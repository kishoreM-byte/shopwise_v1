import 'package:flutter_test/flutter_test.dart';

import 'package:shopwise_v1/models/product.dart';
import 'package:shopwise_v1/services/smart_score_service.dart';

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
  String? offerText,
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
    offerText: offerText ?? (hasOffer ? 'Special offer' : null),
  );
}

void main() {
  const service = SmartScoreService();

  group('SmartScoreService', () {
    test('calculates a valid score within 0 to 100', () {
      final result = service.calculate(
        _product(id: 'one', name: 'Product One', price: 10000),
      );

      expect(result.score, inInclusiveRange(0, 100));
      expect(result.valueScore, inInclusiveRange(0, 100));
      expect(result.qualityScore, inInclusiveRange(0, 100));
      expect(result.availabilityScore, inInclusiveRange(0, 100));
      expect(result.offerScore, inInclusiveRange(0, 100));
    });

    test('calculates discount contribution to value score', () {
      final withoutDiscount = service.calculate(
        _product(id: 'one', name: 'Product One', price: 10000),
      );

      final withDiscount = service.calculate(
        _product(
          id: 'two',
          name: 'Product Two',
          price: 8000,
          originalPrice: 10000,
        ),
      );

      expect(withDiscount.valueScore, greaterThan(withoutDiscount.valueScore));
    });

    test('offer with text receives stronger offer score', () {
      final noOffer = service.calculate(
        _product(id: 'one', name: 'Product One', price: 10000),
      );

      final offer = service.calculate(
        _product(
          id: 'two',
          name: 'Product Two',
          price: 10000,
          hasOffer: true,
          offerText: '10% off',
        ),
      );

      expect(offer.offerScore, greaterThan(noOffer.offerScore));
    });

    test('unavailable product receives lower availability score', () {
      final available = service.calculate(
        _product(id: 'one', name: 'Available', price: 10000, stock: 10),
      );

      final unavailable = service.calculate(
        _product(
          id: 'two',
          name: 'Unavailable',
          price: 10000,
          stock: 0,
          isAvailable: false,
        ),
      );

      expect(
        unavailable.availabilityScore,
        lessThan(available.availabilityScore),
      );
    });

    test('higher rating and review confidence improve quality score', () {
      final lower = service.calculate(
        _product(
          id: 'one',
          name: 'Lower Rated',
          price: 10000,
          rating: 3,
          reviewCount: 5,
        ),
      );

      final higher = service.calculate(
        _product(
          id: 'two',
          name: 'Higher Rated',
          price: 10000,
          rating: 5,
          reviewCount: 100,
        ),
      );

      expect(higher.qualityScore, greaterThan(lower.qualityScore));
    });

    test('additional purchase costs are included in true cost', () {
      final result = service.calculate(
        _product(id: 'one', name: 'Product One', price: 10000),
        travelCost: 500,
        deliveryCost: 300,
        installationCost: 200,
      );

      expect(result.productPrice, 10000);
      expect(result.travelCost, 500);
      expect(result.deliveryCost, 300);
      expect(result.installationCost, 200);
      expect(result.additionalCost, 1000);
      expect(result.trueCost, 11000);
    });

    test('additional costs can reduce the final Smart Score', () {
      final noAdditionalCosts = service.calculate(
        _product(id: 'one', name: 'Product One', price: 10000),
      );

      final withAdditionalCosts = service.calculate(
        _product(id: 'two', name: 'Product Two', price: 10000),
        travelCost: 1000,
        deliveryCost: 1000,
        installationCost: 1000,
      );

      expect(withAdditionalCosts.score, lessThan(noAdditionalCosts.score));
    });

    test('invalid product price produces safe value score', () {
      final result = service.calculate(
        _product(id: 'zero', name: 'Invalid Price', price: 0),
      );

      expect(result.valueScore, 0);
      expect(result.score, inInclusiveRange(0, 100));
    });

    test('score labels match score ranges', () {
      final result = service.calculate(
        _product(
          id: 'one',
          name: 'Product One',
          price: 10000,
          rating: 5,
          reviewCount: 500,
          stock: 10,
          hasOffer: true,
          offerText: 'Best offer',
          originalPrice: 15000,
        ),
      );

      expect(const <String>[
        'Excellent choice',
        'Good choice',
        'Fair choice',
        'Needs consideration',
      ], contains(result.scoreLabel));

      expect(result.scoreDescription, isNotEmpty);
    });
  });
}
