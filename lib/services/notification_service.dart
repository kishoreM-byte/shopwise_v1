import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _notifications {
    return _firestore.collection('notifications');
  }

  Stream<List<AppNotification>> watchMyNotifications() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream.value(const <AppNotification>[]);
    }

    return _notifications
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) {
      final notifications = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return AppNotification.fromMap(data);
      }).toList();

      notifications.sort((a, b) {
        final DateTime aDate =
            a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bDate =
            b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return notifications;
    });
  }

  Stream<int> watchUnreadCount() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream.value(0);
    }

    return _notifications
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<String> createNotification({
    required String userId,
    required String type,
    required String title,
    required String message,
    String? productId,
    String? shopId,
    String? enquiryId,
  }) async {
    final DocumentReference<Map<String, dynamic>> document =
        _notifications.doc();

    await document.set({
      'id': document.id,
      'userId': userId,
      'type': type,
      'title': title,
      'message': message,
      'productId': productId,
      'shopId': shopId,
      'enquiryId': enquiryId,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Future<void> markAsRead(String notificationId) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('Please sign in to update notifications.');
    }

    final document = await _notifications.doc(notificationId).get();

    if (!document.exists) {
      throw Exception('Notification no longer exists.');
    }

    final data = document.data();

    if (data == null || data['userId'] != user.uid) {
      throw Exception('You are not authorized to update this notification.');
    }

    if (data['isRead'] == true) {
      return;
    }

    await _notifications.doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllAsRead() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final snapshot = await _notifications
        .where('userId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) {
      return;
    }

    final WriteBatch batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }
}
