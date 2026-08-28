import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/wishlist_item.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _wishlist {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist');
  }

  Future<void> saveProduct({
    required String productId,
    required String shopId,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    if (productId.trim().isEmpty) {
      throw Exception('Invalid product ID.');
    }

    final item = WishlistItem(
      productId: productId,
      shopId: shopId,
      userId: user.uid,
      savedAt: DateTime.now(),
    );

    await _wishlist.doc(productId).set(
      item.toMap(),
      SetOptions(merge: true),
    );
  }

  Future<void> removeProduct(String productId) async {
    await _wishlist.doc(productId).delete();
  }

  Future<bool> isSaved(String productId) async {
    final document = await _wishlist.doc(productId).get();
    return document.exists;
  }

  Stream<List<WishlistItem>> watchWishlist() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(const <WishlistItem>[]);
    }

    return _wishlist.orderBy('savedAt', descending: true).snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map((doc) => WishlistItem.fromMap(doc.data()))
            .toList();
      },
    );
  }
}
