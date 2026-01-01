import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  FirebaseAuthRepository({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      
      final user = credential.user!;
      return UserEntity(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
      );
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  @override
  Future<UserEntity> register(String name, String email, String password) async {
    try {
      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      
      final user = credential.user!;
      await user.updateDisplayName(name);
      
      return UserEntity(
        id: user.uid,
        name: name,
        email: email,
      );
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return UserEntity(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
      );
    }
    return null;
  }
}
