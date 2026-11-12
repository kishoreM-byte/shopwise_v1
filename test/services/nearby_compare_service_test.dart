import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shopwise_v1/models/product.dart';
import 'package:shopwise_v1/models/shop.dart';
import 'package:shopwise_v1/services/customer/compare/nearby_compare_service.dart';
import 'package:shopwise_v1/services/route_service.dart';

Product _product({
  required String id,
  required String shopId,
  required double price,
  String category = 'Furniture',
}) => Product(
  id: id,
  shopId: shopId,
  ownerId: 'owner-$shopId',
  name: id == 'selected' ? 'Oak Dining Table' : 'Modern Dining Table $id',
  category: category,
  description: 'Furniture item',
  price: price,
  stock: 4,
  isAvailable: true,
  imageUrls: const [],
  rating: 4.2,
  reviewCount: 6,
  hasOffer: false,
);

Shop _shop({
  required String id,
  double? latitude,
  double? longitude,
  bool deliveryAvailable = false,
  double deliveryCharge = 0,
  bool deliveryChargeIsKnown = true,
  bool installationAvailable = false,
  double installationCharge = 0,
  bool installationChargeIsKnown = true,
}) => Shop(
  id: id,
  ownerId: 'owner-$id',
  name: 'Shop $id',
  category: 'Furniture',
  description: '',
  address: '',
  phone: '',
  latitude: latitude,
  longitude: longitude,
  rating: 4,
  reviewCount: 1,
  isOpen: true,
  deliveryAvailable: deliveryAvailable,
  deliveryCharge: deliveryCharge,
  deliveryChargeIsKnown: deliveryChargeIsKnown,
  installationAvailable: installationAvailable,
  installationCharge: installationCharge,
  installationChargeIsKnown: installationChargeIsKnown,
);

class _FakeRouteService extends RouteService {
  _FakeRouteService({this.fail = false, this.distanceKm = 10});

  final bool fail;
  final double distanceKm;
  int calls = 0;

  @override
  Future<ShopRouteResult> getDrivingRoute({
    required double customerLatitude,
    required double customerLongitude,
    required double shopLatitude,
    required double shopLongitude,
  }) async {
    calls++;
    if (fail) throw Exception('route unavailable');
    return ShopRouteResult(
      points: const [LatLng(0, 0), LatLng(0.1, 0.1)],
      distanceKm: distanceKm,
      durationMinutes: 20,
    );
  }
}

Future<void> _seedProduct(FakeFirebaseFirestore firestore, Product product) {
  final data = product.toMap()..remove('id');
  return firestore.collection('products').doc(product.id).set(data);
}

Future<void> _seedShop(FakeFirebaseFirestore firestore, Shop shop) {
  final data = shop.toMap()..remove('id');
  return firestore.collection('shops').doc(shop.id).set(data);
}

