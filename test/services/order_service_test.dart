import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopwise_v1/models/product.dart';
import 'package:shopwise_v1/models/shop.dart';
import 'package:shopwise_v1/models/order.dart';
import 'package:shopwise_v1/services/customer/order_service.dart';

class _FakeAuth implements FirebaseAuth {
  _FakeAuth(this._user);

  User? _user;

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
  group('OrderService', () {
    late FakeFirebaseFirestore firestore;
    late OrderService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      firestore = FakeFirebaseFirestore();
      service = OrderService(
        firestore: firestore,
        auth: _FakeAuth(_FakeUser('customer-1')),
      );
      await firestore
          .collection('products')
          .doc('product-1')
          .set(_productData());
      await firestore.collection('shops').doc('shop-1').set(_shopData());
    });

    test(
      'direct order request id survives service recreation until confirmed',
      () async {
        final firstAttempt = await service.getOrCreateDirectOrderRequest(
          'product-1',
        );
        final firstId = firstAttempt.requestId;
        expect(firstAttempt.customerId, 'customer-1');
        final recreatedService = OrderService(
          firestore: firestore,
          auth: _FakeAuth(_FakeUser('customer-1')),
        );

        expect(
          (await recreatedService.getOrCreateDirectOrderRequest(
            'product-1',
          )).requestId,
          firstId,
        );
        expect(
          (await recreatedService.getOrCreateDirectOrderRequest(
            'product-2',
          )).requestId,
          isNot(firstId),
        );

        await recreatedService.completeDirectOrderRequest(
          customerId: 'customer-1',
          productId: 'product-1',
          requestId: firstId,
        );
        expect(
          (await service.getOrCreateDirectOrderRequest('product-1')).requestId,
          isNot(firstId),
        );
      },
    );

    test(
      'direct checkout rejects an account switch with a pending request',
      () async {
        final auth = _FakeAuth(_FakeUser('customer-1'));
        final signedInService = OrderService(firestore: firestore, auth: auth);
        final attempt = await signedInService.getOrCreateDirectOrderRequest(
          'product-1',
        );
        auth._user = _FakeUser('customer-2');

        await expectLater(
          signedInService.createDirectOrder(
            product: Product.fromMap(_productData()..['id'] = 'product-1'),
            shop: Shop.fromMap(_shopData()..['id'] = 'shop-1'),
            quantity: 1,
            purchaseMode: 'offline',
            fulfillmentType: 'pickup',
            requestId: attempt.requestId,
            expectedCustomerId: attempt.customerId,
          ),
          throwsA(
            predicate((error) => error.toString().contains('account changed')),
          ),
        );

        expect((await firestore.collection('orders').get()).docs, isEmpty);
        expect(
          (await firestore.collection('products').doc('product-1').get())
              .data()?['stock'],
          5,
        );
      },
    );

    test(
      'direct order retries with same request ID return one saved order',
      () async {
        final requestId = service.createOrderRequestId();
        final product = Product.fromMap(_productData()..['id'] = 'product-1');
        final shop = Shop.fromMap(_shopData()..['id'] = 'shop-1');

        final first = await service.createDirectOrder(
          product: product,
          shop: shop,
          quantity: 2,
          purchaseMode: 'online',
          fulfillmentType: 'delivery',
          requestId: requestId,
          expectedCustomerId: 'customer-1',
        );
        final retry = await service.createDirectOrder(
          product: product,
          shop: shop,
          quantity: 2,
          purchaseMode: 'online',
          fulfillmentType: 'delivery',
          requestId: requestId,
          expectedCustomerId: 'customer-1',
        );

        expect(retry.id, first.id);
        expect(retry.totalAmount, 2250);
        expect((await firestore.collection('orders').get()).docs, hasLength(1));
        expect(
          (await firestore.collection('products').doc('product-1').get())
              .data()?['stock'],
          3,
        );
      },
    );

    test(
      'concurrent direct order requests with same key create one order',
      () async {
        final requestId = service.createOrderRequestId();
        final product = Product.fromMap(_productData()..['id'] = 'product-1');
        final shop = Shop.fromMap(_shopData()..['id'] = 'shop-1');

        final orders = await Future.wait([
          service.createDirectOrder(
            product: product,
            shop: shop,
            quantity: 1,
            purchaseMode: 'offline',
            fulfillmentType: 'pickup',
            requestId: requestId,
            expectedCustomerId: 'customer-1',
          ),
          service.createDirectOrder(
            product: product,
            shop: shop,
            quantity: 1,
            purchaseMode: 'offline',
            fulfillmentType: 'pickup',
            requestId: requestId,
            expectedCustomerId: 'customer-1',
          ),
        ]);

        expect(orders[0].id, orders[1].id);
        expect((await firestore.collection('orders').get()).docs, hasLength(1));
        expect(
          (await firestore.collection('products').doc('product-1').get())
              .data()?['stock'],
          4,
        );
      },
    );

