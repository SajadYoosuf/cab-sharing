import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

class VerificationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isLoading = false;
  String? _error;
  String? _verificationId;
  
  // Document Upload State
  File? _identityImage;
  File? _selfieImage;
  File? _licenseImage;
  String _selectedDocType = 'Aadhaar Card';

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get verificationId => _verificationId;
  File? get identityImage => _identityImage;
  File? get selfieImage => _selfieImage;
  File? get licenseImage => _licenseImage;
  String get selectedDocType => _selectedDocType;

  // Phone Verification
  Future<void> sendOtp(String phoneNumber) async {
    _setLoading(true);
    _error = null;
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (mostly Android)
          // For this flow, we might just want to let the user enter OTP to keep UI consistent
          // or auto-sign in if already verified.
        },
        verificationFailed: (FirebaseAuthException e) {
          _error = e.message;
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          notifyListeners();
        },
        codeAutoRetrievalTimeout: (String verificationId) {
           _verificationId = verificationId;
        },
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOtp(String otp) async {
    if (_verificationId == null) return false;
    _setLoading(true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp
      );
      
      User? user = _auth.currentUser;
      if (user != null) {
          try {
             await user.updatePhoneNumber(credential);
             await _firestore.collection('users').doc(user.uid).update({
               'isPhoneVerified': true,
               'phone': user.phoneNumber,
             });
             return true;
          } on FirebaseAuthException catch (e) {
             print('Error updating phone number: ${e.code} - ${e.message}');
             // If credential already linked to another user, or invalid code
             if (e.code == 'credential-already-in-use') {
                _error = 'This phone number is already linked to another account.';
             } else if (e.code == 'invalid-verification-code') {
                _error = 'Invalid verification code.';
             } else {
                _error = e.message;
             }
             return false;
          }
      }
      return false;
    } catch (e) {
      _error = e.toString();
      print('Verify OTP General Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Document Handling
  void setDocType(String type) {
    _selectedDocType = type;
    notifyListeners();
  }

  Future<void> pickIdentityImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      _identityImage = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<void> pickSelfieImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera, 
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      _selfieImage = File(pickedFile.path);
      notifyListeners();
    }
  }

    Future<void> pickLicenseImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 50,
    );
    if (pickedFile != null) {
      _licenseImage = File(pickedFile.path);
      notifyListeners();
    }
  }
  
  void skipLicense() {
    _licenseImage = null;
    notifyListeners();
  }

  Future<bool> submitVerification() async {
    _setLoading(true);
    print('Starting Verification Submission...'); // Debug
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('Error: No user logged in during submission');
        throw Exception('No user logged in');
      }
      
      print('Processing User: ${user.uid}');

      // 1. Process Identity
      String? identityBase64;
      if (_identityImage != null) {
         print('Encoding Identity Image...');
         identityBase64 = await _fileToBase64(_identityImage!);
      } else {
         print('Warning: No Identity Image provided');
      }

      // 2. Process Selfie
      String? selfieBase64;
       if (_selfieImage != null) {
         print('Encoding Selfie Image...');
         selfieBase64 = await _fileToBase64(_selfieImage!);
      } else {
         print('Warning: No Selfie Image provided');
      }

      // 3. Process License (Optional)
      String? licenseBase64;
       if (_licenseImage != null) {
         print('Encoding License Image...');
         licenseBase64 = await _fileToBase64(_licenseImage!);
      } else {
         print('Info: No License Image (Skipped)');
      }
      
      final updateData = {
        'verificationStatus': 'pending',
        'identityDocBase64': identityBase64,
        'selfieBase64': selfieBase64,
        'licenseBase64': licenseBase64,
        'licenseStatus': licenseBase64 != null ? 'pending' : 'none',
        'docType': _selectedDocType,
        'submittedAt': FieldValue.serverTimestamp(),
      };
      
      print('Updating Firestore with data size: ${updateData.toString().length} chars approx');

      // 4. Update Firestore
      await _firestore.collection('users').doc(user.uid).update(updateData);
      
      print('Firestore Update Successful');

      return true;
    } catch (e) {
      _error = e.toString();
      print('Submit Verification Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String> _fileToBase64(File file) async {
    List<int> imageBytes = await file.readAsBytes();
    return base64Encode(imageBytes);
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
