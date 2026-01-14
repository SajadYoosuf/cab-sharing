import 'package:ride_share_app/models/user.dart';

abstract class AuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String email, String password);
  Future<void> logout();
  Future<UserModel?> getCurrentUser();
}
