import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? password; // Added for visibility in Firestore
  final bool isVerified; // Legacy
  final bool isPhoneVerified;
  final String verificationStatus; // 'unverified', 'pending', 'approved', 'rejected'
  final String role; 

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.password,
    this.isVerified = false,
    this.isPhoneVerified = false,
    this.verificationStatus = 'unverified',
    this.role = 'user',
  });

  @override
  List<Object?> get props => [id, email, name, password, isVerified, isPhoneVerified, verificationStatus, role];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'password': password,
      'isVerified': isVerified,
      'isPhoneVerified': isPhoneVerified,
      'verificationStatus': verificationStatus,
      'role': role,
    };
  }

  factory UserEntity.fromMap(Map<String, dynamic> map) {
    return UserEntity(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      password: map['password'],
      isVerified: map['isVerified'] ?? false,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      verificationStatus: map['verificationStatus'] ?? 'unverified',
      role: map['role'] ?? 'user',
    );
  }
}
