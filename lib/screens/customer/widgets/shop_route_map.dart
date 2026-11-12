import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart' as ml;
import 'package:latlong2/latlong.dart' as route_geo;

import '../../../services/route_service.dart';
import '../../../theme/design_tokens.dart';

class ShopRouteMap extends StatefulWidget {
  final double customerLatitude;
  final double customerLongitude;
  final double shopLatitude;
  final double shopLongitude;
  final String shopName;
  final ShopRouteResult? route;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const ShopRouteMap({
    super.key,
    required this.customerLatitude,
    required this.customerLongitude,
    required this.shopLatitude,
    required this.shopLongitude,
    required this.shopName,
    this.route,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<ShopRouteMap> createState() => _ShopRouteMapState();
}

class _ShopRouteMapState extends State<ShopRouteMap> {
  ml.MapLibreMapController? _mapController;

  ml.LatLng get _customer =>
      ml.LatLng(widget.customerLatitude, widget.customerLongitude);

  ml.LatLng get _shop => ml.LatLng(widget.shopLatitude, widget.shopLongitude);

  List<ml.LatLng> get _routePoints =>
      (widget.route?.points ?? const <route_geo.LatLng>[])
          .map((point) => ml.LatLng(point.latitude, point.longitude))
          .toList(growable: false);

  @override
  void didUpdateWidget(covariant ShopRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.route != widget.route ||
        oldWidget.customerLatitude != widget.customerLatitude ||
        oldWidget.customerLongitude != widget.customerLongitude ||
        oldWidget.shopLatitude != widget.shopLatitude ||
        oldWidget.shopLongitude != widget.shopLongitude) {
      _drawMapAnnotations();
      _fitRouteAfterLayout();
    }
  }

  void _fitRouteAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fitRoute();
    });
  }

  bool _styleLoaded = false;
  bool _annotationsBusy = false;

  Future<void> _fitRoute() async {
    final controller = _mapController;
    if (controller == null) return;

    final points = _routePoints.isEmpty
        ? <ml.LatLng>[_customer, _shop]
        : _routePoints;

    if (points.length == 1) {
      await controller.animateCamera(
        ml.CameraUpdate.newLatLngZoom(points.first, 15),
      );
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points.skip(1)) {
      minLat = math.min(minLat, point.latitude);
      maxLat = math.max(maxLat, point.latitude);
      minLng = math.min(minLng, point.longitude);
      maxLng = math.max(maxLng, point.longitude);
    }

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final latSpan = maxLat - minLat;
    final lngSpan =
        (maxLng - minLng) * math.cos(centerLat * math.pi / 180).abs();
    final span = math.max(latSpan, lngSpan);

    final zoom = span < 0.0001
        ? 15.0
        : (math.log(360 / span) / math.ln2 - 1.3).clamp(3.0, 16.0);

    await controller.animateCamera(
      ml.CameraUpdate.newLatLngZoom(
        ml.LatLng(centerLat, centerLng),
        zoom.toDouble(),
      ),
    );
  }

  Future<void> _drawMapAnnotations() async {
    final controller = _mapController;
    if (controller == null || !_styleLoaded || _annotationsBusy) return;

    _annotationsBusy = true;
    try {
      await controller.clearLines();
      await controller.clearCircles();

      final points = _routePoints;
      if (points.length >= 2) {
        await controller.addLine(
          ml.LineOptions(
            geometry: points,
            lineColor: '#FFFFFF',
            lineWidth: 8,
            lineOpacity: 0.95,
          ),
        );
        await controller.addLine(
          ml.LineOptions(
            geometry: points,
            lineColor: '#2563EB',
            lineWidth: 5,
            lineOpacity: 1,
          ),
        );
      }

      await controller.addCircle(
        ml.CircleOptions(
          geometry: _customer,
          circleRadius: 9,
          circleColor: '#2563EB',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 3,
        ),
      );
      await controller.addCircle(
        ml.CircleOptions(
          geometry: _shop,
          circleRadius: 10,
          circleColor: '#087F5B',
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 3,
        ),
      );
    } catch (error) {
      debugPrint('ShopWise map annotation error: $error');
    } finally {
      _annotationsBusy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = widget.errorMessage;
    final routePoints = _routePoints;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 360,
        color: ShopWiseColors.surfaceSoft,
        child: Stack(
          children: [
            ml.MapLibreMap(
              styleString: 'https://tiles.openfreemap.org/styles/liberty',
              initialCameraPosition: ml.CameraPosition(
                target: _customer,
                zoom: 13,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _fitRouteAfterLayout();
              },
              onStyleLoadedCallback: () {
                _styleLoaded = true;
                _drawMapAnnotations();
                _fitRouteAfterLayout();
              },
              minMaxZoomPreference: const ml.MinMaxZoomPreference(3, 19),
              zoomGesturesEnabled: true,
              scrollGesturesEnabled: true,
              rotateGesturesEnabled: true,
              tiltGesturesEnabled: false,
              compassEnabled: true,
              logoEnabled: false,
            ),

            if (widget.isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.78),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3),
                        SizedBox(height: 12),
                        Text(
                          'Finding best route...',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (errorMessage != null && !widget.isLoading)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withValues(alpha: 0.9),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.route_rounded, size: 42),
                          const SizedBox(height: 12),
                          Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: widget.onRetry,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            if (!widget.isLoading &&
                errorMessage == null &&
                widget.route != null)
              Positioned(
                top: 14,
                left: 14,
                right: 14,
                child: _buildRouteInfo(),
              ),

            if (!widget.isLoading && routePoints.isNotEmpty)
              Positioned(right: 14, bottom: 18, child: _buildMapControls()),
          ],
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _mapControl(icon: Icons.add_rounded, onTap: () => _changeZoom(1)),
        const SizedBox(height: 8),
        _mapControl(icon: Icons.remove_rounded, onTap: () => _changeZoom(-1)),
        const SizedBox(height: 8),
        _mapControl(icon: Icons.fit_screen_rounded, onTap: _fitRoute),
      ],
    );
  }

  Future<void> _changeZoom(double delta) async {
    final controller = _mapController;
    if (controller == null) return;

    final current = controller.cameraPosition;
    final target = current?.target ?? _customer;
    final currentZoom = current?.zoom ?? 13.0;
    final nextZoom = (currentZoom + delta).clamp(3.0, 19.0);

    await controller.animateCamera(
      ml.CameraUpdate.newLatLngZoom(target, nextZoom.toDouble()),
    );
  }

  Widget _mapControl({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(icon, size: 21, color: ShopWiseColors.textPrimary),
        ),
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            offset: Offset(0, 6),
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: ShopWiseColors.oliveSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Color(0xFF2563EB),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Route to shop',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ShopWiseColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.route!.distanceKm.toStringAsFixed(1)} km  •  ${widget.route!.durationMinutes} min',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