    test('accepted enquiry retry does not create another order', () async {
      await firestore.collection('enquiries').doc('enquiry-1').set({
        'id': 'enquiry-1',
        'customerId': 'customer-1',
        'ownerId': 'owner-1',
        'productId': 'product-1',
        'shopId': 'shop-1',
        'quantity': 2,
        'status': 'accepted',
      });

      final order = await service.createOrderFromAcceptedEnquiry('enquiry-1');
      await expectLater(
        service.createOrderFromAcceptedEnquiry('enquiry-1'),
        throwsA(isA<Exception>()),
      );

      expect(order.id, 'enquiry-1');
      expect((await firestore.collection('orders').get()).docs, hasLength(1));
      expect(
        (await firestore.collection('enquiries').doc('enquiry-1').get())
            .data()?['orderId'],
        'enquiry-1',
      );
      expect(
        (await firestore.collection('products').doc('product-1').get())
            .data()?['stock'],
        3,
      );
    });

    test(
      'accepted enquiry rejects fractional quantities without reservation',
      () async {
        await firestore.collection('enquiries').doc('enquiry-fraction').set({
          'id': 'enquiry-fraction',
          'customerId': 'customer-1',
          'ownerId': 'owner-1',
          'productId': 'product-1',
          'shopId': 'shop-1',
          'quantity': 1.5,
          'status': 'accepted',
        });

        await expectLater(
          service.createOrderFromAcceptedEnquiry('enquiry-fraction'),
          throwsA(
            predicate(
              (error) => error.toString().contains('Invalid purchase quantity'),
            ),
          ),
        );
        expect((await firestore.collection('orders').get()).docs, isEmpty);
        expect(
          (await firestore.collection('products').doc('product-1').get())
              .data()?['stock'],
          5,
        );
      },
    );

    test(
      'direct order validates latest stock inside the transaction',
      () async {
        await firestore.collection('products').doc('product-1').update({
          'stock': 0,
          'isAvailable': false,
        });
        final product = Product.fromMap(_productData()..['id'] = 'product-1');
        final shop = Shop.fromMap(_shopData()..['id'] = 'shop-1');

        await expectLater(
          service.createDirectOrder(
            product: product,
            shop: shop,
            quantity: 1,
            purchaseMode: 'offline',
            fulfillmentType: 'pickup',
            requestId: service.createOrderRequestId(),
            expectedCustomerId: 'customer-1',
          ),
          throwsA(
            predicate(
              (error) => error.toString().contains('currently unavailable'),
            ),
          ),
        );
        expect((await firestore.collection('orders').get()).docs, isEmpty);
      },
    );

    test(
      'direct checkout refuses an unknown applicable delivery charge',
      () async {
        final incompleteShop = _shopData()..remove('deliveryCharge');
        await firestore.collection('shops').doc('shop-1').set(incompleteShop);
        final product = Product.fromMap(_productData()..['id'] = 'product-1');
        final shop = Shop.fromMap(_shopData()..['id'] = 'shop-1');

        await expectLater(
          service.createDirectOrder(
            product: product,
            shop: shop,
            quantity: 1,
            purchaseMode: 'online',
            fulfillmentType: 'delivery',
            requestId: service.createOrderRequestId(),
            expectedCustomerId: 'customer-1',
          ),
          throwsA(
            predicate(
              (error) =>
                  error.toString().contains('delivery charge is unavailable'),
            ),
          ),
        );
        expect((await firestore.collection('orders').get()).docs, isEmpty);
      },
    );

    test('invalid quantities are rejected before writing an order', () async {
      final product = Product.fromMap(_productData()..['id'] = 'product-1');
      final shop = Shop.fromMap(_shopData()..['id'] = 'shop-1');

      for (final quantity in [0, -1, 6]) {
        await expectLater(
          service.createDirectOrder(
            product: product,
            shop: shop,
            quantity: quantity,
            purchaseMode: 'offline',
            fulfillmentType: 'pickup',
            requestId: service.createOrderRequestId(),
            expectedCustomerId: 'customer-1',
          ),
          throwsA(isA<Exception>()),
        );
      }
      expect((await firestore.collection('orders').get()).docs, isEmpty);
    });

    test('cancellation restores reserved stock only once', () async {
      final product = Product.fromMap(_productData()..['id'] = 'product-1');
      final shop = Shop.fromMap(_shopData()..['id'] = 'shop-1');
      final order = await service.createDirectOrder(
        product: product,
        shop: shop,
        quantity: 2,
        purchaseMode: 'offline',
        fulfillmentType: 'pickup',
        requestId: service.createOrderRequestId(),
        expectedCustomerId: 'customer-1',
      );
      final ownerService = OrderService(
        firestore: firestore,
        auth: _FakeAuth(_FakeUser('owner-1')),
      );

      await ownerService.updateOrderStatus(order.id, 'cancelled');
      expect(
        (await firestore.collection('products').doc('product-1').get())
            .data()?['stock'],
        5,
      );
      expect(
        (await firestore.collection('orders').doc(order.id).get())
            .data()?['inventoryAdjusted'],
        false,
      );

      await expectLater(
        ownerService.updateOrderStatus(order.id, 'cancelled'),
        throwsA(isA<Exception>()),
      );
      expect(
        (await firestore.collection('products').doc('product-1').get())
            .data()?['stock'],
        5,
      );
    });

