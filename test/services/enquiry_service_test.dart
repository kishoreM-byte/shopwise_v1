import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shopwise_v1/services/customer/enquiry_service.dart';

class _FakeFirebaseAuth implements FirebaseAuth {
  _FakeFirebaseAuth(this._user);

  final User? _user;

  @override
  User? get currentUser => _user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeUser implements User {
  _FakeUser(this.uid);

  @override
  final String uid;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Map<String, Object> _enquiry({String status = 'pending'}) => {
  'id': 'enquiry-1',
  'productId': 'product-1',
  'shopId': 'shop-1',
  'ownerId': 'owner-1',
  'customerId': 'customer-1',
  'customerName': 'Customer',
  'customerEmail': 'customer@example.test',
  'customerPhone': '1234567890',
  'productName': 'Chair',
  'productPrice': 1000,
  'quantity': 1,
  'message': 'Please contact me',
  'status': status,
};

void main() {
  group('EnquiryService.updateEnquiryStatus', () {
    late FakeFirebaseFirestore firestore;
    late EnquiryService service;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      service = EnquiryService(
        firestore: firestore,
        auth: _FakeFirebaseAuth(_FakeUser('owner-1')),
      );
      await firestore.collection('enquiries').doc('enquiry-1').set(_enquiry());
    });

    test('commits the decision and customer notification together', () async {
      await service.updateEnquiryStatus('enquiry-1', 'accepted');

      final enquiry = await firestore
          .collection('enquiries')
          .doc('enquiry-1')
          .get();
      final notification = await firestore
          .collection('notifications')
          .doc('enquiry-1_accepted')
          .get();

      expect(enquiry.data()?['status'], 'accepted');
      expect(notification.data()?['userId'], 'customer-1');
      expect(notification.data()?['type'], 'enquiry_accepted');
      expect(notification.data()?['isRead'], isFalse);
    });

    test('rejects a second decision after the enquiry is processed', () async {
      await service.updateEnquiryStatus('enquiry-1', 'accepted');

      await expectLater(
        service.updateEnquiryStatus('enquiry-1', 'rejected'),
        throwsA(
          predicate(
            (error) => error.toString().contains(
              'This enquiry has already been processed.',
            ),
          ),
        ),
      );

      expect(
        (await firestore.collection('notifications').get()).docs,
        hasLength(1),
      );
    });

    test('allows only one concurrent shop decision', () async {
      final decisions = await Future.wait<bool>([
        service
            .updateEnquiryStatus('enquiry-1', 'accepted')
            .then((_) => true, onError: (_) => false),
        service
            .updateEnquiryStatus('enquiry-1', 'rejected')
            .then((_) => true, onError: (_) => false),
      ]);

      expect(decisions.where((succeeded) => succeeded), hasLength(1));
      expect(
        (await firestore.collection('notifications').get()).docs,
        hasLength(1),
      );
    });

    test('rejects decisions from another shop owner', () async {
      final otherOwnerService = EnquiryService(
        firestore: firestore,
        auth: _FakeFirebaseAuth(_FakeUser('owner-2')),
      );

      await expectLater(
        otherOwnerService.updateEnquiryStatus('enquiry-1', 'rejected'),
        throwsA(
          predicate(
            (error) => error.toString().contains(
              'You are not authorized to update this enquiry.',
            ),
          ),
        ),
      );

      expect(
        (await firestore.collection('enquiries').doc('enquiry-1').get())
            .data()?['status'],
        'pending',
      );
      expect((await firestore.collection('notifications').get()).docs, isEmpty);
    });
  });
}
