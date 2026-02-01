import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';
import '../models/app_user_user_model.dart';
// mailer removed

class AuthViewModel with ChangeNotifier {
  final AuthService _authService;
  AppUser? _currentUser;
  bool _isLoading = false;
  String? _error;

  AuthViewModel(this._authService);

  bool _isInitializing = true;
  bool _isLinkSent = false;

  // Getters
  AppUser? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isLinkSent => _isLinkSent;

  // Step 1: Start registration by sending Link
  Future<bool> requestSignInLink(String email) async {
    final cleanEmail = email.trim();
    _setLoading(true);
    try {
      await _authService.sendSignInLink(cleanEmail);
      _isLinkSent = true;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = "Link Failed: ${e.toString()}";
      print('❌ Link Request Error: $e');
      _setLoading(false);
      return false;
    }
  }

  // Step 2: Complete registration (usually called from deep link parsing)
  Future<bool> completeRegistrationWithLink({
    required String email,
    required String link,
    required String password,
    required String name,
    required String role,
  }) async {
    _setLoading(true);
    try {
      final isLink = await _authService.isSignInWithEmailLink(link);
      if (!isLink) {
        _error = "Invalid or expired link";
        _setLoading(false);
        return false;
      }

      await _authService.signInWithEmailLink(email.trim(), link);
      
      // Update profile with name and role
      final user = await _authService.getUserData(_authService.currentUserId!);
      if (user != null) {
        _currentUser = user;
        _isLinkSent = false;
        _setLoading(false);
        return true;
      }
      _setLoading(false);
      return false;
    } catch (e) {
      _error = "Completion Failed: ${e.toString()}";
      _setLoading(false);
      return false;
    }
  }

  // Legacy register method updated for link flow
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String preferredLanguage = 'en',
  }) async {
    return requestSignInLink(email);
  }

  // Sign in
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);

    try {
      final user = await _authService.signInUser(email, password);
      if (user != null) {
        _currentUser = user;
        _setLoading(false);
        return true;
      } else {
        _error = "Invalid email or password";
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _currentUser = null;
    notifyListeners();
  }

  // Load current user
  Future<void> loadCurrentUser() async {
    _isInitializing = true;
    _setLoading(true);

    try {
      _currentUser = await _authService.getCurrentUser();
    } catch (e) {
      _error = "Failed to load user";
    }

    _isInitializing = false;
    _setLoading(false);
  }

  // Update profile
  Future<void> updateProfile(AppUser user) async {
    _setLoading(true);

    try {
      await _authService.updateProfile(user);
      _currentUser = user;
      _setLoading(false);
    } catch (e) {
      _error = "Failed to update profile";
      _setLoading(false);
      rethrow;
    }
  }

  // Helper method to set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    _error = null;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // State Reset
  void resetOtpState() {
    _isLinkSent = false;
    notifyListeners();
  }
}