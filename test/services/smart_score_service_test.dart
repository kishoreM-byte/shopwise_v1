import 'package:flutter_test/flutter_test.dart';

import 'package:shopwise_v1/models/product.dart';
import 'package:shopwise_v1/services/smart_score_service.dart';

void main() {
  const service = SmartScoreService();

  group('SmartScoreService', () {
    test('returns a valid score between 0 and 100', () {
      final product = Product(
        id: 'test-product',
        shopId: 'test-shop',
        ownerId: 'test-owner',
        category: 'General',
        description: 'Test product description',
        imageUrls: const [],
        name: 'Test Product',
        price: 10000,
        rating: 4.5,
        reviewCount: 100,
        stock: 10,
        isAvailable: true,
        hasOffer: true,
        offerText: '10% off',
      );

      final result = service.calculate(product);

      expect(result.score, inInclusiveRange(0, 100));
      expect(result.valueScore, inInclusiveRange(0, 100));
      expect(result.qualityScore, inInclusiveRange(0, 100));
      expect(result.availabilityScore, inInclusiveRange(0, 100));
      expect(result.offerScore, inInclusiveRange(0, 100));
    });

    test('true cost includes travel, delivery and installation', () {
      final product = Product(
        id: 'test-product',
        shopId: 'test-shop',
        ownerId: 'test-owner',
        category: 'General',
        description: 'Test product description',
        imageUrls: const [],
        name: 'Test Product',
        price: 10000,
        rating: 4,
        reviewCount: 20,
        stock: 5,
        isAvailable: true,
        hasOffer: false,
      );

      final result = service.calculate(
        product,
        travelCost: 200,
        deliveryCost: 300,
        installationCost: 500,
      );

      expect(result.productPrice, 10000);
      expect(result.travelCost, 200);
      expect(result.deliveryCost, 300);
      expect(result.installationCost, 500);
      expect(result.additionalCost, 1000);
      expect(result.trueCost, 11000);
    });

    test('negative additional costs are safely ignored', () {
      final product = Product(
        id: 'test-product',
        shopId: 'test-shop',
        ownerId: 'test-owner',
        category: 'General',
        description: 'Test product description',
        imageUrls: const [],
        name: 'Test Product',
        price: 10000,
        rating: 4,
        reviewCount: 20,
        stock: 5,
        isAvailable: true,
        hasOffer: false,
      );

      final result = service.calculate(
        product,
        travelCost: -100,
        deliveryCost: -200,
        installationCost: -300,
      );

      expect(result.travelCost, 0);
      expect(result.deliveryCost, 0);
      expect(result.installationCost, 0);
      expect(result.additionalCost, 0);
      expect(result.trueCost, 10000);
    });

    test('unavailable product receives a low availability score', () {
      final product = Product(
        id: 'test-product',
        shopId: 'test-shop',
        ownerId: 'test-owner',
        category: 'General',
        description: 'Test product description',
        imageUrls: const [],
        name: 'Unavailable Product',
        price: 5000,
        rating: 4,
        reviewCount: 20,
        stock: 0,
        isAvailable: false,
        hasOffer: false,
      );

      final result = service.calculate(product);

      expect(result.availabilityScore, 20);
    });

    test('excellent score gets correct label', () {
      final product = Product(
        id: 'test-product',
        shopId: 'test-shop',
        ownerId: 'test-owner',
        category: 'General',
        description: 'Test product description',
        imageUrls: const [],
        name: 'Excellent Product',
        price: 5000,
        originalPrice: 7000,
        rating: 5,
        reviewCount: 500,
        stock: 10,
        isAvailable: true,
        hasOffer: true,
        offerText: 'Special offer',
      );

      final result = service.calculate(product);

      expect(result.scoreLabel, 'Excellent choice');
      expect(result.score, greaterThanOrEqualTo(85));
    });
  });
}
