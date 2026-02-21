import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../database/auth_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _error = null;

    try {
      if (username.isEmpty) {
        _error = 'Username is required';
        _setLoading(false);
        return false;
      }
      if (password.isEmpty) {
        _error = 'Password is required';
        _setLoading(false);
        return false;
      }

      final user = await _authService.loginUser(username, password);
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        _error = null;
        _setLoading(false);
        return true;
      } else {
        _error = 'Invalid username or password';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Login failed: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> register(
    String username,
    String email,
    String fullName,
    String password,
  ) async {
    _setLoading(true);
    _error = null;

    try {
      if (username.isEmpty) {
        _error = 'Username is required';
        _setLoading(false);
        return false;
      }

      if (!User.validateUsername(username)) {
        _error =
            'Username must be 3-20 characters and can only contain letters, numbers, underscores, and hyphens';
        _setLoading(false);
        return false;
      }

      if (email.isEmpty || !User.validateEmail(email)) {
        _error = 'Valid email is required';
        _setLoading(false);
        return false;
      }

      if (fullName.isEmpty || !User.validateFullName(fullName)) {
        _error =
            'Full name must be 2-50 characters and can only contain letters, spaces, hyphens, and apostrophes';
        _setLoading(false);
        return false;
      }

      if (password.isEmpty || password.length < 6) {
        _error = 'Password must be at least 6 characters';
        _setLoading(false);
        return false;
      }

      final userId = await _authService.registerUser(
        username,
        email,
        fullName,
        password,
      );

      final user = await _authService.loginUser(username, password);

      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
        _error = null;
        _setLoading(false);
        return true;
      } else {
        _error = 'Registration succeeded but login failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = 'Registration failed: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authService.logoutUser();
      _currentUser = null;
      _isAuthenticated = false;
      _error = null;
      _setLoading(false);
    } catch (e) {
      _error = 'Logout failed: ${e.toString()}';
      _setLoading(false);
    }
  }

  Future<void> checkSession() async {
    _isLoading = true;
    // Don't call notifyListeners here - we're being called during build

    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        _currentUser = user;
        _isAuthenticated = true;
      } else {
        _currentUser = null;
        _isAuthenticated = false;
      }
    } catch (e) {
      _currentUser = null;
      _isAuthenticated = false;
      _error = 'Session check failed: ${e.toString()}';
    }

    _isLoading = false;
    // Notify safely after state is set
    _notifySafe();
  }

  void clearError() {
    _error = null;
    _notifySafe();
  }

  /// Sets loading state safely
  void _setLoading(bool loading) {
    _isLoading = loading;
    _notifySafe();
  }

  /// Notify listeners safely to avoid "during build" errors
  void _notifySafe() {
    // Schedule notification for after the current frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      return await _authService.isUsernameAvailable(username);
    } catch (_) {
      return false;
    }
  }
}