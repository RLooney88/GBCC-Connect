import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user.dart';
import '../services/firebase_auth_service.dart';
import '../services/service_manager.dart';
import 'dart:async';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuthService _authService = FirebaseAuthService.instance;
  final ServiceManager _serviceManager = ServiceManager.instance;

  // Maintain both authentication state and user data
  bool _isLoading = false;
  bool _isAuthenticated = false;
  firebase_auth.User? _firebaseUser;
  User? _currentUser;
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;

  // Callback to notify FirebaseProvider
  Function(String)? _onUserAuthenticated;
  VoidCallback? _onUserLoggedOut;

  // Getters
  firebase_auth.User? get firebaseUser => _firebaseUser;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => _firebaseUser?.uid;

  AuthProvider() {
    _initializeAuth();
  }

  /// Set callbacks for FirebaseProvider coordination
  void setFirebaseProviderCallbacks({
    required Function(String) onUserAuthenticated,
    required VoidCallback onUserLoggedOut,
  }) {
    _onUserAuthenticated = onUserAuthenticated;
    _onUserLoggedOut = onUserLoggedOut;
  }

  Future<void> _initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Check current auth status
      await _checkAuthStatus();

      // Set up auth state listener
      _listenToAuthChanges();
    } catch (e) {
      debugPrint('AuthProvider: Error initializing auth: $e');
      _isAuthenticated = false;
      _firebaseUser = null;
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToAuthChanges() {
    // Cancel any existing subscription
    _authStateSubscription?.cancel();

    _authStateSubscription = _authService.authStateChanges.listen(
      (firebaseUser) async {
        debugPrint(
            'AuthProvider: Auth state changed - user: ${firebaseUser?.uid}');

        if (firebaseUser != null) {
          _isAuthenticated = true;
          _firebaseUser = firebaseUser;
          debugPrint('AuthProvider: User authenticated: ${firebaseUser.uid}');

          // Load user data from Firebase
          await _loadUserFromFirebase(firebaseUser.uid);

          // Notify FirebaseProvider to load additional data
          _onUserAuthenticated?.call(firebaseUser.uid);
        } else {
          _isAuthenticated = false;
          _firebaseUser = null;
          _currentUser = null;
          debugPrint('AuthProvider: User signed out');

          // Notify FirebaseProvider to clear user data
          _onUserLoggedOut?.call();
        }

        notifyListeners();
      },
      onError: (error) {
        debugPrint('AuthProvider: Auth state listener error: $error');
        _isAuthenticated = false;
        _firebaseUser = null;
        _currentUser = null;
        notifyListeners();
      },
    );
  }

  Future<void> _checkAuthStatus() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        _isAuthenticated = true;
        _firebaseUser = firebaseUser;
        debugPrint('AuthProvider: Current user found: ${firebaseUser.uid}');

        // Load user data from Firebase
        await _loadUserFromFirebase(firebaseUser.uid);

        // Notify FirebaseProvider to load additional data
        _onUserAuthenticated?.call(firebaseUser.uid);
      } else {
        _isAuthenticated = false;
        _firebaseUser = null;
        _currentUser = null;
        debugPrint('AuthProvider: No current user found');
      }
    } catch (e) {
      debugPrint('AuthProvider: Error checking auth status: $e');
      _isAuthenticated = false;
      _firebaseUser = null;
      _currentUser = null;
    }
  }

  /// Load user data from Firebase
  Future<void> _loadUserFromFirebase(String userId) async {
    try {
      debugPrint('AuthProvider: Loading user data from Firebase for: $userId');

      // Try to get user from Firebase
      final user = await _serviceManager.users.getUserById(userId);

      if (user != null) {
        _currentUser = user;
        debugPrint(
            'AuthProvider: User data loaded from Firebase: ${user.name}');
      } else {
        debugPrint('AuthProvider: User not found in Firebase, creating...');
        await _createUserInFirebase(userId);
      }
    } catch (e) {
      debugPrint('AuthProvider: Error loading user from Firebase: $e');
      // Create fallback user with auth data
      await _createUserInFirebase(userId);
    }
  }

  /// Create user in Firebase from authentication data
  Future<void> _createUserInFirebase(String userId) async {
    try {
      final authUser = _serviceManager.auth.currentUser;
      if (authUser == null) {
        throw Exception('No authenticated user found');
      }

      debugPrint('AuthProvider: Creating user in Firebase from auth data');

      // Create user in Firebase with auth user data
      final newUser = User(
        id: authUser.uid,
        name: authUser.displayName ?? 'User',
        email: authUser.email ?? '',
        phone: authUser.phoneNumber,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _serviceManager.users.createUserWithId(authUser.uid, newUser);
      debugPrint('AuthProvider: User created successfully in Firebase');

      // Set the current user
      _currentUser = newUser;
    } catch (e) {
      debugPrint('AuthProvider: Error creating user in Firebase: $e');
      // Create fallback user with basic auth data
      final authUser = _serviceManager.auth.currentUser;
      if (authUser != null) {
        _currentUser = User(
          id: authUser.uid,
          name: authUser.displayName ?? 'User',
          email: authUser.email ?? '',
          phone: authUser.phoneNumber,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    }
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
        _firebaseUser = credential.user!;
        debugPrint(
            'AuthProvider: Login successful for: ${credential.user!.uid}');

        // Load user data from Firebase
        await _loadUserFromFirebase(credential.user!.uid);

        return {'success': true};
      }
      return {'success': false, 'error': 'Login failed'};
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('AuthProvider: Login error: ${e.code} - ${e.message}');
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
      _firebaseUser = null;
      _currentUser = null;
      debugPrint('AuthProvider: Logout successful');
    } catch (e) {
      debugPrint('AuthProvider: Logout error: $e');
      // Even if logout fails, clear local state
      _isAuthenticated = false;
      _firebaseUser = null;
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
      debugPrint('AuthProvider: Password reset email sent to: $email');
      return true;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AuthProvider: Password reset error: ${e.code} - ${e.message}');
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
        _firebaseUser = credential.user!;
        debugPrint(
            'AuthProvider: Google sign-in successful for: ${credential.user!.uid}');

        // Load user data from Firebase
        await _loadUserFromFirebase(credential.user!.uid);

        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AuthProvider: Google sign-in error: ${e.code} - ${e.message}');
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
        _firebaseUser = credential.user!;
        debugPrint(
            'AuthProvider: Apple sign-in successful for: ${credential.user!.uid}');

        // Load user data from Firebase
        await _loadUserFromFirebase(credential.user!.uid);

        return true;
      }
      return false;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('AuthProvider: Apple sign-in error: ${e.code} - ${e.message}');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update the current user data
  void updateCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Force refresh the current user data from Firebase
  Future<void> refreshCurrentUser() async {
    if (_currentUser != null) {
      try {
        final firebaseUser = _authService.currentUser;
        if (firebaseUser != null) {
          await _loadUserFromFirebase(firebaseUser.uid);
        }
      } catch (e) {
        debugPrint('AuthProvider: Error refreshing user: $e');
      }
    }
  }

  String getAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    return _authService.getAuthErrorMessage(e);
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
