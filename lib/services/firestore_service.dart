import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> testConnection() async {
    await _firestore.collection('connection_test').doc('test').set({
      'message': 'ShopWise Firestore connection successful',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
