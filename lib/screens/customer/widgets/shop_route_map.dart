import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/route_service.dart';

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
  final MapController _mapController = MapController();

  LatLng get _customer =>
      LatLng(widget.customerLatitude, widget.customerLongitude);

  LatLng get _shop => LatLng(widget.shopLatitude, widget.shopLongitude);

  @override
  void initState() {
    super.initState();
    _fitRouteAfterLayout();
  }

  @override
  void didUpdateWidget(covariant ShopRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.route != widget.route) {
      _fitRouteAfterLayout();
    }
  }

  void _fitRouteAfterLayout() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.route?.points.isNotEmpty == true) {
        _fitRoute();
      }
    });
  }

  void _fitRoute() {
    final List<LatLng> routePoints = widget.route?.points ?? const [];

    if (routePoints.isEmpty) return;

    final bounds = LatLngBounds.fromPoints(routePoints);

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.fromLTRB(50, 70, 50, 70),
        maxZoom: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<LatLng> routePoints = widget.route?.points ?? const [];
    final String? errorMessage = widget.errorMessage;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 360,
        color: const Color(0xFFF1F5F9),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _customer,
                initialZoom: 13,
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.drag |
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.doubleTapZoom |
                      InteractiveFlag.scrollWheelZoom,
                  enableMultiFingerGestureRace: true,
                ),
                minZoom: 3,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.shopwise.shopwise_v1',
                  maxZoom: 19,
                  keepBuffer: 2,
                  tileBuilder: (context, tileWidget, tile) {
                    return ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        0.97,
                        0.02,
                        0.01,
                        0,
                        0,
                        0.01,
                        0.98,
                        0.01,
                        0,
                        1,
                        0.01,
                        0.02,
                        0.97,
                        0,
                        2,
                        0,
                        0,
                        0,
                        1,
                        0,
                      ]),
                      child: tileWidget,
                    );
                  },
                ),

                RichAttributionWidget(
                  alignment: AttributionAlignment.bottomRight,
                  showFlutterMapAttribution: true,
                  popupBackgroundColor: Colors.white,
                  attributions: [
                    TextSourceAttribution('OpenStreetMap contributors'),
                  ],
                ),

                if (routePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: routePoints,
                        strokeWidth: 10,
                        color: Colors.white,
                      ),
                      Polyline(
                        points: routePoints,
                        strokeWidth: 6,
                        color: const Color(0xFF2563EB),
                      ),
                    ],
                  ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: _customer,
                      width: 58,
                      height: 58,
                      child: _buildCustomerMarker(),
                    ),
                    Marker(
                      point: _shop,
                      width: 180,
                      height: 100,
                      child: _buildShopMarker(),
                    ),
                  ],
                ),
              ],
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

  Widget _buildCustomerMarker() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(blurRadius: 14, spreadRadius: 1, color: Colors.black26),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF2563EB),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.navigation_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildShopMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 170),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(
                blurRadius: 14,
                offset: Offset(0, 4),
                color: Colors.black26,
              ),
            ],
          ),
          child: Text(
            widget.shopName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(blurRadius: 14, spreadRadius: 1, color: Colors.black26),
            ],
          ),
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.store_rounded,
              color: Colors.white,
              size: 23,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMapControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _mapControl(
          icon: Icons.add_rounded,
          onTap: () {
            final zoom = _mapController.camera.zoom + 1;
            _mapController.move(_mapController.camera.center, zoom);
          },
        ),
        const SizedBox(height: 8),
        _mapControl(
          icon: Icons.remove_rounded,
          onTap: () {
            final zoom = _mapController.camera.zoom - 1;
            _mapController.move(_mapController.camera.center, zoom);
          },
        ),
        const SizedBox(height: 8),
        _mapControl(icon: Icons.fit_screen_rounded, onTap: _fitRoute),
      ],
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
          child: Icon(icon, size: 21, color: const Color(0xFF0F172A)),
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
              color: const Color(0xFFEFF6FF),
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
                    color: Colors.black54,
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
