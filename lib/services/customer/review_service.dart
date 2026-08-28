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

    final DocumentReference<Map<String, dynamic>> productRef =
        _product(trimmedProductId);

    final DocumentReference<Map<String, dynamic>> reviewRef =
        _reviews(trimmedProductId).doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);

      if (!productSnapshot.exists) {
        throw Exception('Product not found.');
      }

      final reviewSnapshot = await transaction.get(reviewRef);

      final Map<String, dynamic> reviewData = {
        'id': user.uid,
        'productId': trimmedProductId,
        'userId': user.uid,
        'userName': user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'ShopWise User',
        'rating': rating,
        'comment': trimmedComment,
        'createdAt': reviewSnapshot.exists &&
                reviewSnapshot.data()?['createdAt'] != null
            ? reviewSnapshot.data()!['createdAt']
            : FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Read all existing reviews before the first transaction write.
      // Firestore transactions require all reads to happen before writes.
      final reviewsSnapshot = await _reviews(trimmedProductId).get();

      double totalRating = 0;
      int reviewCount = 0;

      for (final review in reviewsSnapshot.docs) {
        if (review.id == user.uid) {
          totalRating += rating;
          reviewCount++;
          continue;
        }

        final dynamic value = review.data()['rating'];

        if (value is num && value.isFinite) {
          totalRating += value.toDouble().clamp(1.0, 5.0);
          reviewCount++;
        }
      }

      if (!reviewSnapshot.exists) {
        reviewCount++;
        totalRating += rating;
      }

      transaction.set(reviewRef, reviewData);

      final double averageRating = reviewCount > 0
          ? double.parse((totalRating / reviewCount).toStringAsFixed(1))
          : 0;

      transaction.update(productRef, {
        'rating': averageRating,
        'reviewCount': reviewCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> deleteReview(String productId) async {
    final User? user = _auth.currentUser;

    if (user == null) return;

    final String trimmedProductId = productId.trim();

    if (trimmedProductId.isEmpty) {
      throw Exception('Invalid product.');
    }

    final DocumentReference<Map<String, dynamic>> productRef =
        _product(trimmedProductId);

    final DocumentReference<Map<String, dynamic>> reviewRef =
        _reviews(trimmedProductId).doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final reviewSnapshot = await transaction.get(reviewRef);

      if (!reviewSnapshot.exists) {
        return;
      }

      final reviewsSnapshot = await _reviews(trimmedProductId).get();

      double totalRating = 0;
      int reviewCount = 0;

      for (final review in reviewsSnapshot.docs) {
        if (review.id == user.uid) {
          continue;
        }

        final dynamic value = review.data()['rating'];

        if (value is num && value.isFinite) {
          totalRating += value.toDouble().clamp(1.0, 5.0);
          reviewCount++;
        }
      }

      final double averageRating = reviewCount > 0
          ? double.parse((totalRating / reviewCount).toStringAsFixed(1))
          : 0;

      transaction.delete(reviewRef);

      transaction.update(productRef, {
        'rating': averageRating,
        'reviewCount': reviewCount,
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
