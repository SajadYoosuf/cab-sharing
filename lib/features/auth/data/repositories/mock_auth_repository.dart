import 'package:uuid/uuid.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  UserEntity? _currentUser;
  
  @override
  Future<UserEntity> login(String email, String password) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network
    if (email == 'fail@test.com') {
      throw Exception('Invalid credentials');
    }
    // Mock login
    _currentUser = UserEntity(
      id: const Uuid().v4(),
      email: email,
      name: 'Test User',
      isVerified: true,
    );
    return _currentUser!;
  }

  @override
  Future<UserEntity> register(String name, String email, String password) async {
    await Future.delayed(const Duration(seconds: 1));
    _currentUser = UserEntity(
      id: const Uuid().v4(),
      email: email,
      name: name,
      isVerified: false,
    );
    return _currentUser!;
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return _currentUser;
  }
}
