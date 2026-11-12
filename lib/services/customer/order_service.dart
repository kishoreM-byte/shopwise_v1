import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/shop.dart';
import 'order_lifecycle.dart';

class OrderService {
  OrderService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _orders =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _enquiries =>
      _firestore.collection('enquiries');

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection('products');

  CollectionReference<Map<String, dynamic>> get _shops =>
      _firestore.collection('shops');

  /// Generates a new idempotency key for a direct-checkout attempt.
  String createOrderRequestId() => _orders.doc().id;

  Future<DirectOrderRequest> getOrCreateDirectOrderRequest(
    String productId,
  ) async {
    final user = _auth.currentUser;
    final normalizedProductId = productId.trim();
    if (user == null || normalizedProductId.isEmpty) {
      throw Exception('Sign in and refresh the product before ordering.');
    }

    final preferences = await SharedPreferences.getInstance();
    final key = _directOrderRequestPreferenceKey(user.uid, normalizedProductId);
    final existing = preferences.getString(key)?.trim();
    if (existing != null && existing.isNotEmpty) {
      if (_auth.currentUser?.uid != user.uid) {
        throw Exception('Your account changed. Reopen checkout to continue.');
      }
      return DirectOrderRequest(customerId: user.uid, requestId: existing);
    }

    final requestId = createOrderRequestId();
    if (!await preferences.setString(key, requestId)) {
      throw Exception('Could not save this order attempt. Please retry.');
    }
    if (_auth.currentUser?.uid != user.uid) {
      throw Exception('Your account changed. Reopen checkout to continue.');
    }
    return DirectOrderRequest(customerId: user.uid, requestId: requestId);
  }

  Future<void> completeDirectOrderRequest({
    required String customerId,
    required String productId,
    required String requestId,
  }) async {
    final normalizedProductId = productId.trim();
    final normalizedCustomerId = customerId.trim();
    if (normalizedCustomerId.isEmpty || normalizedProductId.isEmpty) return;

    final preferences = await SharedPreferences.getInstance();
    final key = _directOrderRequestPreferenceKey(
      normalizedCustomerId,
      normalizedProductId,
    );
    if (preferences.getString(key) == requestId) {
      if (!await preferences.setString(key, createOrderRequestId())) {
        throw Exception('The completed order could not reset its retry key.');
      }
    }
  }

  String _directOrderRequestPreferenceKey(String userId, String productId) =>
      'shopwise.pending_direct_order.$userId.$productId';

