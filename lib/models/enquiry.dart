import 'package:cloud_firestore/cloud_firestore.dart';

class ProductEnquiry {
  final String id;
  final String productId;
  final String shopId;
  final String ownerId;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String productName;
  final double productPrice;
  final int quantity;
  final String message;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductEnquiry({
    required this.id,
    required this.productId,
    required this.shopId,
    required this.ownerId,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.productName,
    required this.productPrice,
    required this.quantity,
    required this.message,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'shopId': shopId,
      'ownerId': ownerId,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'productName': productName,
      'productPrice': productPrice,
      'quantity': quantity,
      'message': message,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory ProductEnquiry.fromMap(Map<String, dynamic> map) {
    return ProductEnquiry(
      id: map['id'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      customerId: map['customerId'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerEmail: map['customerEmail'] as String? ?? '',
      customerPhone: map['customerPhone'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      productPrice: (map['productPrice'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      createdAt: _dateFromMap(map['createdAt']),
      updatedAt: _dateFromMap(map['updatedAt']),
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
