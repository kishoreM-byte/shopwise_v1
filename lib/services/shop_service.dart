import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/shop.dart';

class ShopService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _shops {
    return _firestore.collection('shops');
  }

  CollectionReference<Map<String, dynamic>> get _users {
    return _firestore.collection('users');
  }

  /// Creates or updates the current owner's single shop.
  ///
  /// The shop ID is taken from users/{uid}.shopId when available.
  /// This prevents duplicate shop documents.
  Future<String> createShop(Shop shop) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final DocumentReference<Map<String, dynamic>> userDocument = _users.doc(
      user.uid,
    );

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await userDocument.get();

    final String? existingShopId = userSnapshot.data()?['shopId'] as String?;

    final String shopId =
        existingShopId != null && existingShopId.trim().isNotEmpty
        ? existingShopId
        : _shops.doc().id;

    final DocumentReference<Map<String, dynamic>> shopDocument = _shops.doc(
      shopId,
    );

    final DateTime now = DateTime.now();

    final Shop shopToSave = shop.copyWith(
      id: shopId,
      ownerId: user.uid,
      createdAt: shop.createdAt ?? now,
      updatedAt: now,
    );

    await shopDocument.set(shopToSave.toMap(), SetOptions(merge: true));

    // Keep users/{uid}.shopId synchronized.
    await userDocument.set({
      'uid': user.uid,
      'shopId': shopId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return shopId;
  }

  /// Gets the current owner's exact shop using users/{uid}.shopId.
  Future<Shop?> getMyShop() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot = await _users
        .doc(user.uid)
        .get();

    final String? shopId = userSnapshot.data()?['shopId'] as String?;

    if (shopId != null && shopId.trim().isNotEmpty) {
      final Shop? shop = await getShopById(shopId);

      if (shop != null) {
        return shop;
      }
    }

    // Fallback for older data where users.shopId was not stored.
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _shops
        .where('ownerId', isEqualTo: user.uid)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final document = snapshot.docs.first;
    final data = document.data();

    data['id'] = document.id;

    final Shop shop = Shop.fromMap(data);

    // Repair users/{uid}.shopId automatically.
    await _users.doc(user.uid).set({
      'shopId': document.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return shop;
  }

  /// Watches all shops for customer discovery features.
  Stream<List<Shop>> watchAllShops() {
    return _shops.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Shop.fromMap(data);
      }).toList();
    });
  }

  /// Gets a shop by its Firestore document ID.
  Future<Shop?> getShopById(String shopId) async {
    final String normalizedShopId = shopId.trim();

    if (normalizedShopId.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> document = await _shops
        .doc(normalizedShopId)
        .get();

    if (!document.exists || document.data() == null) {
      return null;
    }

    final data = document.data()!;
    data['id'] = document.id;

    return Shop.fromMap(data);
  }

  /// Gets a shop using its owner ID.
  ///
  /// Kept as a fallback for older products/data.
  Future<Shop?> getShopByOwnerId(String ownerId) async {
    final String normalizedOwnerId = ownerId.trim();

    if (normalizedOwnerId.isEmpty) {
      return null;
    }

    final QuerySnapshot<Map<String, dynamic>> snapshot = await _shops
        .where('ownerId', isEqualTo: normalizedOwnerId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final document = snapshot.docs.first;
    final data = document.data();

    data['id'] = document.id;

    return Shop.fromMap(data);
  }

  /// Updates the current shop owner's shop.
  Future<void> updateShop(Shop shop) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    if (shop.id.trim().isEmpty) {
      throw Exception('Invalid shop ID.');
    }

    final Shop updatedShop = shop.copyWith(
      id: shop.id,
      ownerId: user.uid,
      updatedAt: DateTime.now(),
    );

    await _shops.doc(shop.id).set(updatedShop.toMap(), SetOptions(merge: true));

    // Keep users/{uid}.shopId synchronized.
    await _users.doc(user.uid).set({
      'shopId': shop.id,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Watches the current owner's shop in real time.
  Stream<Shop?> watchMyShop() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream.value(null);
    }

    return _users.doc(user.uid).snapshots().asyncMap((userSnapshot) async {
      final String? shopId = userSnapshot.data()?['shopId'] as String?;

      if (shopId == null || shopId.trim().isEmpty) {
        return null;
      }

      return getShopById(shopId);
    });
  }

  /// Deletes the current owner's shop.
  Future<void> deleteShop(String shopId) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final String normalizedShopId = shopId.trim();

    if (normalizedShopId.isEmpty) {
      throw Exception('Invalid shop ID.');
    }

    await _shops.doc(normalizedShopId).delete();

    final DocumentReference<Map<String, dynamic>> userDocument = _users.doc(
      user.uid,
    );

    final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
        await userDocument.get();

    if (userSnapshot.data()?['shopId'] == normalizedShopId) {
      await userDocument.set({
        'shopId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
