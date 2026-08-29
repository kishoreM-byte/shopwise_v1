import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:shopwise_v1/services/customer/wishlist_service.dart';

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

void main() {
  group('WishlistService', () {
    late FakeFirebaseFirestore firestore;
    late _FakeUser user;
    late _FakeFirebaseAuth auth;
    late WishlistService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      user = _FakeUser('test-user');
      auth = _FakeFirebaseAuth(user);
      service = WishlistService(
        firestore: firestore,
        auth: auth,
      );
    });

    test('starts with no saved products', () async {
      expect(await service.isSaved('product-1'), isFalse);
    });

    test('toggle saves a product', () async {
      final saved = await service.toggle('product-1');

      expect(saved, isTrue);
      expect(await service.isSaved('product-1'), isTrue);

      final doc = await firestore
          .collection('users')
          .doc('test-user')
          .collection('wishlist')
          .doc('product-1')
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()?['productId'], 'product-1');
      expect(doc.data()?['savedAt'], isNotNull);
    });

    test('toggle removes an already saved product', () async {
      await service.toggle('product-1');

      final removed = await service.toggle('product-1');

      expect(removed, isFalse);
      expect(await service.isSaved('product-1'), isFalse);
    });

    test('watchWishlistIds emits saved product IDs', () async {
      final stream = service.watchWishlistIds();

      expect(await stream.first, isEmpty);

      await service.toggle('product-1');
      await service.toggle('product-2');

      final ids = await stream.firstWhere(
        (value) => value.length == 2,
      );

      expect(ids, containsAll(<String>['product-1', 'product-2']));
    });
  });

  test('throws when toggling while signed out', () async {
    final firestore = FakeFirebaseFirestore();
    final auth = _FakeFirebaseAuth(null);
    final service = WishlistService(
      firestore: firestore,
      auth: auth,
    );

    expect(
      () => service.toggle('product-1'),
      throwsA(
        predicate(
          (error) =>
              error.toString().contains('Please sign in to save products.'),
        ),
      ),
    );
  });
}
