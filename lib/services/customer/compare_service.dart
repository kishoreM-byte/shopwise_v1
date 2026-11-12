import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/product.dart';

class CompareService {
  CompareService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>? get _compare {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore.collection('users').doc(user.uid).collection('compare');
  }

  Stream<Set<String>> watchCompareIds() {
    final compare = _compare;

    if (compare == null) {
      return Stream.value(<String>{});
    }

    return compare.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.id).toSet(),
    );
  }

  Future<bool> isCompared(String productId) async {
    final compare = _compare;

    if (compare == null) return false;

    final doc = await compare.doc(productId).get();
    return doc.exists;
  }

  Future<bool> toggle(String productId) async {
    final compare = _compare;

    if (compare == null) {
      throw Exception('Please sign in to compare products.');
    }

    final doc = compare.doc(productId);
    final snapshot = await doc.get();

    if (snapshot.exists) {
      await doc.delete();
      return false;
    }

    final current = await compare.limit(4).get();

    if (current.docs.length >= 4) {
      throw Exception('You can compare up to 4 products at a time.');
    }

    await doc.set({
      'productId': productId,
      'addedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  /// Adds a selected product and one compatible alternative as a
  /// comparison pair.
  ///
  /// This is used by the nearby-alternatives flow so the selected product
  /// is always present when the user starts comparing an alternative.
  Future<void> addProductPair(
    Product selectedProduct,
    Product alternative,
  ) async {
    final compare = _compare;
    if (compare == null) {
      throw Exception('Please sign in to compare products.');
    }

    final selectedCategory = selectedProduct.category.trim().toLowerCase();
    final alternativeCategory = alternative.category.trim().toLowerCase();

    if (selectedCategory != alternativeCategory) {
      throw Exception('Compare products from the same category.');
    }

    final existing = await compare.get();
    final existingIds = existing.docs.map((doc) => doc.id).toSet();

    final requiredNewIds = <String>[
      if (!existingIds.contains(selectedProduct.id)) selectedProduct.id,
      if (!existingIds.contains(alternative.id)) alternative.id,
    ];

    if (existing.docs.length + requiredNewIds.length > 4) {
      throw Exception('You can compare up to 4 products at a time.');
    }

    final existingProducts = await _getProductsByIds(existingIds);

    final allProducts = <Product>[
      ...existingProducts,
      if (!existingIds.contains(selectedProduct.id)) selectedProduct,
      if (!existingIds.contains(alternative.id)) alternative,
    ];

    final categories = allProducts
        .map((product) => product.category.trim().toLowerCase())
        .toSet();

    if (categories.length > 1) {
      throw Exception('Compare products from the same category.');
    }

    final batch = _firestore.batch();

    for (final product in [
      if (!existingIds.contains(selectedProduct.id)) selectedProduct,
      if (!existingIds.contains(alternative.id)) alternative,
    ]) {
      batch.set(compare.doc(product.id), {
        'productId': product.id,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<bool> toggleSameProduct(Product product) async {
    final compare = _compare;
    if (compare == null) {
      throw Exception('Please sign in to compare products.');
    }

    final existing = await compare.get();

    if (existing.docs.any((doc) => doc.id == product.id)) {
      await compare.doc(product.id).delete();
      return false;
    }

    if (existing.docs.length >= 4) {
      throw Exception('You can compare up to 4 products at a time.');
    }

    final ids = existing.docs.map((doc) => doc.id).toSet();
    final products = await _getProductsByIds(ids);

    String categoryKey(Product p) {
      return p.category.trim().toLowerCase();
    }

    if (products.isNotEmpty &&
        products.any((p) => categoryKey(p) != categoryKey(product))) {
      throw Exception('Compare products from the same category.');
    }

    await compare.doc(product.id).set({
      'productId': product.id,
      'addedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }

  Future<void> remove(String productId) async {
    await _compare?.doc(productId).delete();
  }

  Future<List<Product>> _getProductsByIds(Set<String> ids) async {
    if (ids.isEmpty) return const <Product>[];
    final snapshot = await _firestore
        .collection('products')
        .where(FieldPath.documentId, whereIn: ids.toList())
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Product.fromMap(<String, dynamic>{'id': doc.id, ...data});
    }).toList();
  }

  Future<void> clear() async {
    final compare = _compare;

    if (compare == null) return;

    final snapshot = await compare.get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }
}
