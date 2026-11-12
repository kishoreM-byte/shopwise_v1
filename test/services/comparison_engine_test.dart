import 'package:flutter_test/flutter_test.dart';

import 'package:shopwise_v1/models/product.dart';
import 'package:shopwise_v1/models/shop.dart';
import 'package:shopwise_v1/services/customer/comparison_engine.dart';

Product _product({
  required String id,
  required String name,
  required double price,
  double rating = 4,
  int reviewCount = 20,
  int stock = 10,
  bool isAvailable = true,
  bool hasOffer = false,
  double? originalPrice,
}) {
  return Product(
    id: id,
    shopId: 'shop-$id',
    ownerId: 'owner-$id',
    name: name,
    category: 'General',
    description: 'Test product',
    price: price,
    originalPrice: originalPrice,
    stock: stock,
    isAvailable: isAvailable,
    imageUrls: const [],
    rating: rating,
    reviewCount: reviewCount,
    hasOffer: hasOffer,
    offerText: hasOffer ? 'Special offer' : null,
  );
}

void main() {
  const engine = ComparisonEngine();

  group('ComparisonEngine', () {
    test('an offered but unknown shop charge stays incomplete', () {
      const shop = Shop(
        id: 'shop-one',
        ownerId: 'owner-one',
        name: 'Shop One',
        category: 'Furniture',
        description: '',
        address: '',
        phone: '',
        rating: 0,
        reviewCount: 0,
        isOpen: true,
        deliveryAvailable: true,
        deliveryCharge: 0,
        deliveryChargeIsKnown: false,
      );

      final costs = ComparisonShopCosts.fromShop(shop);
      final knownCosts = ComparisonShopCosts.fromShop(
        shop.copyWith(
          id: 'shop-two',
          deliveryCharge: 300,
          deliveryChargeIsKnown: true,
        ),
      );
      final result = engine.compare(
        [
          _product(id: 'one', name: 'One', price: 10000),
          _product(id: 'two', name: 'Two', price: 11000),
        ],
        travelCosts: const {'one': 100, 'two': 100},
        deliveryCosts: {
          if (costs.deliveryCost != null) 'one': costs.deliveryCost!,
          if (knownCosts.deliveryCost != null) 'two': knownCosts.deliveryCost!,
        },
        installationCosts: {
          if (costs.installationCost != null) 'one': costs.installationCost!,
          if (knownCosts.installationCost != null)
            'two': knownCosts.installationCost!,
        },
        reliableTravelCostProductIds: const {'one', 'two'},
        reliableShopCostDataProductIds: {
          if (costs.isComplete) 'one',
          if (knownCosts.isComplete) 'two',
        },
      );

      expect(costs.deliveryCost, isNull);
      expect(costs.installationCost, 0);
      expect(costs.isComplete, isFalse);
      expect(knownCosts.isComplete, isTrue);
      expect(result.lowestTrueCostProductId, isNull);
    });

    test('compares between 2 and 4 products', () {
      final products = [
        _product(id: 'one', name: 'Product One', price: 10000),
        _product(id: 'two', name: 'Product Two', price: 9000),
      ];

      final result = engine.compare(products);

      expect(result.products.length, 2);
    });

    test('rejects fewer than 2 products', () {
      final products = [_product(id: 'one', name: 'Product One', price: 10000)];

      expect(() => engine.compare(products), throwsArgumentError);
    });

    test('rejects more than 4 products', () {
      final products = List.generate(
        5,
        (index) => _product(
          id: '$index',
          name: 'Product $index',
          price: 10000 + index.toDouble(),
        ),
      );

      expect(() => engine.compare(products), throwsArgumentError);
    });

    test('identifies lowest price product', () {
      final result = engine.compare([
        _product(id: 'expensive', name: 'Expensive', price: 15000),
        _product(id: 'cheap', name: 'Cheap', price: 9000),
        _product(id: 'middle', name: 'Middle', price: 12000),
      ]);

      expect(result.lowestPriceProductId, 'cheap');
    });

    test('identifies highest rated product', () {
      final result = engine.compare([
        _product(id: 'one', name: 'One', price: 10000, rating: 4.1),
        _product(id: 'two', name: 'Two', price: 11000, rating: 4.8),
        _product(id: 'three', name: 'Three', price: 9000, rating: 4.3),
      ]);

      expect(result.highestRatedProductId, 'two');
    });

    test('does not highlight a rating when there are no review records', () {
      final result = engine.compare([
        _product(
          id: 'unreviewed',
          name: 'Unreviewed',
          price: 10000,
          rating: 0,
          reviewCount: 0,
        ),
        _product(
          id: 'reviewed',
          name: 'Reviewed',
          price: 11000,
          rating: 4.5,
          reviewCount: 2,
        ),
      ]);

      expect(result.highestRatedProductId, 'reviewed');
    });

    test('does not call an option the best offer if none have an offer', () {
      final result = engine.compare([
        _product(id: 'one', name: 'One', price: 10000),
        _product(id: 'two', name: 'Two', price: 11000),
      ]);

      expect(result.bestOfferProductId, isNull);
    });

    test('identifies unavailable product as weaker availability', () {
      final result = engine.compare([
        _product(
          id: 'available',
          name: 'Available',
          price: 10000,
          stock: 10,
          isAvailable: true,
        ),
        _product(
          id: 'unavailable',
          name: 'Unavailable',
          price: 9000,
          stock: 0,
          isAvailable: false,
        ),
      ]);

      expect(result.bestAvailabilityProductId, 'available');
    });

    test('identifies strongest offer using Smart Score logic', () {
      final result = engine.compare([
        _product(
          id: 'normal',
          name: 'Normal',
          price: 10000,
          originalPrice: null,
          hasOffer: false,
        ),
        _product(
          id: 'offer',
          name: 'Offer',
          price: 8000,
          originalPrice: 10000,
          hasOffer: true,
        ),
      ]);

      expect(result.bestOfferProductId, 'offer');
    });

    test('identifies best Smart Score product', () {
      final result = engine.compare([
        _product(
          id: 'weak',
          name: 'Weak',
          price: 15000,
          rating: 3,
          reviewCount: 5,
          stock: 1,
          isAvailable: true,
          hasOffer: false,
        ),
        _product(
          id: 'strong',
          name: 'Strong',
          price: 9000,
          rating: 5,
          reviewCount: 500,
          stock: 20,
          isAvailable: true,
          hasOffer: true,
          originalPrice: 12000,
        ),
      ]);

      expect(result.bestSmartScoreProductId, 'strong');
    });

    test('reuses TrueCostService for total purchase cost', () {
      final result = engine.compare(
        [
          _product(id: 'one', name: 'One', price: 10000),
          _product(id: 'two', name: 'Two', price: 11000),
        ],
        travelCosts: const {'one': 200, 'two': 100},
        deliveryCosts: const {'one': 300, 'two': 0},
        installationCosts: const {'one': 500, 'two': 0},
      );

      final first = result.products.firstWhere(
        (item) => item.product.id == 'one',
      );

      final second = result.products.firstWhere(
        (item) => item.product.id == 'two',
      );

      expect(first.trueCost, 11000);
      expect(second.trueCost, 11100);
      expect(result.lowestTrueCostProductId, 'one');
    });

    test('does not recommend a true cost when travel inputs are missing', () {
      final result = engine.compare([
        _product(id: 'one', name: 'One', price: 10000),
        _product(id: 'two', name: 'Two', price: 11000),
      ], reliableTravelCostProductIds: const <String>{});

      expect(result.lowestPriceProductId, 'one');
      expect(result.lowestTrueCostProductId, isNull);
      expect(
        result.products.every((item) => !item.hasReliableTravelCost),
        isTrue,
      );
    });

    test('unknown shop charges do not reduce Smart Score as free services', () {
      final products = [
        _product(id: 'unknown', name: 'Unknown charges', price: 10000),
        _product(id: 'free', name: 'Confirmed zero charges', price: 10000),
      ];

      final unknownResult = engine.compare(
        products,
        travelCosts: const {'unknown': 0, 'free': 0},
        deliveryCosts: const {'free': 0},
        installationCosts: const {'free': 0},
        reliableTravelCostProductIds: const {'unknown', 'free'},
      );

      final unknown = unknownResult.products.firstWhere(
        (item) => item.product.id == 'unknown',
      );
      final free = unknownResult.products.firstWhere(
        (item) => item.product.id == 'free',
      );

      expect(unknown.hasReliableDeliveryCost, isFalse);
      expect(unknown.hasReliableInstallationCost, isFalse);
      expect(free.hasReliableDeliveryCost, isTrue);
      expect(free.hasReliableInstallationCost, isTrue);
      expect(unknown.smartScore.score, free.smartScore.score);
    });

    test('known delivery remains reliable when installation is unknown', () {
      final result = engine.compare(
        [
          _product(id: 'partial', name: 'Partial costs', price: 10000),
          _product(id: 'complete', name: 'Complete costs', price: 11000),
        ],
        travelCosts: const {'partial': 100, 'complete': 100},
        deliveryCosts: const {'partial': 250, 'complete': 0},
        installationCosts: const {'complete': 0},
        reliableTravelCostProductIds: const {'partial', 'complete'},
      );

      final partial = result.products.firstWhere(
        (item) => item.product.id == 'partial',
      );

      expect(partial.hasReliableDeliveryCost, isTrue);
      expect(partial.hasReliableInstallationCost, isFalse);
      expect(partial.hasReliableShopCostData, isFalse);
      expect(partial.smartScore.deliveryCost, 250);
      expect(result.lowestTrueCostProductId, isNull);
    });

    test(
      'excludes installation cost from every score when any installation cost is unknown',
      () {
        final result = engine.compare(
          [
            _product(id: 'partial', name: 'Partial costs', price: 10000),
            _product(id: 'complete', name: 'Complete costs', price: 11000),
          ],
          travelCosts: const {'partial': 100, 'complete': 100},
          deliveryCosts: const {'partial': 250, 'complete': 0},
          installationCosts: const {'complete': 500},
          reliableTravelCostProductIds: const {'partial', 'complete'},
        );

        final partial = result.products.firstWhere(
          (item) => item.product.id == 'partial',
        );
        final complete = result.products.firstWhere(
          (item) => item.product.id == 'complete',
        );

        expect(partial.hasReliableDeliveryCost, isTrue);
        expect(partial.hasReliableInstallationCost, isFalse);
        expect(complete.hasReliableInstallationCost, isTrue);

        // Delivery is known for both products, so its impact remains.
        expect(partial.smartScore.deliveryCost, 250);
        expect(complete.smartScore.deliveryCost, 0);

        // Installation is unknown for one product, so exclude it for both.
        expect(partial.smartScore.installationCost, 0);
        expect(complete.smartScore.installationCost, 0);

        // True cost must remain unavailable when shop charges are incomplete.
        expect(result.lowestTrueCostProductId, isNull);
      },
    );

    test(
      'Smart Score explanation identifies comparable and excluded costs',
      () {
        final result = engine.compare(
          [
            _product(id: 'partial', name: 'Partial costs', price: 10000),
            _product(id: 'complete', name: 'Complete costs', price: 11000),
          ],
          travelCosts: const {'partial': 100, 'complete': 100},
          deliveryCosts: const {'partial': 250, 'complete': 0},
          installationCosts: const {'complete': 500},
          reliableTravelCostProductIds: const {'partial', 'complete'},
        );

        expect(
          result.smartScoreCostSummary,
          contains('travel, delivery costs included'),
        );
        expect(result.smartScoreCostSummary, contains('installation excluded'));
        expect(result.hasComparableDeliveryCosts, isTrue);
        expect(result.hasComparableInstallationCosts, isFalse);
      },
    );

    test('True Cost explanation names each missing cost category', () {
      final result = engine.compare(
        [
          _product(id: 'partial', name: 'Partial costs', price: 10000),
          _product(id: 'complete', name: 'Complete costs', price: 11000),
        ],
        travelCosts: const {'partial': 100, 'complete': 100},
        deliveryCosts: const {'partial': 250, 'complete': 0},
        installationCosts: const {'complete': 500},
        reliableTravelCostProductIds: const {'partial', 'complete'},
      );

      expect(result.trueCostUnavailableReason, contains('installation charge'));
      expect(result.trueCostUnavailableReason, isNot(contains('travel route')));
      expect(
        result.trueCostUnavailableReason,
        isNot(contains('delivery charge')),
      );
    });

    test('omitted cost inputs are unknown rather than reliable zero costs', () {
      final result = engine.compare([
        _product(id: 'one', name: 'One', price: 10000),
        _product(id: 'two', name: 'Two', price: 11000),
      ]);

      expect(result.lowestPriceProductId, 'one');
      expect(result.lowestTrueCostProductId, isNull);
      expect(result.hasReliableTravelCosts, isFalse);
      expect(result.hasReliableShopCostData, isFalse);
    });

    test('does not select a product with missing listed price', () {
      final result = engine.compare([
        _product(id: 'missing', name: 'Missing price', price: 0),
        _product(id: 'priced', name: 'Priced', price: 11000),
      ]);

      expect(result.lowestPriceProductId, 'priced');
      expect(result.bestSmartScoreProductId, 'priced');
      expect(result.lowestTrueCostProductId, isNull);
    });

    test('keeps known shop distances aligned with their products', () {
      final result = engine.compare(
        [
          _product(id: 'one', name: 'One', price: 10000),
          _product(id: 'two', name: 'Two', price: 11000),
        ],
        distancesKm: const {'one': 1.4, 'two': 3.2},
      );

      expect(result.products.map((item) => item.distanceKm), <double?>[
        1.4,
        3.2,
      ]);
    });

    test('calculates price difference correctly', () {
      final first = _product(id: 'one', name: 'One', price: 12000);

      final second = _product(id: 'two', name: 'Two', price: 10000);

      expect(engine.priceDifference(first, second), 2000);
      expect(engine.priceDifference(second, first), -2000);
    });

    test('calculates rating and stock differences correctly', () {
      final first = _product(
        id: 'one',
        name: 'One',
        price: 10000,
        rating: 4.8,
        stock: 15,
      );

      final second = _product(
        id: 'two',
        name: 'Two',
        price: 10000,
        rating: 4.2,
        stock: 10,
      );

      expect(engine.ratingDifference(first, second), closeTo(0.6, 0.0001));

      expect(engine.stockDifference(first, second), 5);
    });
  });
}
