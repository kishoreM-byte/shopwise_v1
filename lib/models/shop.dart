import 'package:cloud_firestore/cloud_firestore.dart';

class Shop {
  final String id;
  final String ownerId;

  final String name;
  final String category;
  final String description;
  final String address;
  final String phone;
  final String? imageUrl;

  // Map location
  final double? latitude;
  final double? longitude;

  final double rating;
  final int reviewCount;
  final bool isOpen;

  // Delivery settings
  final bool deliveryAvailable;
  final double deliveryCharge;
  final bool deliveryChargeIsKnown;

  // Installation settings
  final bool installationAvailable;
  final double installationCharge;
  final bool installationChargeIsKnown;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Shop({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    required this.description,
    required this.address,
    required this.phone,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.rating,
    required this.reviewCount,
    required this.isOpen,
    this.deliveryAvailable = false,
    this.deliveryCharge = 0,
    this.deliveryChargeIsKnown = true,
    this.installationAvailable = false,
    this.installationCharge = 0,
    this.installationChargeIsKnown = true,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerId': ownerId,
      'name': name,
      'category': category,
      'description': description,
      'address': address,
      'phone': phone,
      'imageUrl': imageUrl,

      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'reviewCount': reviewCount,
      'isOpen': isOpen,

      'deliveryAvailable': deliveryAvailable,
      'deliveryCharge': deliveryCharge,

      'installationAvailable': installationAvailable,
      'installationCharge': installationCharge,

      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,

      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      isOpen: map['isOpen'] as bool? ?? true,

      deliveryAvailable: map['deliveryAvailable'] as bool? ?? false,
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0,
      deliveryChargeIsKnown: _isKnownCharge(map['deliveryCharge']),

      installationAvailable: map['installationAvailable'] as bool? ?? false,
      installationCharge: (map['installationCharge'] as num?)?.toDouble() ?? 0,
      installationChargeIsKnown: _isKnownCharge(map['installationCharge']),

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

  static bool _isKnownCharge(dynamic value) =>
      value is num && value.isFinite && value >= 0;

  Shop copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? category,
    String? description,
    String? address,
    String? phone,
    String? imageUrl,
    double? latitude,
    double? longitude,
    double? rating,
    int? reviewCount,
    bool? isOpen,
    bool? deliveryAvailable,
    double? deliveryCharge,
    bool? deliveryChargeIsKnown,
    bool? installationAvailable,
    double? installationCharge,
    bool? installationChargeIsKnown,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shop(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isOpen: isOpen ?? this.isOpen,

      deliveryAvailable: deliveryAvailable ?? this.deliveryAvailable,
      deliveryCharge: deliveryCharge ?? this.deliveryCharge,
      deliveryChargeIsKnown:
          deliveryChargeIsKnown ?? this.deliveryChargeIsKnown,

      installationAvailable:
          installationAvailable ?? this.installationAvailable,
      installationCharge: installationCharge ?? this.installationCharge,
      installationChargeIsKnown:
          installationChargeIsKnown ?? this.installationChargeIsKnown,

      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
