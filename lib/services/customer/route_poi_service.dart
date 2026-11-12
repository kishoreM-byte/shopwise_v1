import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../models/route_poi.dart';

class RoutePoiResult {
  final List<RoutePoi> petrolStations;
  final List<RoutePoi> mechanicShops;

  const RoutePoiResult({
    required this.petrolStations,
    this.mechanicShops = const [],
  });

  int get petrolStationCount => petrolStations.length;
  int get mechanicShopCount => mechanicShops.length;
}

class RoutePoiService {
  RoutePoiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _overpassEndpoint =
      'https://overpass-api.de/api/interpreter';

  static const double _corridorRadiusKm = 0.75;
  static const double _maxSampleSpacingKm = 3.0;

  Future<RoutePoiResult> getPetrolStationsAlongRoute({
    required List<LatLng> routePoints,
  }) async {
    if (routePoints.length < 2) {
      return const RoutePoiResult(petrolStations: [], mechanicShops: []);
    }

    final List<LatLng> samples = _sampleRoute(routePoints);

    final Map<String, RoutePoi> uniqueStations = {};
    final Map<String, RoutePoi> uniqueMechanics = {};

    final String query = _buildOverpassQuery(samples);

    final Uri url = Uri.parse(
      _overpassEndpoint,
    ).replace(queryParameters: {'data': query});

    final http.Response response = await _client.get(
      url,
      headers: const {
        'User-Agent': 'ShopWise/1.0',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Petrol station lookup failed (${response.statusCode})');
    }

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    final List<dynamic> elements =
        (data['elements'] as List<dynamic>?) ?? const [];

    final LatLng customerPoint = routePoints.first;

    for (final dynamic rawElement in elements) {
      final Map<String, dynamic> element = rawElement as Map<String, dynamic>;

      final double? latitude = _elementLatitude(element);
      final double? longitude = _elementLongitude(element);

      if (latitude == null || longitude == null) {
        continue;
      }

      final LatLng stationPoint = LatLng(latitude, longitude);

      final double routeDistanceKm = _distanceToRouteKm(
        stationPoint,
        routePoints,
      );

      if (routeDistanceKm > _corridorRadiusKm) {
        continue;
      }

      final String osmType = element['type']?.toString() ?? 'unknown';

      final String osmId = element['id']?.toString() ?? '$latitude:$longitude';

      final Map<String, dynamic> tags =
          (element['tags'] as Map<String, dynamic>?) ?? const {};

      final bool isFuel = tags['amenity'] == 'fuel';
      final bool isMechanic = _isMechanic(tags);
      if (!isFuel && !isMechanic) continue;

      final String name = _poiName(tags, isMechanic: isMechanic);

      final double customerDistanceKm = _distanceKm(
        customerPoint,
        stationPoint,
      );

      final RoutePoi poi = RoutePoi(
        id: '$osmType:$osmId',
        name: name,
        latitude: latitude,
        longitude: longitude,
        type: isMechanic
            ? RoutePoiType.mechanicShop
            : RoutePoiType.petrolStation,
        distanceFromRouteKm: routeDistanceKm,
        distanceFromCustomerKm: customerDistanceKm,
      );

      if (isMechanic) {
        uniqueMechanics[poi.id] = poi;
      } else {
        uniqueStations[poi.id] = poi;
      }
    }

    final List<RoutePoi> stations = uniqueStations.values.toList()
      ..sort(
        (a, b) => a.distanceFromCustomerKm.compareTo(b.distanceFromCustomerKm),
      );

    final List<RoutePoi> mechanics = uniqueMechanics.values.toList()
      ..sort(
        (a, b) => a.distanceFromCustomerKm.compareTo(b.distanceFromCustomerKm),
      );

    return RoutePoiResult(petrolStations: stations, mechanicShops: mechanics);
  }

  List<LatLng> _sampleRoute(List<LatLng> points) {
    final List<LatLng> samples = [points.first];

    double accumulatedKm = 0;

    for (int i = 1; i < points.length; i++) {
      final double segmentKm = _distanceKm(points[i - 1], points[i]);

      accumulatedKm += segmentKm;

      if (accumulatedKm >= _maxSampleSpacingKm) {
        samples.add(points[i]);
        accumulatedKm = 0;
      }
    }

    if (samples.last != points.last) {
      samples.add(points.last);
    }

    return samples;
  }

  String _buildOverpassQuery(List<LatLng> samples) {
    final StringBuffer query = StringBuffer()
      ..writeln('[out:json][timeout:30];')
      ..writeln('(');

    for (final LatLng point in samples) {
      query.writeln(
        'nwr["amenity"="fuel"]'
        '(around:750,${point.latitude},${point.longitude});'
        'nwr["shop"="car_repair"]'
        '(around:750,${point.latitude},${point.longitude});'
        'nwr["craft"="car_repair"]'
        '(around:750,${point.latitude},${point.longitude});'
        'nwr["amenity"="car_repair"]'
        '(around:750,${point.latitude},${point.longitude});',
      );
    }

    query
      ..writeln(');')
      ..writeln('out center tags;');

    return query.toString();
  }

  double? _elementLatitude(Map<String, dynamic> element) {
    final dynamic lat = element['lat'];

    if (lat is num) {
      return lat.toDouble();
    }

    final Map<String, dynamic>? center =
        element['center'] as Map<String, dynamic>?;

    final dynamic centerLat = center?['lat'];

    if (centerLat is num) {
      return centerLat.toDouble();
    }

    return null;
  }

  double? _elementLongitude(Map<String, dynamic> element) {
    final dynamic lon = element['lon'];

    if (lon is num) {
      return lon.toDouble();
    }

    final Map<String, dynamic>? center =
        element['center'] as Map<String, dynamic>?;

    final dynamic centerLon = center?['lon'];

    if (centerLon is num) {
      return centerLon.toDouble();
    }

    return null;
  }

  bool _isMechanic(Map<String, dynamic> tags) {
    return tags['shop'] == 'car_repair' ||
        tags['craft'] == 'car_repair' ||
        tags['amenity'] == 'car_repair';
  }

  String _poiName(Map<String, dynamic> tags, {required bool isMechanic}) {
    final String? name = tags['name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    final String? brand = tags['brand']?.toString().trim();

    if (brand != null && brand.isNotEmpty) {
      return brand;
    }

    return isMechanic ? 'Mechanic shop' : 'Petrol station';
  }

  double _distanceKm(LatLng a, LatLng b) {
    const double earthRadiusKm = 6371.0088;

    final double lat1 = _toRadians(a.latitude);
    final double lat2 = _toRadians(b.latitude);
    final double deltaLat = _toRadians(b.latitude - a.latitude);
    final double deltaLon = _toRadians(b.longitude - a.longitude);

    final double haversine =
        math.pow(math.sin(deltaLat / 2), 2).toDouble() +
        math.cos(lat1) *
            math.cos(lat2) *
            math.pow(math.sin(deltaLon / 2), 2).toDouble();

    final double arc =
        2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));

    return earthRadiusKm * arc;
  }

