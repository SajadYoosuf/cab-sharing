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
  final String? phone;
  final String? identityDocBase64;
  final String? selfieBase64;
  final String? licenseBase64;
  final String? identityDocUrl;
  final String? selfieUrl;
  final String? licenseUrl;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.password,
    this.isVerified = false,
    this.isPhoneVerified = false,
    this.verificationStatus = 'unverified',
    this.role = 'user',
    this.phone,
    this.identityDocBase64,
    this.selfieBase64,
    this.licenseBase64,
    this.identityDocUrl,
    this.selfieUrl,
    this.licenseUrl,
  });

  @override
  List<Object?> get props => [
        id, email, name, password, isVerified, isPhoneVerified, 
        verificationStatus, role, phone, identityDocBase64, selfieBase64, 
        licenseBase64, identityDocUrl, selfieUrl, licenseUrl
      ];

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
      'phone': phone,
      'identityDocBase64': identityDocBase64,
      'selfieBase64': selfieBase64,
      'licenseBase64': licenseBase64,
      'identityDocUrl': identityDocUrl,
      'selfieUrl': selfieUrl,
      'licenseUrl': licenseUrl,
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
      phone: map['phone'],
      identityDocBase64: map['identityDocBase64'],
      selfieBase64: map['selfieBase64'],
      licenseBase64: map['licenseBase64'],
      identityDocUrl: map['identityDocUrl'],
      selfieUrl: map['selfieUrl'],
      licenseUrl: map['licenseUrl'],
    );
  }
}
