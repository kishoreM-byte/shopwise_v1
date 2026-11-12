import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/enquiry.dart';

class EnquiryService {
  EnquiryService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Set<String> _pendingEnquiryDecisions = <String>{};

  CollectionReference<Map<String, dynamic>> get _enquiries {
    return _firestore.collection('enquiries');
  }

  Future<String> createEnquiry(ProductEnquiry enquiry) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to send an enquiry.');
    }

    final DocumentReference<Map<String, dynamic>> document = _enquiries.doc();

    final DateTime now = DateTime.now();

    final ProductEnquiry enquiryToSave = ProductEnquiry(
      id: document.id,
      productId: enquiry.productId,
      shopId: enquiry.shopId,
      ownerId: enquiry.ownerId,
      customerId: user.uid,
      customerName: user.displayName ?? enquiry.customerName,
      customerEmail: user.email ?? enquiry.customerEmail,
      customerPhone: enquiry.customerPhone.trim(),
      productName: enquiry.productName,
      productPrice: enquiry.productPrice,
      quantity: enquiry.quantity,
      message: enquiry.message.trim(),
      status: 'pending',
      createdAt: now,
      updatedAt: now,
    );

    await document.set(enquiryToSave.toMap());

    return document.id;
  }

  Stream<List<ProductEnquiry>> watchMyEnquiries() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream.value(const <ProductEnquiry>[]);
    }

    return _enquiries.where('customerId', isEqualTo: user.uid).snapshots().map((
      snapshot,
    ) {
      final enquiries = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductEnquiry.fromMap(data);
      }).toList();

      enquiries.sort((a, b) {
        final DateTime aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return enquiries;
    });
  }

  Future<void> updateEnquiryStatus(String enquiryId, String status) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to update an enquiry.');
    }

    final String normalizedStatus = status.trim().toLowerCase();

    if (normalizedStatus != 'accepted' && normalizedStatus != 'rejected') {
      throw Exception('Invalid enquiry status.');
    }

    final String normalizedEnquiryId = enquiryId.trim();

    if (normalizedEnquiryId.isEmpty) {
      throw Exception('Invalid enquiry.');
    }

    if (!_pendingEnquiryDecisions.add(normalizedEnquiryId)) {
      throw Exception('This enquiry has already been processed.');
    }

    final DocumentReference<Map<String, dynamic>> enquiryRef = _enquiries.doc(
      normalizedEnquiryId,
    );

    final String notificationType = normalizedStatus == 'accepted'
        ? 'enquiry_accepted'
        : 'enquiry_rejected';

    final String notificationId = [
      normalizedEnquiryId,
      normalizedStatus,
    ].join('_');

    final DocumentReference<Map<String, dynamic>> notificationRef = _firestore
        .collection('notifications')
        .doc(notificationId);

    try {
      await _firestore.runTransaction((transaction) async {
        final document = await transaction.get(enquiryRef);

        if (!document.exists || document.data() == null) {
          throw Exception('Enquiry no longer exists.');
        }

        final data = document.data()!;

        if (data['ownerId'] != user.uid) {
          throw Exception('You are not authorized to update this enquiry.');
        }

        if ((data['status'] as String? ?? 'pending') != 'pending') {
          throw Exception('This enquiry has already been processed.');
        }

        transaction.update(enquiryRef, {
          'status': normalizedStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(notificationRef, {
          'id': notificationId,
          'userId': data['customerId'],
          'type': notificationType,
          'title': normalizedStatus == 'accepted'
              ? 'Enquiry accepted'
              : 'Enquiry rejected',
          'message': normalizedStatus == 'accepted'
              ? "Your enquiry for ${data['productName'] ?? 'this product'} has been accepted by the shop."
              : 'Your enquiry for ${data['productName'] ?? 'this product'} has been declined by the shop.',
          'productId': data['productId'],
          'shopId': data['shopId'],
          'enquiryId': normalizedEnquiryId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (e) {
      throw Exception(
        'Firestore ${e.code}: ${e.message ?? 'Unknown Firestore error.'}',
      );
    } finally {
      _pendingEnquiryDecisions.remove(normalizedEnquiryId);
    }
  }

  Stream<List<ProductEnquiry>> watchShopOwnerEnquiries() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream.value(const <ProductEnquiry>[]);
    }

    return _enquiries.where('ownerId', isEqualTo: user.uid).snapshots().map((
      snapshot,
    ) {
      final enquiries = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ProductEnquiry.fromMap(data);
      }).toList();

      enquiries.sort((a, b) {
        final DateTime aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return enquiries;
    });
  }
}