    test(
      'cancellation fails without changing order when product is missing',
      () async {
        final product = Product.fromMap(_productData()..['id'] = 'product-1');
        final shop = Shop.fromMap(_shopData()..['id'] = 'shop-1');
        final order = await service.createDirectOrder(
          product: product,
          shop: shop,
          quantity: 2,
          purchaseMode: 'offline',
          fulfillmentType: 'pickup',
          requestId: service.createOrderRequestId(),
          expectedCustomerId: 'customer-1',
        );
        final ownerService = OrderService(
          firestore: firestore,
          auth: _FakeAuth(_FakeUser('owner-1')),
        );

        await firestore.collection('products').doc('product-1').delete();

        await expectLater(
          ownerService.updateOrderStatus(order.id, 'cancelled'),
          throwsA(isA<Exception>()),
        );

        final savedOrder =
            (await firestore.collection('orders').doc(order.id).get()).data();
        expect(savedOrder?['status'], 'placed');
        expect(savedOrder?['inventoryAdjusted'], true);
        expect(
          (await firestore.collection('products').doc('product-1').get())
              .exists,
          false,
        );
      },
    );

    test(
      'cancellation fails without changing order when product stock is negative',
      () async {
        final product = Product.fromMap(_productData()..['id'] = 'product-1');
        final shop = Shop.fromMap(_shopData()..['id'] = 'shop-1');
        final order = await service.createDirectOrder(
          product: product,
          shop: shop,
          quantity: 2,
          purchaseMode: 'offline',
          fulfillmentType: 'pickup',
          requestId: service.createOrderRequestId(),
          expectedCustomerId: 'customer-1',
        );
        final ownerService = OrderService(
          firestore: firestore,
          auth: _FakeAuth(_FakeUser('owner-1')),
        );

        await firestore.collection('products').doc('product-1').update({
          'stock': -1,
        });

        await expectLater(
          ownerService.updateOrderStatus(order.id, 'cancelled'),
          throwsA(isA<Exception>()),
        );

        final savedOrder =
            (await firestore.collection('orders').doc(order.id).get()).data();
        final savedProduct =
            (await firestore.collection('products').doc('product-1').get())
                .data();

        expect(savedOrder?['status'], 'placed');
        expect(savedOrder?['inventoryAdjusted'], true);
        expect(savedProduct?['stock'], -1);
      },
    );

    test('completion consumes reserved stock without restoring it', () async {
      final product = Product.fromMap(_productData()..['id'] = 'product-1');
      final shop = Shop.fromMap(_shopData()..['id'] = 'shop-1');
      final order = await service.createDirectOrder(
        product: product,
        shop: shop,
        quantity: 1,
        purchaseMode: 'offline',
        fulfillmentType: 'pickup',
        requestId: service.createOrderRequestId(),
        expectedCustomerId: 'customer-1',
      );
      final ownerService = OrderService(
        firestore: firestore,
        auth: _FakeAuth(_FakeUser('owner-1')),
      );

      await ownerService.updateOrderStatus(order.id, 'accepted');
      await ownerService.updateOrderStatus(order.id, 'completed');
      expect(
        (await firestore.collection('products').doc('product-1').get())
            .data()?['stock'],
        4,
      );
    });
  });

  test('malformed persisted prices are marked unavailable', () {
    final order = ShopWiseOrder.fromMap(<String, dynamic>{
      'id': 'order-1',
      'quantity': 1,
      'unitPrice': 100,
      'subtotal': 100,
      'totalAmount': 100,
      'status': 'placed',
    });

    expect(order.hasValidPriceBreakdown, isFalse);
    expect(order.deliveryCharge, 0);
  });
}

Map<String, dynamic> _productData() => <String, dynamic>{
  'id': 'product-1',
  'shopId': 'shop-1',
  'ownerId': 'owner-1',
  'name': 'Oak table',
  'category': 'Table',
  'description': '',
  'price': 1000,
  'stock': 5,
  'isAvailable': true,
  'imageUrls': <String>[],
  'rating': 0,
  'reviewCount': 0,
  'hasOffer': false,
};

Map<String, dynamic> _shopData() => <String, dynamic>{
  'id': 'shop-1',
  'ownerId': 'owner-1',
  'name': 'Oak House',
  'category': 'Furniture',
  'description': '',
  'address': '',
  'phone': '',
  'rating': 0,
  'reviewCount': 0,
  'isOpen': true,
  'deliveryAvailable': true,
  'deliveryCharge': 200,
  'installationAvailable': true,
  'installationCharge': 50,
};
