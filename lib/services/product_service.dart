import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

import '../models/product.dart';
import '../models/shop.dart';
import 'shop_service.dart';

class ProductService {
  static const int _whereInLimit = 30;

  ProductService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    Future<Shop?> Function()? getMyShop,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _getMyShop = getMyShop ?? (() => ShopService().getMyShop());

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Future<Shop?> Function() _getMyShop;

  CollectionReference<Map<String, dynamic>> get _products {
    return _firestore.collection('products');
  }

  /// Add a new product for the currently logged-in shop owner.
  Future<String> addProduct(Product product) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    // Get the actual shop belonging to this owner.
    final Shop? shop = await _getMyShop();

    if (shop == null) {
      throw Exception(
        'No shop found for this shop owner. Please create your shop first.',
      );
    }

    final DocumentReference<Map<String, dynamic>> doc = _products.doc();

    final DateTime now = DateTime.now();

    final Product productToSave = product.copyWith(
      id: doc.id,
      shopId: shop.id,
      ownerId: user.uid,
      createdAt: now,
      updatedAt: now,
    );

    await doc.set(productToSave.toMap());

    return doc.id;
  }

  /// Get all products belonging to the current shop owner.
  Stream<List<Product>> watchMyProducts() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream.value(const <Product>[]);
    }

    return _products.where('ownerId', isEqualTo: user.uid).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => Product.fromMap(doc.data())).toList();
    });
  }

  /// Watch only visible products for customer-facing catalog screens.
  Stream<List<Product>> watchAllProducts() {
    return _products.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Always use the Firestore document ID.
        data['id'] = doc.id;

        return Product.fromMap(data);
      }).where((product) => product.isAvailable).toList();
    });
  }

  /// Watch only the products represented by the supplied document IDs.
  ///
  /// This avoids downloading the entire products collection for Wishlist
  /// and Compare screens. Firestore `whereIn` supports up to 30 IDs,
  /// which is comfortably above ShopWise's current Compare limit of 4.

  Future<List<Product>> getProductsByIds(Set<String> productIds) async {
    final ids = _normalizeProductIds(productIds);
    if (ids.isEmpty) return <Product>[];

    final chunks = _chunkIds(ids);
    final snapshots = await Future.wait(
      chunks.map(
        (chunk) => _products.where(FieldPath.documentId, whereIn: chunk).get(),
      ),
    );
    final products = snapshots
        .expand((snapshot) => snapshot.docs)
        .map((doc) => Product.fromMap(doc.data()..['id'] = doc.id))
        .toList();

    return _orderProducts(products, ids);
  }

  Stream<List<Product>> watchProductsByIds(Set<String> productIds) {
    final ids = _normalizeProductIds(productIds);

    if (ids.isEmpty) {
      return Stream.value(const <Product>[]);
    }

    final chunks = _chunkIds(ids);
    if (chunks.length == 1) return _watchProductIdChunk(chunks.single);

    return Stream<List<Product>>.multi((controller) {
      final latestByChunk = <int, List<Product>>{};
      final subscriptions = <StreamSubscription<List<Product>>>[];

      for (var index = 0; index < chunks.length; index++) {
        final chunkIndex = index;
        subscriptions.add(
          _watchProductIdChunk(chunks[index]).listen(
            (products) {
              latestByChunk[chunkIndex] = products;
              if (latestByChunk.length == chunks.length) {
                controller.add(
                  _orderProducts(
                    latestByChunk.values.expand((items) => items).toList(),
                    ids,
                  ),
                );
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              controller.addError(error, stackTrace);
            },
          ),
        );
      }

      controller.onCancel = () async {
        await Future.wait(
          subscriptions.map((subscription) => subscription.cancel()),
        );
      };
    });
  }

  Stream<List<Product>> _watchProductIdChunk(List<String> ids) {
    return _products.where(FieldPath.documentId, whereIn: ids).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();
    });
  }

  List<String> _normalizeProductIds(Set<String> productIds) => productIds
      .map((id) => id.trim())
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  List<List<String>> _chunkIds(List<String> ids) => [
    for (var start = 0; start < ids.length; start += _whereInLimit)
      ids.skip(start).take(_whereInLimit).toList(),
  ];

  List<Product> _orderProducts(List<Product> products, List<String> ids) {
    final order = <String, int>{
      for (var index = 0; index < ids.length; index++) ids[index]: index,
    };
    products.sort(
      (first, second) => (order[first.id] ?? ids.length).compareTo(
        order[second.id] ?? ids.length,
      ),
    );
    return products;
  }

  /// Get one product by its document ID.
  Future<Product?> getProduct(String productId) async {
    final DocumentSnapshot<Map<String, dynamic>> doc = await _products
        .doc(productId)
        .get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return Product.fromMap(doc.data()!);
  }

  /// Update an existing product owned by the current shop owner.
  ///
  /// Ownership fields are intentionally preserved from the existing document
  /// rather than being rewritten from client-provided data.
  Future<void> updateProduct(Product product) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final String productId = product.id.trim();

    if (productId.isEmpty) {
      throw Exception('Product ID is required to update a product.');
    }

    final DocumentReference<Map<String, dynamic>> doc = _products.doc(
      productId,
    );

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Product not found.');
    }

    final data = snapshot.data()!;

    final String ownerId = data['ownerId'] as String? ?? '';

    if (ownerId != user.uid) {
      throw Exception('You are not allowed to update this product.');
    }

    final String existingShopId = data['shopId'] as String? ?? '';

    String shopId = existingShopId.trim();

    // Repair legacy products that were created without a shopId.
    // The shop is resolved from the authenticated owner's shop record.
    if (shopId.isEmpty) {
      final Shop? ownerShop = await _getMyShop();

      if (ownerShop == null || ownerShop.id.trim().isEmpty) {
        throw Exception(
          'No shop found for this shop owner. Please complete your shop setup first.',
        );
      }

      if (ownerShop.ownerId != user.uid) {
        throw Exception('You are not allowed to use this shop.');
      }

      shopId = ownerShop.id.trim();
    }

    final updatedProduct = product.copyWith(
      id: productId,
      shopId: shopId,
      ownerId: ownerId,
      updatedAt: DateTime.now(),
    );

    await doc.update(updatedProduct.toMap());
  }

  /// Delete a product owned by the current shop owner.
  Future<void> deleteProduct(String productId) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final String normalizedProductId = productId.trim();

    if (normalizedProductId.isEmpty) {
      throw Exception('Product ID is required to delete a product.');
    }

    final DocumentReference<Map<String, dynamic>> doc = _products.doc(
      normalizedProductId,
    );

    final DocumentSnapshot<Map<String, dynamic>> snapshot = await doc.get();

    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Product not found.');
    }

    final String ownerId = snapshot.data()!['ownerId'] as String? ?? '';

    if (ownerId != user.uid) {
      throw Exception('You are not allowed to delete this product.');
    }

    await doc.update(<String, dynamic>{
      'isAvailable': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