  Future<ShopWiseOrder> createOrderFromAcceptedEnquiry(String enquiryId) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to place your order.');
    }

    final String normalizedId = enquiryId.trim();

    if (normalizedId.isEmpty) {
      throw Exception('Invalid enquiry.');
    }

    final DocumentReference<Map<String, dynamic>> orderRef = _orders.doc(
      normalizedId,
    );

    final DocumentReference<Map<String, dynamic>> enquiryRef = _enquiries.doc(
      normalizedId,
    );

    late ShopWiseOrder createdOrder;

    await _firestore.runTransaction((transaction) async {
      /*
       * IMPORTANT:
       * Read every document that will participate in the transaction
       * before performing any writes.
       */
      final existingOrder = await transaction.get(orderRef);

      if (existingOrder.exists) {
        final data = existingOrder.data();

        if (data != null && data['customerId'] == user.uid) {
          throw Exception('An order has already been placed for this enquiry.');
        }

        throw Exception('This enquiry already has an order.');
      }

      final enquirySnapshot = await transaction.get(enquiryRef);

      if (!enquirySnapshot.exists || enquirySnapshot.data() == null) {
        throw Exception('Enquiry no longer exists.');
      }

      final enquiryData = enquirySnapshot.data()!;

      final String customerId = (enquiryData['customerId'] as String? ?? '')
          .trim();

      if (customerId != user.uid) {
        throw Exception('You are not authorized to purchase this enquiry.');
      }

      final String enquiryStatus = (enquiryData['status'] as String? ?? '')
          .trim()
          .toLowerCase();

      if (enquiryStatus != 'accepted') {
        throw Exception('Only an accepted enquiry can be purchased.');
      }

      final String existingEnquiryOrderId =
          (enquiryData['orderId'] as String? ?? '').trim();

      if (existingEnquiryOrderId.isNotEmpty) {
        throw Exception('An order has already been placed for this enquiry.');
      }

      final String productId = (enquiryData['productId'] as String? ?? '')
          .trim();

      final String shopId = (enquiryData['shopId'] as String? ?? '').trim();

      if (productId.isEmpty) {
        throw Exception('Product information is missing from this enquiry.');
      }

      if (shopId.isEmpty) {
        throw Exception('Shop information is missing from this enquiry.');
      }

      final DocumentReference<Map<String, dynamic>> productRef = _products.doc(
        productId,
      );

      final DocumentReference<Map<String, dynamic>> shopRef = _shops.doc(
        shopId,
      );

      final productSnapshot = await transaction.get(productRef);
      final shopSnapshot = await transaction.get(shopRef);

      if (!productSnapshot.exists || productSnapshot.data() == null) {
        throw Exception('The product is no longer available.');
      }

      if (!shopSnapshot.exists || shopSnapshot.data() == null) {
        throw Exception('The shop is no longer available.');
      }

      final Map<String, dynamic> productData = Map<String, dynamic>.from(
        productSnapshot.data()!,
      );

      productData['id'] = productSnapshot.id;

      final Map<String, dynamic> shopData = Map<String, dynamic>.from(
        shopSnapshot.data()!,
      );

      shopData['id'] = shopSnapshot.id;

      final Product product = Product.fromMap(productData);
      final Shop shop = Shop.fromMap(shopData);

      if (!product.isAvailable || product.stock <= 0) {
        throw Exception('This product is currently unavailable.');
      }

      if (shop.deliveryAvailable && !shop.deliveryChargeIsKnown) {
        throw Exception(
          'The delivery charge is unavailable. Please contact the shop.',
        );
      }
      if (shop.installationAvailable && !shop.installationChargeIsKnown) {
        throw Exception(
          'The installation charge is unavailable. Please contact the shop.',
        );
      }

      final rawQuantity = enquiryData['quantity'];
      if (rawQuantity is! num ||
          !rawQuantity.isFinite ||
          rawQuantity < 1 ||
          rawQuantity != rawQuantity.toInt()) {
        throw Exception('Invalid purchase quantity.');
      }
      final int quantity = rawQuantity.toInt();

      if (quantity > product.stock) {
        throw Exception(
          'Only ${product.stock} unit'
          '${product.stock == 1 ? '' : 's'} currently available.',
        );
      }

      final double subtotal = product.price * quantity;

      final double deliveryCharge = shop.deliveryAvailable
          ? shop.deliveryCharge
          : 0;

      final double installationCharge = shop.installationAvailable
          ? shop.installationCharge
          : 0;

      final double totalAmount = subtotal + deliveryCharge + installationCharge;

      final DateTime now = DateTime.now();

      createdOrder = ShopWiseOrder(
        id: orderRef.id,
        enquiryId: normalizedId,
        productId: product.id,
        shopId: shop.id,
        ownerId: shop.ownerId,
        customerId: user.uid,
        productName: product.name,
        quantity: quantity,
        unitPrice: product.price,
        subtotal: subtotal,
        deliveryCharge: deliveryCharge,
        installationCharge: installationCharge,
        totalAmount: totalAmount,
        status: OrderLifecycle.placed,
        createdAt: now,
        updatedAt: now,
        inventoryAdjusted: true,
      );

      /*
       * Order and enquiry are committed atomically.
       */
      transaction.set(orderRef, createdOrder.toMap());

      transaction.update(enquiryRef, {
        'orderId': orderRef.id,
        'purchaseStatus': 'purchased',
        'purchasedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(productRef, {
        'stock': product.stock - quantity,
        'lastStockOrderId': orderRef.id,
      });
    });

    return createdOrder;
  }

  Future<ShopWiseOrder> createDirectOrder({
    required Product product,
    required Shop shop,
    required int quantity,
    required String purchaseMode,
    required String fulfillmentType,
    required String requestId,
    required String expectedCustomerId,
  }) async {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('Please sign in to place an order.');
    }
    if (user.uid != expectedCustomerId) {
      throw Exception('Your account changed. Reopen checkout to continue.');
    }

    if (product.id.isEmpty || shop.id.isEmpty || shop.ownerId.isEmpty) {
      throw Exception('Product or shop information is unavailable.');
    }

    final idempotencyKey = requestId.trim();
    if (idempotencyKey.isEmpty) {
      throw Exception('Order request information is unavailable. Try again.');
    }

    if (!product.isAvailable || product.stock <= 0) {
      throw Exception('This product is currently unavailable.');
    }

    if (quantity < 1) {
      throw Exception('Quantity must be at least 1.');
    }
    if (quantity > product.stock) {
      throw Exception(
        'Only ${product.stock} unit${product.stock == 1 ? '' : 's'} currently available.',
      );
    }

    final mode = purchaseMode.trim().toLowerCase();
    final fulfillment = fulfillmentType.trim().toLowerCase();

    if (mode != 'online' && mode != 'offline') {
      throw Exception('Invalid purchase mode.');
    }

    if (fulfillment != 'delivery' && fulfillment != 'pickup') {
      throw Exception('Invalid fulfillment type.');
    }

    if (mode == 'online' && fulfillment != 'delivery') {
      throw Exception('Online purchase requires delivery.');
    }

    if (mode == 'offline' && fulfillment != 'pickup') {
      throw Exception('Offline purchase requires shop pickup.');
    }

    if (fulfillment == 'delivery' && !shop.deliveryAvailable) {
      throw Exception('Delivery is not available from this shop.');
    }

    final orderRef = _orders.doc(idempotencyKey);

    return _firestore.runTransaction<ShopWiseOrder>((transaction) async {
      if (_auth.currentUser?.uid != expectedCustomerId) {
        throw Exception('Your account changed. Reopen checkout to continue.');
      }
      final existingSnapshot = await transaction.get(orderRef);
      if (existingSnapshot.exists && existingSnapshot.data() != null) {
        final existingData = Map<String, dynamic>.from(existingSnapshot.data()!)
          ..['id'] = existingSnapshot.id;
        final existing = ShopWiseOrder.fromMap(existingData);

        if (existing.customerId == user.uid &&
            existing.productId == product.id &&
            existing.shopId == shop.id &&
            existing.quantity == quantity &&
            existing.purchaseMode == mode &&
            existing.fulfillmentType == fulfillment) {
          return existing;
        }
        throw Exception('This order request has already been used.');
      }

      final productRef = _products.doc(product.id);
      final shopRef = _shops.doc(shop.id);
      final productSnapshot = await transaction.get(productRef);
      final shopSnapshot = await transaction.get(shopRef);

      if (!productSnapshot.exists || productSnapshot.data() == null) {
        throw Exception('The product is no longer available.');
      }
      if (!shopSnapshot.exists || shopSnapshot.data() == null) {
        throw Exception('The shop is no longer available.');
      }

      final productData = Map<String, dynamic>.from(productSnapshot.data()!)
        ..['id'] = productSnapshot.id;
      final shopData = Map<String, dynamic>.from(shopSnapshot.data()!)
        ..['id'] = shopSnapshot.id;
      final latestProduct = Product.fromMap(productData);
      final latestShop = Shop.fromMap(shopData);

      if (!latestProduct.isAvailable || latestProduct.stock <= 0) {
        throw Exception('This product is currently unavailable.');
      }
      if (quantity > latestProduct.stock) {
        throw Exception(
          'Only ${latestProduct.stock} unit'
          '${latestProduct.stock == 1 ? '' : 's'} currently available.',
        );
      }
      if (latestProduct.shopId != latestShop.id ||
          latestProduct.ownerId != latestShop.ownerId ||
          latestShop.ownerId != shop.ownerId) {
        throw Exception(
          'Shop or product information has changed. Refresh and retry.',
        );
      }
      if (fulfillment == 'delivery' && !latestShop.deliveryAvailable) {
        throw Exception('Delivery is no longer available from this shop.');
      }
      if (fulfillment == 'delivery' &&
          latestShop.deliveryAvailable &&
          !latestShop.deliveryChargeIsKnown) {
        throw Exception(
          'The delivery charge is unavailable. Please contact the shop.',
        );
      }
      if (fulfillment == 'delivery' &&
          latestShop.installationAvailable &&
          !latestShop.installationChargeIsKnown) {
        throw Exception(
          'The installation charge is unavailable. Please contact the shop.',
        );
      }

      if (_auth.currentUser?.uid != expectedCustomerId) {
        throw Exception('Your account changed. Reopen checkout to continue.');
      }

      final subtotal = latestProduct.price * quantity;
      final delivery = fulfillment == 'delivery'
          ? latestShop.deliveryCharge
          : 0.0;
      final installation =
          fulfillment == 'delivery' && latestShop.installationAvailable
          ? latestShop.installationCharge
          : 0.0;
      final now = DateTime.now();
      final order = ShopWiseOrder(
        id: orderRef.id,
        enquiryId: '',
        purchaseMode: mode,
        fulfillmentType: fulfillment,
        productId: latestProduct.id,
        shopId: latestShop.id,
        ownerId: latestShop.ownerId,
        customerId: user.uid,
        productName: latestProduct.name,
        quantity: quantity,
        unitPrice: latestProduct.price,
        subtotal: subtotal,
        deliveryCharge: delivery,
        installationCharge: installation,
        totalAmount: subtotal + delivery + installation,
        status: OrderLifecycle.placed,
        createdAt: now,
        updatedAt: now,
        inventoryAdjusted: true,
      );

      transaction.set(orderRef, order.toMap());
      transaction.update(productRef, {
        'stock': latestProduct.stock - quantity,
        'lastStockOrderId': orderRef.id,
      });
      return order;
    });
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to update the order.');
    }

    final String id = orderId.trim();
    final String normalizedStatus = status.trim().toLowerCase();

    if (id.isEmpty) {
      throw Exception('Invalid order.');
    }

    if (!OrderLifecycle.allStatuses.contains(normalizedStatus) ||
        normalizedStatus == OrderLifecycle.placed) {
      throw Exception('Invalid order status.');
    }

    final DocumentReference<Map<String, dynamic>> orderRef = _orders.doc(id);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(orderRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('Order no longer exists.');
      }

      final data = snapshot.data()!;

      final String ownerId = (data['ownerId'] as String? ?? '').trim();

      final String currentStatus = (data['status'] as String? ?? '')
          .trim()
          .toLowerCase();

      if (ownerId != user.uid) {
        throw Exception('You are not authorized to update this order.');
      }

      if (!OrderLifecycle.canTransition(currentStatus, normalizedStatus)) {
        throw Exception(
          'Cannot change order status from '
          '${currentStatus.isEmpty ? 'unknown' : currentStatus} '
          'to $normalizedStatus.',
        );
      }

      final inventoryAdjusted = data['inventoryAdjusted'] == true;
      if (normalizedStatus == OrderLifecycle.cancelled && inventoryAdjusted) {
        final rawQuantity = data['quantity'];
        final quantity = rawQuantity is int ? rawQuantity : 0;
        final productId = (data['productId'] as String? ?? '').trim();
        if (quantity < 1 || productId.isEmpty) {
          throw Exception(
            'This order has invalid stock information and cannot be cancelled safely.',
          );
        }

        final productRef = _products.doc(productId);
        final productSnapshot = await transaction.get(productRef);
        if (!productSnapshot.exists || productSnapshot.data() == null) {
          throw Exception(
            'The product for this reserved order no longer exists; '
            'cancellation was not applied. Please contact support.',
          );
        }

        final rawStock = productSnapshot.data()!['stock'];
        final currentStock = rawStock is int ? rawStock : null;
        if (currentStock == null || currentStock < 0) {
          throw Exception(
            'Product stock is invalid; cancellation was not applied.',
          );
        }
        transaction.update(productRef, {
          'stock': currentStock + quantity,
          'lastStockOrderId': id,
        });
      }

      transaction.update(orderRef, {
        'status': normalizedStatus,
        if (normalizedStatus == OrderLifecycle.cancelled && inventoryAdjusted)
          'inventoryAdjusted': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<bool> hasOrderForEnquiry(String enquiryId) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final String id = enquiryId.trim();

    if (id.isEmpty) {
      return false;
    }

    final snapshot = await _enquiries.doc(id).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return false;
    }

    final data = snapshot.data()!;

    if (data['customerId'] != user.uid) {
      return false;
    }

    final String orderId = (data['orderId'] as String? ?? '').trim();

    return orderId.isNotEmpty;
  }

  Future<ShopWiseOrder?> getOrderById(String orderId) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final String id = orderId.trim();

    if (id.isEmpty) {
      return null;
    }

    final snapshot = await _orders.doc(id).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    final data = snapshot.data()!;

    final String customerId = (data['customerId'] as String? ?? '').trim();

    final String ownerId = (data['ownerId'] as String? ?? '').trim();

    if (customerId != user.uid && ownerId != user.uid) {
      throw Exception('You are not authorized to view this order.');
    }

    final Map<String, dynamic> normalized = Map<String, dynamic>.from(data);

    normalized['id'] = snapshot.id;

    return ShopWiseOrder.fromMap(normalized);
  }

  Stream<List<ShopWiseOrder>> watchShopOwnerOrders() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream.value(const <ShopWiseOrder>[]);
    }

    return _orders.where('ownerId', isEqualTo: user.uid).snapshots().map((
      snapshot,
    ) {
      final orders = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());

        data['id'] = doc.id;

        return ShopWiseOrder.fromMap(data);
      }).toList();

      orders.sort((a, b) {
        final DateTime aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        final DateTime bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return orders;
    });
  }

  Stream<List<ShopWiseOrder>> watchMyOrders() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream.value(const <ShopWiseOrder>[]);
    }

    return _orders.where('customerId', isEqualTo: user.uid).snapshots().map((
      snapshot,
    ) {
      final orders = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());

        data['id'] = doc.id;

        return ShopWiseOrder.fromMap(data);
      }).toList();

      orders.sort((a, b) {
        final DateTime aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        final DateTime bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return orders;
    });
  }
}

class DirectOrderRequest {
  const DirectOrderRequest({required this.customerId, required this.requestId});

  final String customerId;
  final String requestId;
}
