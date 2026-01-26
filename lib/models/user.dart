import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? password; // Added for visibility in Firestore
  final bool isVerified; // Legacy
  final bool isPhoneVerified;
  final String
  verificationStatus; // 'unverified', 'pending', 'approved', 'rejected'
  final String role;
  final String? phone;
  final String? vehicleType;
  final String? vehicleName;
  final String? vehicleNumber;
  final String? vehicleSeats;

  // Verification Documents (Base64)
  final String? identityDocBase64;
  final String? selfieBase64;
  final String? licenseBase64;

  // Verification Documents (URLs)
  final String? identityDocUrl;
  final String? selfieUrl;
  final String? licenseUrl;

  final bool isBanned;
  final String? banReason;
  final DateTime? banExpiryDate;

  const UserModel({
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
    this.isBanned = false,
    this.banReason,
    this.banExpiryDate,
    this.vehicleType,
    this.vehicleName,
    this.vehicleNumber,
    this.vehicleSeats,
  });

  @override
  List<Object?> get props => [
    id,
    email,
    name,
    password,
    isVerified,
    isPhoneVerified,
    verificationStatus,
    role,
    phone,
    identityDocBase64,
    selfieBase64,
    licenseBase64,
    identityDocUrl,
    selfieUrl,
    licenseUrl,
    isBanned,
    banReason,
    banExpiryDate,
    vehicleType,
    vehicleName,
    vehicleNumber,
    vehicleSeats,
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
      'isBanned': isBanned,
      'banReason': banReason,
      'banExpiryDate': banExpiryDate,
      'vehicleType': vehicleType,
      'vehicleName': vehicleName,
      'vehicleNumber': vehicleNumber,
      'vehicleSeats': vehicleSeats,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
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
      isBanned: map['isBanned'] ?? false,
      banReason: map['banReason'],
      banExpiryDate: map['banExpiryDate'] != null
          ? (map['banExpiryDate'] as Timestamp).toDate()
          : null,
      vehicleType: map['vehicleType'],
      vehicleName: map['vehicleName'],
      vehicleNumber: map['vehicleNumber'],
      vehicleSeats: map['vehicleSeats'],
    );
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? password,
    bool? isVerified,
    bool? isPhoneVerified,
    String? verificationStatus,
    String? role,
    String? phone,
    String? identityDocBase64,
    String? selfieBase64,
    String? licenseBase64,
    String? identityDocUrl,
    String? selfieUrl,
    String? licenseUrl,
    bool? isBanned,
    String? banReason,
    DateTime? banExpiryDate,
    String? vehicleType,
    String? vehicleName,
    String? vehicleNumber,
    String? vehicleSeats,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      password: password ?? this.password,
      isVerified: isVerified ?? this.isVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      identityDocBase64: identityDocBase64 ?? this.identityDocBase64,
      selfieBase64: selfieBase64 ?? this.selfieBase64,
      licenseBase64: licenseBase64 ?? this.licenseBase64,
      identityDocUrl: identityDocUrl ?? this.identityDocUrl,
      selfieUrl: selfieUrl ?? this.selfieUrl,
      licenseUrl: licenseUrl ?? this.licenseUrl,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      banExpiryDate: banExpiryDate ?? this.banExpiryDate,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleName: vehicleName ?? this.vehicleName,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleSeats: vehicleSeats ?? this.vehicleSeats,
    );
  }
}
