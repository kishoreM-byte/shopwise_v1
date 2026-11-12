import 'package:cloud_firestore/cloud_firestore.dart';

class ShopWiseOrder {
  final String id;
  final String enquiryId;
  final String purchaseMode;
  final String fulfillmentType;
  final String productId;
  final String shopId;
  final String ownerId;
  final String customerId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final double deliveryCharge;
  final double installationCharge;
  final double totalAmount;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool hasValidPriceBreakdown;
  final bool inventoryAdjusted;

  const ShopWiseOrder({
    required this.id,
    required this.enquiryId,
    this.purchaseMode = 'enquiry',
    this.fulfillmentType = 'delivery',
    required this.productId,
    required this.shopId,
    required this.ownerId,
    required this.customerId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.deliveryCharge,
    required this.installationCharge,
    required this.totalAmount,
    required this.status,
    this.createdAt,
    this.updatedAt,
    this.hasValidPriceBreakdown = true,
    this.inventoryAdjusted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'enquiryId': enquiryId,
      'purchaseMode': purchaseMode,
      'fulfillmentType': fulfillmentType,
      'productId': productId,
      'shopId': shopId,
      'ownerId': ownerId,
      'customerId': customerId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
      'deliveryCharge': deliveryCharge,
      'installationCharge': installationCharge,
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'inventoryAdjusted': inventoryAdjusted,
    };
  }

  factory ShopWiseOrder.fromMap(Map<String, dynamic> map) {
    return ShopWiseOrder(
      id: _string(map['id']),
      enquiryId: _string(map['enquiryId']),
      purchaseMode: _string(map['purchaseMode'], fallback: 'enquiry'),
      fulfillmentType: _string(map['fulfillmentType'], fallback: 'delivery'),
      productId: _string(map['productId']),
      shopId: _string(map['shopId']),
      ownerId: _string(map['ownerId']),
      customerId: _string(map['customerId']),
      productName: _string(map['productName']),
      quantity: _int(map['quantity']),
      unitPrice: _double(map['unitPrice']),
      subtotal: _double(map['subtotal']),
      deliveryCharge: _double(map['deliveryCharge']),
      installationCharge: _double(map['installationCharge']),
      totalAmount: _double(map['totalAmount']),
      status: _string(map['status'], fallback: 'unknown'),
      createdAt: _dateFromMap(map['createdAt']),
      updatedAt: _dateFromMap(map['updatedAt']),
      hasValidPriceBreakdown: _hasValidPriceBreakdown(map),
      inventoryAdjusted: map['inventoryAdjusted'] == true,
    );
  }

  static bool _hasValidPriceBreakdown(Map<String, dynamic> map) {
    final fields = <String>[
      'quantity',
      'unitPrice',
      'subtotal',
      'deliveryCharge',
      'installationCharge',
      'totalAmount',
    ];
    if (fields.any((field) => map[field] is! num)) return false;

    final quantity = (map['quantity'] as num).toDouble();
    final unitPrice = (map['unitPrice'] as num).toDouble();
    final subtotal = (map['subtotal'] as num).toDouble();
    final delivery = (map['deliveryCharge'] as num).toDouble();
    final installation = (map['installationCharge'] as num).toDouble();
    final total = (map['totalAmount'] as num).toDouble();
    final values = [unitPrice, subtotal, delivery, installation, total];

    return quantity >= 1 &&
        quantity == quantity.roundToDouble() &&
        values.every((value) => value.isFinite && value >= 0) &&
        (subtotal - unitPrice * quantity).abs() < 0.01 &&
        (total - subtotal - delivery - installation).abs() < 0.01;
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value is String) {
      return value.trim();
    }

    return fallback;
  }

  static int _int(dynamic value) {
    if (value is num) {
      return value.toInt();
    }

    return 0;
  }

  static double _double(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return 0;
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
