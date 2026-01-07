import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ride_share_app/features/auth/domain/entities/user_entity.dart';
import 'package:ride_share_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:ride_share_app/core/errors/auth_failure.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<UserEntity> login(String email, String password) async {
    try {
      final UserCredential credential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);
      
      final user = credential.user!;
      
      // Fetch user data from Firestore to get role and other details
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return UserEntity.fromMap({
          ...userDoc.data()!,
          'id': user.uid,
        });
      } else {
        // Migration: Save existing auth user to Firestore
        final newUser = UserEntity(
          id: user.uid,
          name: user.displayName ?? 'Registered User',
          email: user.email ?? '',
          role: 'user',
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }

      return UserEntity(
        id: user.uid,
        name: user.displayName ?? '',
        email: user.email ?? '',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure.fromFirebase(e.code);
    } catch (e) {
      throw AuthFailure('An unexpected error occurred during login.');
    }
  }

  @override
  Future<UserEntity> register(String name, String email, String password) async {
    try {
      final UserCredential credential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);
      
      final user = credential.user!;
      await user.updateDisplayName(name);
      
      final userEntity = UserEntity(
        id: user.uid,
        name: name,
        email: email,
        role: 'user',
      );

      // Save user to Firestore for admin visibility
      await _firestore.collection('users').doc(user.uid).set(userEntity.toMap());
      
      return userEntity;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Register Error: ${e.code} - ${e.message}');
      throw AuthFailure.fromFirebase(e.code);
    } catch (e) {
      print('General Register Error: $e');
      throw AuthFailure('An unexpected error occurred during registration. Details: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // Ensure we wait for the persistence layer to restoration
    final user = await _firebaseAuth.authStateChanges().first;
    
    if (user != null) {
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return UserEntity.fromMap({
            ...userDoc.data()!,
            'id': user.uid,
          });
        }
        return UserEntity(
          id: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
        );
      } catch (e) {
        // Fallback if firestore fails but auth is valid
        return UserEntity(
          id: user.uid,
          name: user.displayName ?? '',
          email: user.email ?? '',
        );
      }
    }
    return null;
  }
}
