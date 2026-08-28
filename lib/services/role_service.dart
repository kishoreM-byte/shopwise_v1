import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  CollectionReference<Map<String, dynamic>> get _shopsCollection {
    return _firestore.collection('shops');
  }

  /// Creates or updates the user's basic profile.
  ///
  /// A shop owner has exactly one shop.
  /// The shop document ID is stored in users/{uid}.shopId.
  Future<void> createUserProfile({required String role}) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final DocumentReference<Map<String, dynamic>> userDocument =
        _usersCollection.doc(user.uid);

    final Map<String, dynamic> userData = {
      'uid': user.uid,
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (role == 'shop_owner') {
      final DocumentSnapshot<Map<String, dynamic>> existingUser =
          await userDocument.get();

      final String? existingShopId =
          existingUser.data()?['shopId'] as String?;

      if (existingShopId != null && existingShopId.trim().isNotEmpty) {
        // Reuse the existing shop. Never create a second shop.
        userData['shopId'] = existingShopId;
      } else {
        final DocumentReference<Map<String, dynamic>> shopDocument =
            _shopsCollection.doc();

        await shopDocument.set({
          'id': shopDocument.id,
          'ownerId': user.uid,
          'name': '',
          'category': 'Furniture',
          'description': '',
          'address': '',
          'phone': user.phoneNumber ?? '',
          'imageUrl': null,
          'rating': 0.0,
          'reviewCount': 0,
          'isOpen': true,
          'deliveryAvailable': false,
          'deliveryCharge': 0.0,
          'installationAvailable': false,
          'installationCharge': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        userData['shopId'] = shopDocument.id;
      }
    }

    await userDocument.set(
      userData,
      SetOptions(merge: true),
    );
  }

  /// Saves only the selected role.
  ///
  /// If the user becomes a shop owner, exactly one shop is maintained.
  Future<void> saveRole(String role) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No authenticated user found.');
    }

    final Map<String, dynamic> data = {
      'uid': user.uid,
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (role == 'shop_owner') {
      final DocumentReference<Map<String, dynamic>> userDocument =
          _usersCollection.doc(user.uid);

      final DocumentSnapshot<Map<String, dynamic>> existingUser =
          await userDocument.get();

      final String? existingShopId =
          existingUser.data()?['shopId'] as String?;

      if (existingShopId != null && existingShopId.trim().isNotEmpty) {
        // Reuse the existing shop.
        data['shopId'] = existingShopId;
      } else {
        final DocumentReference<Map<String, dynamic>> shopDocument =
            _shopsCollection.doc();

        await shopDocument.set({
          'id': shopDocument.id,
          'ownerId': user.uid,
          'name': '',
          'category': 'Furniture',
          'description': '',
          'address': '',
          'phone': user.phoneNumber ?? '',
          'imageUrl': null,
          'rating': 0.0,
          'reviewCount': 0,
          'isOpen': true,
          'deliveryAvailable': false,
          'deliveryCharge': 0.0,
          'installationAvailable': false,
          'installationCharge': 0.0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        data['shopId'] = shopDocument.id;
      }
    }

    await _usersCollection.doc(user.uid).set(
      data,
      SetOptions(merge: true),
    );
  }

  /// Gets the current user's role.
  Future<String?> getCurrentUserRole() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> document =
        await _usersCollection.doc(user.uid).get();

    if (!document.exists) {
      return null;
    }

    return document.data()?['role'] as String?;
  }

  /// Gets the current user's shop ID.
  Future<String?> getCurrentShopId() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> document =
        await _usersCollection.doc(user.uid).get();

    if (!document.exists) {
      return null;
    }

    final String? shopId = document.data()?['shopId'] as String?;

    if (shopId == null || shopId.trim().isEmpty) {
      return null;
    }

    return shopId;
  }

  /// Checks whether a role has already been selected.
  Future<bool> hasSelectedRole() async {
    final String? role = await getCurrentUserRole();

    return role == 'customer' || role == 'shop_owner';
  }

  /// Returns the complete current user profile.
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> document =
        await _usersCollection.doc(user.uid).get();

    return document.data();
  }
}
