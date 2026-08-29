import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/product.dart';
import '../models/shop.dart';
import 'shop_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final ShopService _shopService = ShopService();

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
    final Shop? shop = await _shopService.getMyShop();

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

  /// Watch all products for customers in real time.
  Stream<List<Product>> watchAllProducts() {
    return _products.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) {
        final data = doc.data();

        // Always use the Firestore document ID.
        data['id'] = doc.id;

        return Product.fromMap(data);
      }).toList();
    });
  }

  /// Watch only the products represented by the supplied document IDs.
  ///
  /// This avoids downloading the entire products collection for Wishlist
  /// and Compare screens. Firestore `whereIn` supports up to 30 IDs,
  /// which is comfortably above ShopWise's current Compare limit of 4.
  Stream<List<Product>> watchProductsByIds(Set<String> productIds) {
    final ids = productIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    if (ids.isEmpty) {
      return Stream.value(const <Product>[]);
    }

    return _products.where(FieldPath.documentId, whereIn: ids).snapshots().map((
      snapshot,
    ) {
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromMap(data);
      }).toList();

      final order = <String, int>{
        for (var index = 0; index < ids.length; index++) ids[index]: index,
      };

      products.sort(
        (a, b) =>
            (order[a.id] ?? ids.length).compareTo(order[b.id] ?? ids.length),
      );

      return products;
    });
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

    final String shopId = data['shopId'] as String? ?? '';

    if (shopId.isEmpty) {
      throw Exception('Product is not linked to a shop.');
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

    await doc.delete();
  }
}
