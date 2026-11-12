import 'package:latlong2/latlong.dart';

enum RoutePoiType { petrolStation, mechanicShop }

class RoutePoi {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final RoutePoiType type;
  final double distanceFromRouteKm;
  final double distanceFromCustomerKm;

  const RoutePoi({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.distanceFromRouteKm,
    required this.distanceFromCustomerKm,
  });

  LatLng get position => LatLng(latitude, longitude);
}
