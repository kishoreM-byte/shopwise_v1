import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String message;
  final String? productId;
  final String? shopId;
  final String? enquiryId;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.productId,
    this.shopId,
    this.enquiryId,
    required this.isRead,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'productId': productId,
      'shopId': shopId,
      'enquiryId': enquiryId,
      'isRead': isRead,
      'createdAt': createdAt,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      productId: map['productId'] as String?,
      shopId: map['shopId'] as String?,
      enquiryId: map['enquiryId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _dateFromMap(map['createdAt']),
    );
  }

  static DateTime? _dateFromMap(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
