import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shopwise_v1/models/product.dart';
import 'package:shopwise_v1/services/customer/compare_service.dart';

class _FakeFirebaseAuth implements FirebaseAuth {
  _FakeFirebaseAuth(this._user);

  final User? _user;

  @override
  User? get currentUser => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Product _product({
  required String id,
  required String shopId,
  String category = 'Furniture',
}) {
  return Product(
    id: id,
    shopId: shopId,
    ownerId: 'owner-$shopId',
    name: 'Product $id',
    category: category,
    description: 'Test product',
    price: 10000,
    stock: 10,
    isAvailable: true,
    imageUrls: const [],
    rating: 4.5,
    reviewCount: 20,
    hasOffer: false,
  );
}

Future<void> seedProduct(
  FakeFirebaseFirestore firestore,
  Product product,
) async {
  await firestore.collection('products').doc(product.id).set({
    ...product.toMap(),
    'id': product.id,
  });
}

void main() {
  group('CompareService', () {
    late FakeFirebaseFirestore firestore;
    late _FakeUser user;
    late _FakeFirebaseAuth auth;
    late CompareService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      user = _FakeUser('test-user');
      auth = _FakeFirebaseAuth(user);

      service = CompareService(firestore: firestore, auth: auth);
    });

    test('starts with no compared products', () async {
      expect(await service.isCompared('product-1'), isFalse);
    });

    test('toggleSameProduct adds a product', () async {
      final product = _product(id: 'product-1', shopId: 'shop-1');

      final added = await service.toggleSameProduct(product);

      expect(added, isTrue);
      expect(await service.isCompared('product-1'), isTrue);
    });

    test('toggleSameProduct removes an already compared product', () async {
      final product = _product(id: 'product-1', shopId: 'shop-1');

      await service.toggleSameProduct(product);

      final removed = await service.toggleSameProduct(product);

      expect(removed, isFalse);
      expect(await service.isCompared('product-1'), isFalse);
    });

    test('accepts multiple products from the same shop', () async {
      final products = List.generate(
        4,
        (index) => _product(id: 'product-${index + 1}', shopId: 'shop-1'),
      );

      for (final product in products) {
        final added = await service.toggleSameProduct(product);
        expect(added, isTrue);
      }

      for (final product in products) {
        expect(await service.isCompared(product.id), isTrue);
      }
    });

    test('rejects a product from a different category', () async {
      final first = _product(
        id: 'product-1',
        shopId: 'shop-1',
        category: 'Furniture',
      );

      final second = _product(
        id: 'product-2',
        shopId: 'shop-2',
        category: 'Electronics',
      );

      await service.toggleSameProduct(first);

      await seedProduct(firestore, first);

      expect(
        () => service.toggleSameProduct(second),
        throwsA(
          predicate(
            (error) => error.toString().contains(
              'Compare products from the same category',
            ),
          ),
        ),
      );
    });

    test('accepts same category with different shops', () async {
      final first = _product(id: 'product-1', shopId: 'shop-1');

      final second = _product(id: 'product-2', shopId: 'shop-2');

      await seedProduct(firestore, first);

      await service.toggleSameProduct(first);
      final added = await service.toggleSameProduct(second);

      expect(added, isTrue);
      expect(await service.isCompared('product-1'), isTrue);
      expect(await service.isCompared('product-2'), isTrue);
    });

    test('addProductPair adds both selected and alternative', () async {
      final selected = _product(id: 'product-1', shopId: 'shop-1');

      final alternative = _product(id: 'product-2', shopId: 'shop-2');

      await service.addProductPair(selected, alternative);

      expect(await service.isCompared('product-1'), isTrue);
      expect(await service.isCompared('product-2'), isTrue);
    });

    test('addProductPair accepts products from the same shop', () async {
      final selected = _product(id: 'product-1', shopId: 'shop-1');
      final alternative = _product(id: 'product-2', shopId: 'shop-1');

      await service.addProductPair(selected, alternative);

      expect(await service.isCompared('product-1'), isTrue);
      expect(await service.isCompared('product-2'), isTrue);
    });

    test(
      'addProductPair is idempotent when alternative already compared',
      () async {
        final selected = _product(id: 'product-1', shopId: 'shop-1');

        final alternative = _product(id: 'product-2', shopId: 'shop-2');

        await service.addProductPair(selected, alternative);
        await service.addProductPair(selected, alternative);

        expect(await service.isCompared('product-1'), isTrue);
        expect(await service.isCompared('product-2'), isTrue);
      },
    );

    test('rejects more than four compared products', () async {
      final products = List.generate(
        5,
        (index) => _product(id: 'product-$index', shopId: 'shop-$index'),
      );

      for (final product in products.take(4)) {
        await seedProduct(firestore, product);
      }

      await service.toggleSameProduct(products[0]);

      for (final product in products.skip(1).take(3)) {
        await service.toggleSameProduct(product);
      }

      await seedProduct(firestore, products[4]);

      expect(
        () => service.toggleSameProduct(products[4]),
        throwsA(
          predicate(
            (error) => error.toString().contains(
              'You can compare up to 4 products at a time.',
            ),
          ),
        ),
      );
    });

    test('clear removes all compared products', () async {
      final first = _product(id: 'product-1', shopId: 'shop-1');

      final second = _product(id: 'product-2', shopId: 'shop-2');

      await service.addProductPair(first, second);

      await service.clear();

      expect(await service.isCompared('product-1'), isFalse);
      expect(await service.isCompared('product-2'), isFalse);
    });

    test('watchCompareIds emits compared product IDs', () async {
      final stream = service.watchCompareIds();

      expect(await stream.first, isEmpty);

      final first = _product(id: 'product-1', shopId: 'shop-1');

      final second = _product(id: 'product-2', shopId: 'shop-2');

      await service.addProductPair(first, second);

      final ids = await stream.firstWhere((value) => value.length == 2);

      expect(ids, containsAll(<String>['product-1', 'product-2']));
    });

    test('throws when adding while signed out', () async {
      final signedOutService = CompareService(
        firestore: firestore,
        auth: _FakeFirebaseAuth(null),
      );

      final product = _product(id: 'product-1', shopId: 'shop-1');

      expect(
        () => signedOutService.toggleSameProduct(product),
        throwsA(
          predicate(
            (error) => error.toString().contains(
              'Please sign in to compare products.',
            ),
          ),
        ),
      );
    });
  });
}
