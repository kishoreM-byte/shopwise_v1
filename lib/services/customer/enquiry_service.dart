import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/enquiry.dart';

class EnquiryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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

  Future<void> updateEnquiryStatus(
    String enquiryId,
    String status,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to update an enquiry.');
    }

    final normalizedStatus = status.trim().toLowerCase();

    if (normalizedStatus != 'accepted' &&
        normalizedStatus != 'rejected') {
      throw Exception('Invalid enquiry status.');
    }

    final document = await _enquiries.doc(enquiryId).get();

    if (!document.exists) {
      throw Exception('Enquiry no longer exists.');
    }

    final data = document.data();

    if (data == null || data['ownerId'] != user.uid) {
      throw Exception('You are not authorized to update this enquiry.');
    }

    if ((data['status'] as String? ?? 'pending') != 'pending') {
      throw Exception('This enquiry has already been processed.');
    }

    await _enquiries.doc(enquiryId).update({
      'status': normalizedStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
