import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  WishlistService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>? get _wishlist {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore.collection('users').doc(user.uid).collection('wishlist');
  }

  Stream<Set<String>> watchWishlistIds() {
    final wishlist = _wishlist;

    if (wishlist == null) {
      return Stream.value(<String>{});
    }

    return wishlist.snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => doc.id).toSet(),
    );
  }

  Future<bool> isSaved(String productId) async {
    final wishlist = _wishlist;

    if (wishlist == null) return false;

    final normalizedId = productId.trim();
    if (normalizedId.isEmpty) return false;

    final doc = await wishlist.doc(normalizedId).get();
    return doc.exists;
  }

  Future<bool> toggle(String productId) async {
    final wishlist = _wishlist;

    if (wishlist == null) {
      throw Exception('Please sign in to save products.');
    }

    final normalizedId = productId.trim();
    if (normalizedId.isEmpty) {
      throw ArgumentError.value(productId, 'productId', 'Cannot be empty.');
    }

    final doc = wishlist.doc(normalizedId);

    return _firestore.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(doc);

      if (snapshot.exists) {
        transaction.delete(doc);
        return false;
      }

      transaction.set(doc, {
        'productId': normalizedId,
        'savedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  /// Removes a saved item without risking a re-add if the record was already
  /// removed by another screen or device.
  Future<void> remove(String productId) async {
    final wishlist = _wishlist;

    if (wishlist == null) {
      throw Exception('Please sign in to update your wishlist.');
    }

    final normalizedId = productId.trim();
    if (normalizedId.isEmpty) return;

    await wishlist.doc(normalizedId).delete();
  }
}