void main() {
  group('NearbyCompareService', () {
    test(
      'includes selected product and only one lowest-price item per shop',
      () async {
        final firestore = FakeFirebaseFirestore();
        final selected = _product(
          id: 'selected',
          shopId: 'selected-shop',
          price: 15000,
        );
        await _seedProduct(firestore, selected);
        await _seedShop(firestore, _shop(id: 'selected-shop'));
        await _seedShop(
          firestore,
          _shop(id: 'nearby-shop', latitude: 0.1, longitude: 0),
        );
        await _seedProduct(
          firestore,
          _product(id: 'higher-price', shopId: 'nearby-shop', price: 12000),
        );
        await _seedProduct(
          firestore,
          _product(id: 'lower-price', shopId: 'nearby-shop', price: 10000),
        );
        await _seedProduct(
          firestore,
          _product(id: 'same-shop', shopId: 'selected-shop', price: 8000),
        );
        await _seedProduct(
          firestore,
          _product(
            id: 'coffee-table',
            shopId: 'coffee-shop',
            price: 7000,
          ).copyWith(name: 'Modern Coffee Table'),
        );
        await _seedShop(
          firestore,
          _shop(id: 'coffee-shop', latitude: 0.02, longitude: 0),
        );

        final results = await NearbyCompareService(firestore: firestore)
            .findAlternatives(
              selectedProduct: selected,
              customerLatitude: 0,
              customerLongitude: 0,
            );

        expect(results.map((item) => item.product.id), [
          'selected',
          'lower-price',
        ]);
        expect(results.first.isSelected, isTrue);
        expect(results.first.distanceKm, isNull);
        expect(results.last.shop?.id, 'nearby-shop');
        expect(results.last.distanceKm, closeTo(11.1, 0.2));
      },
    );

    test('rejects invalid customer coordinates before querying', () async {
      final firestore = FakeFirebaseFirestore();
      final results = await NearbyCompareService(firestore: firestore)
          .findAlternatives(
            selectedProduct: _product(
              id: 'selected',
              shopId: 'shop',
              price: 10000,
            ),
            customerLatitude: 91,
            customerLongitude: 0,
          );

      expect(results, isEmpty);
    });

    test(
      'skips malformed product documents without failing discovery',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('products').doc('broken').set({
          'category': 'Furniture',
          'name': 42,
          'shopId': 'broken-shop',
        });
        final selected = _product(
          id: 'selected',
          shopId: 'selected-shop',
          price: 15000,
        );
        await _seedShop(
          firestore,
          _shop(id: 'selected-shop', latitude: 0, longitude: 0),
        );

        final results = await NearbyCompareService(firestore: firestore)
            .findAlternatives(
              selectedProduct: selected,
              customerLatitude: 0,
              customerLongitude: 0,
            );
        expect(results.map((item) => item.product.id), ['selected']);
      },
    );

    test(
      'excludes unavailable, out-of-stock and unrelated name matches',
      () async {
        final firestore = FakeFirebaseFirestore();
        final selected = _product(
          id: 'selected',
          shopId: 'shop-1',
          price: 15000,
        );
        await _seedProduct(firestore, selected);
        await _seedProduct(
          firestore,
          _product(
            id: 'sold-out',
            shopId: 'shop-2',
            price: 10000,
          ).copyWith(stock: 0),
        );
        await _seedProduct(
          firestore,
          _product(
            id: 'paused',
            shopId: 'shop-3',
            price: 10000,
          ).copyWith(isAvailable: false),
        );
        await _seedProduct(
          firestore,
          _product(
            id: 'coffee',
            shopId: 'shop-4',
            price: 10000,
          ).copyWith(name: 'Oak Coffee Table'),
        );
        for (final id in ['shop-1', 'shop-2', 'shop-3', 'shop-4']) {
          await _seedShop(
            firestore,
            _shop(id: id, latitude: 0.01, longitude: 0),
          );
        }

        final results = await NearbyCompareService(firestore: firestore)
            .findAlternatives(
              selectedProduct: selected,
              customerLatitude: 0,
              customerLongitude: 0,
            );
        expect(results.map((item) => item.product.id), ['selected']);
      },
    );

    test('calculates round-trip totals without double-counting', () async {
      final route = _FakeRouteService(distanceKm: 10);
      final selected = NearbyCompareItem(
        product: _product(id: 'selected', shopId: 'shop-1', price: 10000),
        shop: _shop(id: 'shop-1', latitude: 0.1, longitude: 0),
        distanceKm: 11,
        isSelected: true,
      );
      final alternative = NearbyCompareItem(
        product: _product(id: 'alternative', shopId: 'shop-2', price: 9000),
        shop: _shop(
          id: 'shop-2',
          latitude: 0.2,
          longitude: 0,
          deliveryAvailable: true,
          deliveryCharge: 1000,
          installationAvailable: true,
          installationCharge: 500,
        ),
        distanceKm: 22,
      );

      final result =
          await NearbyCompareService(
            firestore: FakeFirebaseFirestore(),
            routeService: route,
          ).analyzeCosts(
            items: [selected, alternative],
            customerLatitude: 0,
            customerLongitude: 0,
          );

      expect(route.calls, 2);
      expect(result.hasComparableCosts, isTrue);
      expect(result.items.first.costEstimate!.travelCost, closeTo(140, 0.01));
      expect(
        result.items.first.costEstimate!.estimatedTotalCost,
        closeTo(10140, 0.01),
      );
      expect(
        result.items.last.costEstimate!.estimatedTotalCost,
        closeTo(10640, 0.01),
      );
      expect(result.lowestEstimatedTotal?.product.id, 'selected');
      expect(result.bestValue, isNotNull);
      expect(result.items.last.isLowestListedPrice, isTrue);
    });

    test(
      'keeps failed routes and unknown applicable charges incomplete',
      () async {
        final route = _FakeRouteService(fail: true);
        final selected = NearbyCompareItem(
          product: _product(id: 'selected', shopId: 'shop-1', price: 10000),
          shop: _shop(
            id: 'shop-1',
            latitude: 0.1,
            longitude: 0,
            deliveryAvailable: true,
            deliveryChargeIsKnown: false,
          ),
          distanceKm: 11,
          isSelected: true,
        );
        final alternative = NearbyCompareItem(
          product: _product(id: 'alternative', shopId: 'shop-2', price: 9000),
          shop: _shop(id: 'shop-2', latitude: 0.2, longitude: 0),
          distanceKm: 22,
        );
        final result =
            await NearbyCompareService(
              firestore: FakeFirebaseFirestore(),
              routeService: route,
            ).analyzeCosts(
              items: [selected, alternative],
              customerLatitude: 0,
              customerLongitude: 0,
            );

        expect(result.hasComparableCosts, isFalse);
        expect(result.bestValue, isNull);
        expect(result.lowestEstimatedTotal, isNull);
        expect(result.items.first.costEstimate!.estimatedTotalCost, isNull);
        expect(
          result.items.first.costEstimate!.missingComponents,
          containsAll(['road travel estimate', 'delivery charge']),
        );
        expect(result.items.last.costEstimate!.travelCost, isNull);
      },
    );

    test(
      'does not name a lowest total while any eligible cost is incomplete',
      () async {
        final route = _FakeRouteService(distanceKm: 5);
        final items = [
          NearbyCompareItem(
            product: _product(id: 'selected', shopId: 'shop-1', price: 10000),
            shop: _shop(id: 'shop-1', latitude: 0, longitude: 0),
            distanceKm: 0,
            isSelected: true,
          ),
          NearbyCompareItem(
            product: _product(id: 'unknown-fee', shopId: 'shop-2', price: 9000),
            shop: _shop(
              id: 'shop-2',
              latitude: 0,
              longitude: 0,
              deliveryAvailable: true,
              deliveryChargeIsKnown: false,
            ),
            distanceKm: 0,
          ),
          NearbyCompareItem(
            product: _product(id: 'other', shopId: 'shop-3', price: 12000),
            shop: _shop(id: 'shop-3', latitude: 0, longitude: 0),
            distanceKm: 0,
          ),
        ];

        final result = await NearbyCompareService(
          firestore: FakeFirebaseFirestore(),
          routeService: route,
        ).analyzeCosts(items: items, customerLatitude: 0, customerLongitude: 0);

        expect(result.hasComparableCosts, isFalse);
        expect(result.lowestEstimatedTotal, isNull);
        expect(
          result.items.every((item) => !item.isLowestEstimatedTotal),
          isTrue,
        );
        expect(result.bestValue, isNull);
      },
    );

    test('missing shop coordinates leave route cost unknown', () async {
      final route = _FakeRouteService();
      final items = [
        NearbyCompareItem(
          product: _product(id: 'selected', shopId: 'shop-1', price: 10000),
          shop: _shop(id: 'shop-1'),
          distanceKm: null,
          isSelected: true,
        ),
        NearbyCompareItem(
          product: _product(id: 'alternative', shopId: 'shop-2', price: 9000),
          shop: _shop(id: 'shop-2'),
          distanceKm: null,
        ),
      ];
      final result = await NearbyCompareService(
        firestore: FakeFirebaseFirestore(),
        routeService: route,
      ).analyzeCosts(items: items, customerLatitude: 0, customerLongitude: 0);
      expect(route.calls, 0);
      expect(result.hasComparableCosts, isFalse);
      expect(
        result.items.every(
          (item) => item.costEstimate!.estimatedTotalCost == null,
        ),
        isTrue,
      );
    });

    test(
      'reports tied Smart Scores without selecting an overall winner',
      () async {
        final route = _FakeRouteService(distanceKm: 0);
        final products = [
          for (final id in ['a', 'b'])
            NearbyCompareItem(
              product: _product(id: id, shopId: 'shop-$id', price: 10000),
              shop: _shop(id: 'shop-$id', latitude: 0, longitude: 0),
              distanceKm: 0,
              isSelected: id == 'a',
            ),
        ];
        final result =
            await NearbyCompareService(
              firestore: FakeFirebaseFirestore(),
              routeService: route,
            ).analyzeCosts(
              items: products,
              customerLatitude: 0,
              customerLongitude: 0,
            );
        expect(result.hasComparableCosts, isTrue);
        expect(result.hasBestValueTie, isTrue);
        expect(result.bestValue, isNull);
        expect(result.lowestEstimatedTotal, isNull);
      },
    );

    test(
      'does not rank an unavailable selected baseline as Smart Pick',
      () async {
        final route = _FakeRouteService(distanceKm: 5);
        final items = [
          NearbyCompareItem(
            product: _product(
              id: 'selected',
              shopId: 'shop-1',
              price: 8000,
            ).copyWith(isAvailable: false),
            shop: _shop(id: 'shop-1', latitude: 0, longitude: 0),
            distanceKm: 0,
            isSelected: true,
          ),
          for (final id in ['candidate-a', 'candidate-b'])
            NearbyCompareItem(
              product: _product(
                id: id,
                shopId: id,
                price: 10000,
              ).copyWith(rating: id == 'candidate-b' ? 3 : 4.2),
              shop: _shop(id: id, latitude: 0.1, longitude: 0),
              distanceKm: 11,
            ),
        ];
        final result = await NearbyCompareService(
          firestore: FakeFirebaseFirestore(),
          routeService: route,
        ).analyzeCosts(items: items, customerLatitude: 0, customerLongitude: 0);
        expect(result.hasComparableCosts, isTrue);
        expect(result.items.first.smartScore, isNull);
        expect(
          result.bestValue?.product.id,
          isIn(['candidate-a', 'candidate-b']),
        );
      },
    );
  });
}
