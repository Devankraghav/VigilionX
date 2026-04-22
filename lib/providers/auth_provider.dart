/// VigilionX - Auth Provider
/// Manages authentication state across the application.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _user;
  bool _isLoading = false;
  String? _error;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  String? get uid => _user?.uid ?? _authService.currentUser?.uid;

  /// Initialize auth state
  Future<void> initialize() async {
    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      try {
        _user = await _authService.getUserProfile(firebaseUser.uid);
      } catch (_) {
        // Profile fetch failed, user will need to re-login
      }
    }
    notifyListeners();
  }

  /// Sign up a new user
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Sign in an existing user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _error = null;
    try {
      _user = await _authService.signIn(
        email: email,
        password: password,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _error = null;
    try {
      await _authService.sendPasswordReset(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? fullName,
    String? phone,
  }) async {
    if (_user == null) return false;
    _setLoading(true);
    try {
      final updated = _user!.copyWith(
        fullName: fullName,
        phone: phone,
      );
      await _authService.updateUserProfile(updated);
      _user = updated;
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
