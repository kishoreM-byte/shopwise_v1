import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/services/product_service.dart';

class _SignedOutAuth implements FirebaseAuth {
  @override
  User? get currentUser => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('ProductService saved product queries', () {
    late FakeFirebaseFirestore firestore;
    late ProductService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = ProductService(firestore: firestore, auth: _SignedOutAuth());
    });

    Future<List<String>> seedProducts(int count) async {
      final ids = List<String>.generate(count, (index) => 'product-$index');
      final batch = firestore.batch();
      for (final id in ids) {
        batch.set(firestore.collection('products').doc(id), <String, dynamic>{
          'id': id,
          'shopId': 'shop-1',
          'ownerId': 'owner-1',
          'name': id,
          'category': 'Furniture',
          'description': '',
          'price': 100,
          'stock': 1,
          'isAvailable': true,
          'imageUrls': <String>[],
          'rating': 0,
          'reviewCount': 0,
          'hasOffer': false,
        });
      }
      await batch.commit();
      return ids;
    }

    test(
      'loads a wishlist larger than Firestore whereIn limit in order',
      () async {
        final ids = await seedProducts(31);
        final requestedIds = ids.reversed.toSet();

        final products = await service.getProductsByIds(requestedIds);

        expect(products.map((product) => product.id), ids.reversed);
      },
    );

    test('watches a wishlist larger than Firestore whereIn limit', () async {
      final ids = await seedProducts(31);

      final products = await service
          .watchProductsByIds(ids.toSet())
          .firstWhere((items) => items.length == ids.length);

      expect(products.map((product) => product.id), ids);
    });
  });
}
