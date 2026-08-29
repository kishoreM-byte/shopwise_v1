import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  WishlistService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>? get _wishlist {
    final user = _auth.currentUser;
    if (user == null) return null;

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('wishlist');
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

    final doc = await wishlist.doc(productId).get();
    return doc.exists;
  }

  Future<bool> toggle(String productId) async {
    final wishlist = _wishlist;

    if (wishlist == null) {
      throw Exception('Please sign in to save products.');
    }

    final doc = wishlist.doc(productId);
    final snapshot = await doc.get();

    if (snapshot.exists) {
      await doc.delete();
      return false;
    }

    await doc.set({
      'productId': productId,
      'savedAt': FieldValue.serverTimestamp(),
    });

    return true;
  }
}