  double _distanceToRouteKm(LatLng point, List<LatLng> route) {
    double minimum = double.infinity;

    for (int i = 1; i < route.length; i++) {
      final double distance = _distanceToSegmentKm(
        point,
        route[i - 1],
        route[i],
      );

      if (distance < minimum) {
        minimum = distance;
      }
    }

    return minimum;
  }

  double _distanceToSegmentKm(LatLng point, LatLng start, LatLng end) {
    final double latitudeScale = 111.32;
    final double longitudeScale = 111.32 * math.cos(_toRadians(point.latitude));

    final double px = point.longitude * longitudeScale;
    final double py = point.latitude * latitudeScale;

    final double ax = start.longitude * longitudeScale;
    final double ay = start.latitude * latitudeScale;

    final double bx = end.longitude * longitudeScale;
    final double by = end.latitude * latitudeScale;

    final double dx = bx - ax;
    final double dy = by - ay;

    if (dx == 0 && dy == 0) {
      return math.sqrt(math.pow(px - ax, 2) + math.pow(py - ay, 2));
    }

    final double t =
        (((px - ax) * dx) + ((py - ay) * dy)) / ((dx * dx) + (dy * dy));

    final double clamped = t.clamp(0.0, 1.0);

    final double closestX = ax + clamped * dx;
    final double closestY = ay + clamped * dy;

    return math.sqrt(math.pow(px - closestX, 2) + math.pow(py - closestY, 2));
  }

  double _toRadians(double degrees) {
    return degrees * math.pi / 180;
  }

  void dispose() {
    _client.close();
  }
}
