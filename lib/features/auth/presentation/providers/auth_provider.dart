import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  
  UserEntity? _currentUser;
  bool _isLoading = false;
  String? _error;
  final Completer<void> _initCompleter = Completer<void>();

  Future<void> get initialized => _initCompleter.future;

  UserEntity? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider(this._authRepository) {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_data');
    if (userJson != null) {
      try {
        final userData = json.decode(userJson);
        _currentUser = UserEntity.fromMap(userData);
        notifyListeners();
        // Refresh from remote to ensure latest data (like role)
        await checkAuthStatus();
      } catch (e) {
        prefs.remove('user_data');
      }
    }
    if (!_initCompleter.isCompleted) _initCompleter.complete();
  }

  Future<void> checkAuthStatus() async {
    // If it's the static admin, don't check via Firebase
    if (_currentUser?.id == 'admin_static_id') {
       return;
    }

    try {
      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        await _saveUserToPrefs(user);
        notifyListeners();
      } else {
        await logout();
      }
    } catch (e) {
      debugPrint('Error checking auth status: $e');
    }
  }

  Future<void> setManualUser(UserEntity user) async {
    _currentUser = user;
    await _saveUserToPrefs(user);
    notifyListeners();
  }

  Future<void> _saveUserToPrefs(UserEntity user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', json.encode(user.toMap()));
  }

  Future<void> _clearUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.login(email, password);
      if (_currentUser != null) {
        await _saveUserToPrefs(_currentUser!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.register(name, email, password);
      if (_currentUser != null) {
        await _saveUserToPrefs(_currentUser!);
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    await _clearUserFromPrefs();
    _currentUser = null;
    notifyListeners();
  }
}
