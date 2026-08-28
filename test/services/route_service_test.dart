import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:shopwise_v1/services/route_service.dart';

void main() {
  setUp(() {
    RouteService.clearCache();
  });

  group('RouteService', () {
    test('parses OSRM driving route correctly', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.host, 'router.project-osrm.org');
        expect(request.url.path, contains('/route/v1/driving/'));
        expect(request.url.queryParameters['overview'], 'full');
        expect(request.url.queryParameters['geometries'], 'geojson');

        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'distance': 12345.6,
                'duration': 754.2,
                'geometry': {
                  'coordinates': [
                    [80.2700, 13.0800],
                    [80.2750, 13.0850],
                    [80.2800, 13.0900],
                  ],
                  'type': 'LineString',
                },
              },
            ],
          }),
          200,
        );
      });

      final service = RouteService(client: client);

      final result = await service.getDrivingRoute(
        customerLatitude: 13.0800,
        customerLongitude: 80.2700,
        shopLatitude: 13.0900,
        shopLongitude: 80.2800,
      );

      expect(result.distanceKm, closeTo(12.3456, 0.0001));
      expect(result.durationMinutes, 13);
      expect(result.points.length, 3);

      expect(result.points.first, const LatLng(13.0800, 80.2700));
      expect(result.points.last, const LatLng(13.0900, 80.2800));
    });

    test('throws when OSRM returns a non-200 response', () async {
      final client = MockClient((request) async {
        return http.Response('Server error', 500);
      });

      final service = RouteService(client: client);

      expect(
        () => service.getDrivingRoute(
          customerLatitude: 13.0800,
          customerLongitude: 80.2700,
          shopLatitude: 13.0900,
          shopLongitude: 80.2800,
        ),
        throwsException,
      );
    });

    test('throws when OSRM returns a failed route status', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': 'NoRoute',
            'routes': [],
          }),
          200,
        );
      });

      final service = RouteService(client: client);

      expect(
        () => service.getDrivingRoute(
          customerLatitude: 13.0800,
          customerLongitude: 80.2700,
          shopLatitude: 13.0900,
          shopLongitude: 80.2800,
        ),
        throwsException,
      );
    });

    test('throws when OSRM returns Ok with no routes', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [],
          }),
          200,
        );
      });

      final service = RouteService(client: client);

      expect(
        () => service.getDrivingRoute(
          customerLatitude: 13.0800,
          customerLongitude: 80.2700,
          shopLatitude: 13.0900,
          shopLongitude: 80.2800,
        ),
        throwsException,
      );
    });

    test('caches identical route requests', () async {
      int requestCount = 0;

      final client = MockClient((request) async {
        requestCount++;

        return http.Response(
          jsonEncode({
            'code': 'Ok',
            'routes': [
              {
                'distance': 5000,
                'duration': 600,
                'geometry': {
                  'coordinates': [
                    [80.2700, 13.0800],
                    [80.2800, 13.0900],
                  ],
                  'type': 'LineString',
                },
              },
            ],
          }),
          200,
        );
      });

      final service = RouteService(client: client);

      final first = await service.getDrivingRoute(
        customerLatitude: 13.0800,
        customerLongitude: 80.2700,
        shopLatitude: 13.0900,
        shopLongitude: 80.2800,
      );

      final second = await service.getDrivingRoute(
        customerLatitude: 13.0800,
        customerLongitude: 80.2700,
        shopLatitude: 13.0900,
        shopLongitude: 80.2800,
      );

      expect(first.distanceKm, 5);
      expect(second.distanceKm, 5);
      expect(requestCount, 1);
    });
  });
}
