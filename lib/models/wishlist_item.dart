import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistItem {
  final String productId;
  final String shopId;
  final String userId;
  final DateTime? savedAt;

  const WishlistItem({
    required this.productId,
    required this.shopId,
    required this.userId,
    this.savedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'shopId': shopId,
      'userId': userId,
      'savedAt': savedAt,
    };
  }

  factory WishlistItem.fromMap(Map<String, dynamic> map) {
    final value = map['savedAt'];

    return WishlistItem(
      productId: map['productId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      savedAt: value is Timestamp ? value.toDate() : null,
    );
  }
}
