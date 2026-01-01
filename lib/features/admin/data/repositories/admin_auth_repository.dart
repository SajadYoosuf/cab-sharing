import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> login(String email, String password) async {
    try {
      final query = await _firestore
          .collection('admins')
          .where('email', isEqualTo: email)
          .where('password', isEqualTo: password)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return true;
      }
    } catch (e) {
      // Handle error
    }
    return false;
  }
}
