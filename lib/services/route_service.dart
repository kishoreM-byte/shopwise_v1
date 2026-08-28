import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class ShopRouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final int durationMinutes;

  const ShopRouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
  });
}

class RouteService {
  RouteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final Map<String, ShopRouteResult> _routeCache = {};

  Future<ShopRouteResult> getDrivingRoute({
    required double customerLatitude,
    required double customerLongitude,
    required double shopLatitude,
    required double shopLongitude,
  }) async {
    final String cacheKey = _cacheKey(
      customerLatitude: customerLatitude,
      customerLongitude: customerLongitude,
      shopLatitude: shopLatitude,
      shopLongitude: shopLongitude,
    );

    final ShopRouteResult? cachedRoute = _routeCache[cacheKey];
    if (cachedRoute != null) {
      return cachedRoute;
    }

    final Uri url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '$customerLongitude,$customerLatitude;'
      '$shopLongitude,$shopLatitude'
      '?overview=full&geometries=geojson',
    );

    final http.Response response = await _client.get(
      url,
      headers: const {'User-Agent': 'ShopWise/1.0'},
    );

    if (response.statusCode != 200) {
      throw Exception('OSRM request failed');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (data['code'] != 'Ok') {
      throw Exception('No drivable route found');
    }

    final List<dynamic> routes = data['routes'] as List<dynamic>;

    if (routes.isEmpty) {
      throw Exception('No route found');
    }

    final Map<String, dynamic> route = routes.first as Map<String, dynamic>;
    final Map<String, dynamic> geometry =
        route['geometry'] as Map<String, dynamic>;
    final List<dynamic> coordinates = geometry['coordinates'] as List<dynamic>;

    final List<LatLng> points = coordinates.map<LatLng>((coordinate) {
      final List<dynamic> pair = coordinate as List<dynamic>;

      return LatLng((pair[1] as num).toDouble(), (pair[0] as num).toDouble());
    }).toList();

    final ShopRouteResult result = ShopRouteResult(
      points: points,
      distanceKm: (route['distance'] as num).toDouble() / 1000,
      durationMinutes: ((route['duration'] as num).toDouble() / 60).ceil(),
    );

    _routeCache[cacheKey] = result;

    return result;
  }

  String _cacheKey({
    required double customerLatitude,
    required double customerLongitude,
    required double shopLatitude,
    required double shopLongitude,
  }) {
    return [
      customerLatitude.toStringAsFixed(5),
      customerLongitude.toStringAsFixed(5),
      shopLatitude.toStringAsFixed(5),
      shopLongitude.toStringAsFixed(5),
    ].join(':');
  }
}
