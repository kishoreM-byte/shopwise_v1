import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> remove(String productId) async {
    await _compare?.doc(productId).delete();
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
