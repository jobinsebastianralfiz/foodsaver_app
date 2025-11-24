import 'package:flutter/foundation.dart';
import '../../data/models/user/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/local/shared_prefs_service.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  loading,
}

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final SharedPreferencesService _prefsService;

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _error;
  bool _isLoading = false;

  AuthProvider(this._authRepository, this._prefsService) {
    _initializeAuth();
  }

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  UserRole? get userRole => _user?.role;

  // Initialize authentication state
  Future<void> _initializeAuth() async {
    try {
      // Check if user is already logged in
      final currentUser = _authRepository.currentFirebaseUser;
      if (currentUser != null) {
        final userData = await _authRepository.getCurrentUser();
        _user = userData;
        _status = AuthStatus.authenticated;
        await _prefsService.setUser(userData);
        notifyListeners();
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  // Login with email and password
  Future<void> login(String email, String password) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await _authRepository.login(email, password);
      _user = user;
      _status = AuthStatus.authenticated;
      await _prefsService.setUser(user);
      _setLoading(false);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      rethrow;
    }
  }

  // Register with email and password
  Future<void> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    String? phoneNumber,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      final user = await _authRepository.register(
        email: email,
        password: password,
        name: name,
        role: role,
        phoneNumber: phoneNumber,
      );
      _user = user;
      _status = AuthStatus.authenticated;
      await _prefsService.setUser(user);
      _setLoading(false);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      rethrow;
    }
  }

  // Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await _authRepository.logout();
      await _prefsService.clearUser();
      await _prefsService.clearAuthToken();
      _user = null;
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    _setLoading(true);
    _error = null;

    try {
      await _authRepository.resetPassword(email);
      _setLoading(false);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? phoneNumber,
    String? profilePhoto,
  }) async {
    _setLoading(true);
    _error = null;

    try {
      await _authRepository.updateUserProfile(
        name: name,
        phoneNumber: phoneNumber,
        profilePhoto: profilePhoto,
      );

      // Refresh user data
      final updatedUser = await _authRepository.getCurrentUser();
      _user = updatedUser;
      await _prefsService.setUser(updatedUser);
      _setLoading(false);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      rethrow;
    }
  }

  // Refresh user data
  Future<void> refreshUser() async {
    try {
      final updatedUser = await _authRepository.getCurrentUser();
      _user = updatedUser;
      await _prefsService.setUser(updatedUser);
      notifyListeners();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Get home route based on user role
  String getHomeRoute() {
    switch (userRole) {
      case UserRole.customer:
        return '/customer/home';
      case UserRole.restaurant:
        return '/restaurant/dashboard';
      case UserRole.admin:
        return '/admin/dashboard';
      default:
        return '/login';
    }
  }
}
