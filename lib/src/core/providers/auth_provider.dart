import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../services/firebase_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService.instance;

  User? _currentUser;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  AuthProvider() {
    _checkAuthStatus();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _isAuthenticated = true;
        _currentUser = await _convertFirebaseUser(firebaseUser);
      } else {
        _isAuthenticated = false;
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  Future<User?> _convertFirebaseUser(firebase_auth.User firebaseUser) async {
    try {
      final userData = await _authService.getUserData(firebaseUser.uid);
      return User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? userData?['displayName'] ?? 'User',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber,
        createdAt: userData?['createdAt']?.toDate() ?? DateTime.now(),
        updatedAt: userData?['updatedAt']?.toDate() ?? DateTime.now(),
      );
    } catch (e) {
      // Fallback if user data cannot be retrieved
      return User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<void> _checkAuthStatus() async {
    _isLoading = true;
    notifyListeners();

    final firebaseUser = _authService.currentUser;
    if (firebaseUser != null) {
      _isAuthenticated = true;
      _currentUser = await _convertFirebaseUser(firebaseUser);
    } else {
      _isAuthenticated = false;
      _currentUser = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _isAuthenticated = true;
        _currentUser = await _convertFirebaseUser(credential.user!);
        return {'success': true};
      }
      return {'success': false, 'error': 'Login failed'};
    } on firebase_auth.FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': _authService.getAuthErrorMessage(e),
        'code': e.code
      };
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
      _isAuthenticated = false;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on firebase_auth.FirebaseAuthException {
      // Error is already logged in the service
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _authService.signInWithGoogle();
      if (credential.user != null) {
        _isAuthenticated = true;
        _currentUser = await _convertFirebaseUser(credential.user!);
        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException {
      // Error is already logged in the service
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signInWithApple() async {
    _isLoading = true;
    notifyListeners();

    try {
      final credential = await _authService.signInWithApple();

      if (credential.user != null) {
        _isAuthenticated = true;
        _currentUser = await _convertFirebaseUser(credential.user!);
        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException {
      // Error is already logged in the service
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String getAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    return _authService.getAuthErrorMessage(e);
  }
}
