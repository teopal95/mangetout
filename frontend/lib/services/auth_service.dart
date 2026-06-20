import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _usernameKey = 'username';
  static const _emailKey = 'email';

  Future<void> register(String username, String email, String password) async {
    final response = await _dio.post(ApiConfig.register, data: {
      'username': username,
      'email': email,
      'password': password,
    });
    await _saveSession(response.data);
  }

  Future<void> login(String email, String password) async {
    final response = await _dio.post(ApiConfig.login, data: {
      'email': email,
      'password': password,
    });
    await _saveSession(response.data);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);
  Future<String?> getUsername() => _storage.read(key: _usernameKey);
  Future<bool> isLoggedIn() async => (await getToken()) != null;

  Future<void> _saveSession(Map<String, dynamic> data) async {
    await _storage.write(key: _tokenKey, value: data['token']);
    await _storage.write(key: _usernameKey, value: data['username']);
    await _storage.write(key: _emailKey, value: data['email']);
  }
}
