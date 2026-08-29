import 'package:flutter_test/flutter_test.dart';

import 'package:shopwise_v1/models/product.dart';
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
