import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/models/product.dart';
import 'package:shopwise_v1/models/shop.dart';
import 'package:shopwise_v1/services/product_service.dart';

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

const _shop = Shop(
  id: 'shop-1',
  ownerId: 'owner-1',
  name: 'Oak & Co.',
  category: 'Furniture',
  description: '',
  address: '',
  phone: '',
  rating: 0,
  reviewCount: 0,
  isOpen: true,
);

Product _product({String id = '', List<String> imageUrls = const <String>[]}) =>
    Product(
      id: id,
      shopId: 'shop-1',
      ownerId: 'owner-1',
      name: 'Oak chair',
      category: 'Furniture',
      description: '',
      price: 12000,
      stock: 2,
      isAvailable: true,
      imageUrls: imageUrls,
      rating: 0,
      reviewCount: 0,
      hasOffer: false,
    );

void main() {
  group('ProductService image URL persistence', () {
    late FakeFirebaseFirestore firestore;
    late ProductService service;

    setUp(() {
      firestore = FakeFirebaseFirestore();
      service = ProductService(
        firestore: firestore,
        auth: _FakeFirebaseAuth(_FakeUser('owner-1')),
        getMyShop: () async => _shop,
      );
    });

    test('create persists uploaded URLs for parsing after reload', () async {
      const urls = <String>[
        'https://res.cloudinary.com/shopwise/image/upload/chair-front.jpg',
        'https://res.cloudinary.com/shopwise/image/upload/chair-side.jpg',
      ];

      final productId = await service.addProduct(_product(imageUrls: urls));
      final saved = await firestore.collection('products').doc(productId).get();
      final reloaded = Product.fromMap(saved.data()!);

      expect(saved.data()?['imageUrls'], urls);
      expect(reloaded.imageUrls, urls);
      expect(reloaded.id, productId);
    });

    test(
      'edit persists the unchanged existing URLs and newly uploaded URLs',
      () async {
        const existingUrls = <String>[
          'https://res.cloudinary.com/shopwise/image/upload/chair-front.jpg',
        ];
        const updatedUrls = <String>[
          ...existingUrls,
          'https://res.cloudinary.com/shopwise/image/upload/chair-side.jpg',
        ];
        await firestore
            .collection('products')
            .doc('chair-1')
            .set(_product(id: 'chair-1', imageUrls: existingUrls).toMap());

        await service.updateProduct(
          _product(id: 'chair-1', imageUrls: updatedUrls),
        );

        final saved = await firestore
            .collection('products')
            .doc('chair-1')
            .get();
        final reloaded = Product.fromMap(saved.data()!);

        expect(reloaded.imageUrls, updatedUrls);
        expect(reloaded.shopId, 'shop-1');
        expect(reloaded.ownerId, 'owner-1');
      },
    );

    test(
      'hide marks a product unavailable without deleting its record',
      () async {
        await firestore
            .collection('products')
            .doc('chair-1')
            .set(_product(id: 'chair-1').toMap());

        await service.deleteProduct(' chair-1 ');

        final saved = await firestore
            .collection('products')
            .doc('chair-1')
            .get();

        expect(saved.exists, isTrue);
        expect(saved.data()?['isAvailable'], isFalse);
        expect(saved.data()?['ownerId'], 'owner-1');
        expect(saved.data()?['stock'], 2);
      },
    );

    test('another owner cannot update a product', () async {
      await firestore
          .collection('products')
          .doc('chair-1')
          .set(_product(id: 'chair-1').toMap());

      final otherOwnerService = ProductService(
        firestore: firestore,
        auth: _FakeFirebaseAuth(_FakeUser('owner-2')),
        getMyShop: () async => _shop,
      );

      await expectLater(
        otherOwnerService.updateProduct(
          _product(id: 'chair-1').copyWith(name: 'Changed chair'),
        ),
        throwsA(isA<Exception>()),
      );

      final saved = await firestore.collection('products').doc('chair-1').get();
      expect(saved.data()?['name'], 'Oak chair');
    });

    test(
      'create failure before persistence leaves no product document',
      () async {
        final signedOutService = ProductService(
          firestore: firestore,
          auth: _FakeFirebaseAuth(null),
          getMyShop: () async => _shop,
        );

        await expectLater(
          signedOutService.addProduct(
            _product(
              imageUrls: const <String>[
                'https://res.cloudinary.com/shopwise/image/upload/chair.jpg',
              ],
            ),
          ),
          throwsA(isA<Exception>()),
        );
        expect((await firestore.collection('products').get()).docs, isEmpty);
      },
    );
  });
}
