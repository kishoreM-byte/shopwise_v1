import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String shopId;
  final String ownerId;

  final String name;
  final String category;
  final String description;

  final double price;
  final double? originalPrice;

  final int stock;
  final bool isAvailable;

  final List<String> imageUrls;

  final double rating;
  final int reviewCount;

  final bool hasOffer;
  final String? offerText;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.shopId,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    this.originalPrice,
    required this.stock,
    required this.isAvailable,
    required this.imageUrls,
    required this.rating,
    required this.reviewCount,
    required this.hasOffer,
    this.offerText,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'ownerId': ownerId,
      'name': name,
      'category': category,
      'description': description,
      'price': price,
      'originalPrice': originalPrice,
      'stock': stock,
      'isAvailable': isAvailable,
      'imageUrls': imageUrls,
      'rating': rating,
      'reviewCount': reviewCount,
      'hasOffer': hasOffer,
      'offerText': offerText,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as String? ?? '',
      shopId: map['shopId'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (map['originalPrice'] as num?)?.toDouble(),
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      isAvailable: map['isAvailable'] as bool? ?? true,
      imageUrls: List<String>.from(map['imageUrls'] ?? const []),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      hasOffer: map['hasOffer'] as bool? ?? false,
      offerText: map['offerText'] as String?,
      createdAt: _dateFromMap(map['createdAt']),
      updatedAt: _dateFromMap(map['updatedAt']),
    );
  }

  static DateTime? _dateFromMap(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  Product copyWith({
    String? id,
    String? shopId,
    String? ownerId,
    String? name,
    String? category,
    String? description,
    double? price,
    double? originalPrice,
    int? stock,
    bool? isAvailable,
    List<String>? imageUrls,
    double? rating,
    int? reviewCount,
    bool? hasOffer,
    String? offerText,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      stock: stock ?? this.stock,
      isAvailable: isAvailable ?? this.isAvailable,
      imageUrls: imageUrls ?? this.imageUrls,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      hasOffer: hasOffer ?? this.hasOffer,
      offerText: offerText ?? this.offerText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
