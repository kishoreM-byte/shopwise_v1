import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _reviews(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews');
  }

  DocumentReference<Map<String, dynamic>> _product(String productId) {
    return _firestore.collection('products').doc(productId);
  }

  Stream<List<ProductReview>> watchReviews(String productId) {
    return _reviews(productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return ProductReview.fromMap(data);
          }).toList(),
        );
  }

  Future<void> addReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to review this product.');
    }

    final String trimmedProductId = productId.trim();
    final String trimmedComment = comment.trim();

    if (trimmedProductId.isEmpty) {
      throw Exception('Invalid product.');
    }

    if (rating < 1 || rating > 5) {
      throw Exception('Please select a rating between 1 and 5.');
    }

    if (trimmedComment.length < 3) {
      throw Exception('Please write a little more about your experience.');
    }

    final productRef = _product(trimmedProductId);
    final reviewRef = _reviews(trimmedProductId).doc(user.uid);

    final productSnapshot = await productRef.get();

    if (!productSnapshot.exists) {
      throw Exception('Product not found.');
    }

    final existingReview = await reviewRef.get();

    await reviewRef.set({
      'id': user.uid,
      'productId': trimmedProductId,
      'userId': user.uid,
      'userName': user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'ShopWise User',
      'rating': rating,
      'comment': trimmedComment,
      'createdAt':
          existingReview.exists && existingReview.data()?['createdAt'] != null
          ? existingReview.data()!['createdAt']
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteReview(String productId) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to manage your review.');
    }

    final String id = productId.trim();
    if (id.isEmpty) {
      throw Exception('Invalid product.');
    }

    final productRef = _product(id);
    final reviewRef = _reviews(id).doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);
      final reviewSnapshot = await transaction.get(reviewRef);

      if (!reviewSnapshot.exists) return;

      if (!productSnapshot.exists || productSnapshot.data() == null) {
        throw Exception('Product not found.');
      }

      final product = productSnapshot.data()!;
      final review = reviewSnapshot.data()!;

      final int oldCount = (product['reviewCount'] as num?)?.toInt() ?? 0;
      final double oldAverage = (product['rating'] as num?)?.toDouble() ?? 0;
      final double removedRating = (review['rating'] as num?)?.toDouble() ?? 0;

      final int newCount = oldCount > 0 ? oldCount - 1 : 0;
      final double newAverage = newCount == 0
          ? 0
          : ((oldAverage * oldCount - removedRating) / newCount * 10).round() /
                10;

      transaction.delete(reviewRef);
      transaction.update(productRef, {
        'rating': newAverage,
        'reviewCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<ProductReview?> getMyReview(String productId) async {
    final User? user = _auth.currentUser;

    if (user == null) return null;

    final String trimmedProductId = productId.trim();

    if (trimmedProductId.isEmpty) return null;

    final doc = await _reviews(trimmedProductId).doc(user.uid).get();

    if (!doc.exists || doc.data() == null) return null;

    final data = doc.data()!;
    data['id'] = doc.id;

    return ProductReview.fromMap(data);
  }
}
