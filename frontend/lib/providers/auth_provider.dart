import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthState _state = AuthState.initial;
  String? _username;
  String? _errorMessage;

  AuthState get state => _state;
  String? get username => _username;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _state == AuthState.authenticated;

  Future<void> checkAuth() async {
    final loggedIn = await _authService.isLoggedIn();
    if (loggedIn) {
      _username = await _authService.getUsername();
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.login(email, password);
      _username = await _authService.getUsername();
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = _parseError(e);
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.register(username, email, password);
      _username = username;
      _state = AuthState.authenticated;
      notifyListeners();
      return true;
    } on Exception catch (e) {
      _errorMessage = _parseError(e);
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _username = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  String _parseError(Exception e) {
    if (e.toString().contains('401')) return 'Invalid email or password';
    if (e.toString().contains('400')) return 'Check your input and try again';
    return 'Something went wrong. Please try again.';
  }
}
