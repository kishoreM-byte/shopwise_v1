import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/models/product.dart';

void main() {
  group('Product availability', () {
    const base = Product(
      id: 'chair-1',
      shopId: 'shop-1',
      ownerId: 'owner-1',
      name: 'Chair',
      category: 'Chair',
      description: '',
      price: 100,
      stock: 2,
      isAvailable: true,
      imageUrls: <String>[],
      rating: 0,
      reviewCount: 0,
      hasOffer: false,
    );

    test('requires both enabled availability and positive stock', () {
      expect(base.isAvailableForPurchase, isTrue);
      expect(base.copyWith(stock: 0).isAvailableForPurchase, isFalse);
      expect(base.copyWith(isAvailable: false).isAvailableForPurchase, isFalse);
    });
  });

  group('Product.fromMap image URLs', () {
    test('keeps valid remote URLs and ignores blank or malformed entries', () {
      final product = Product.fromMap(<String, dynamic>{
        'imageUrls': <dynamic>[
          ' https://images.example.com/product.jpg ',
          '',
          '   ',
          null,
          42,
          'file:///tmp/product.jpg',
          'not a url',
          'http://images.example.com/second.jpg',
        ],
      });

      expect(product.imageUrls, <String>[
        'https://images.example.com/product.jpg',
        'http://images.example.com/second.jpg',
      ]);
    });

    test('treats a malformed image field as no images', () {
      expect(
        Product.fromMap(<String, dynamic>{'imageUrls': 'broken'}).imageUrls,
        isEmpty,
      );
      expect(Product.fromMap(<String, dynamic>{}).imageUrls, isEmpty);
    });
  });
}
