import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../config/firebase_config.dart';
import 'dart:async';

/// Comprehensive Authentication Provider that manages all Firebase authentication logic
/// Supports email/password, Google, and Apple Sign-In with Firestore sync
/// Also handles global auth state and route determination
class AuthProvider extends ChangeNotifier {
  static AuthProvider? _instance;
  static AuthProvider get instance => _instance ??= AuthProvider._internal();

  AuthProvider._internal();

  // Firebase services
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseConfigService _configService = FirebaseConfigService.instance;

  // State variables
  bool _isLoading = false;
  bool _isInitialized = false;
  firebase_auth.User? _firebaseUser;
  User? _currentUser;
  StreamSubscription<firebase_auth.User?>? _authStateSubscription;

  // Getters
  firebase_auth.User? get firebaseUser => _firebaseUser;
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _firebaseUser?.uid;

  // Auth state stream for global listening
  Stream<firebase_auth.User?> get authStateChanges => _auth.authStateChanges();

  /// Initialize the authentication provider
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _setLoading(true);

      // Set up auth state listener
      _listenToAuthChanges();

      // Check current auth status
      await _checkCurrentAuthStatus();

      _isInitialized = true;
      debugPrint('AuthProvider: Initialized successfully');
    } catch (e) {
      debugPrint('AuthProvider: Initialization error: $e');
      _setError('Failed to initialize authentication');
    } finally {
      _setLoading(false);
    }
  }

  /// Listen to Firebase auth state changes
  void _listenToAuthChanges() {
    _authStateSubscription?.cancel();

    _authStateSubscription = _auth.authStateChanges().listen(
      (firebaseUser) async {
        debugPrint(
            'AuthProvider: Auth state changed - user: ${firebaseUser?.uid}');

        if (firebaseUser != null) {
          _firebaseUser = firebaseUser;
          await loadCurrentUser();
        } else {
          _firebaseUser = null;
          _currentUser = null;
        }

        notifyListeners();
      },
      onError: (error) {
        debugPrint('AuthProvider: Auth state listener error: $error');
        _setError('Authentication state error: $error');
      },
    );
  }

  /// Check current authentication status on app start
  Future<void> _checkCurrentAuthStatus() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _firebaseUser = firebaseUser;
      await loadCurrentUser();
    }
  }

  /// Load current user data from Firestore
  Future<void> loadCurrentUser() async {
    if (_firebaseUser == null) return;

    try {
      _setLoading(true);

      final userDoc =
          await _firestore.collection('users').doc(_firebaseUser!.uid).get();

      if (userDoc.exists) {
        _currentUser = User.fromJson({
          'id': userDoc.id,
          ...userDoc.data()!,
        });
        debugPrint('AuthProvider: User data loaded: ${_currentUser!.name}');
      } else {
        // Create user document if it doesn't exist
        await _createUserDocument();
      }
    } catch (e) {
      debugPrint('AuthProvider: Error loading user: $e');
      _setError('Failed to load user data');
    } finally {
      _setLoading(false);
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument([String? displayName]) async {
    if (_firebaseUser == null) return;

    try {
      final newUser = User(
        id: _firebaseUser!.uid,
        name: displayName ?? _firebaseUser!.displayName ?? 'No Name',
        email: _firebaseUser!.email ?? '',
        phone: _firebaseUser!.phoneNumber,
      );

      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .set(newUser.toJson());

      _currentUser = newUser;
      debugPrint('AuthProvider: User document created: ${newUser.name}');
    } catch (e) {
      debugPrint('AuthProvider: Error creating user document: $e');
      _setError('Failed to create user profile');
    }
  }

  /// Update user data in Firestore
  Future<void> updateUser(User updatedUser) async {
    if (_firebaseUser == null) return;

    try {
      _setLoading(true);

      final userData = updatedUser.toJson();

      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .update(userData);

      _currentUser = updatedUser.copyWith(
        updatedAt: Timestamp.now().toDate(),
      );

      notifyListeners();
      debugPrint('AuthProvider: User updated successfully');
    } catch (e) {
      debugPrint('AuthProvider: Error updating user: $e');
      _setError('Failed to update user profile');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== EMAIL & PASSWORD AUTHENTICATION ====================

  /// Sign in with email and password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      _setLoading(true);

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        _firebaseUser = credential.user;
        await loadCurrentUser();

        // Log analytics
        await _configService.logEvent(
          name: 'user_login',
          parameters: {
            'method': 'email',
            'user_id': credential.user!.uid,
          },
        );

        return AuthResult.success();
      }

      return AuthResult.error('Login failed');
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('AuthProvider: Email sign-in error: ${e.code} - ${e.message}');
      return AuthResult.error(_getAuthErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  /// Register with email and password
  Future<AuthResult> registerWithEmail(
      String email, String password, String displayName) async {
    try {
      _setLoading(true);

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(displayName);

        _firebaseUser = credential.user;
        await _createUserDocument(displayName);

        // Log analytics
        await _configService.logEvent(
          name: 'user_signup',
          parameters: {
            'method': 'email',
            'user_id': credential.user!.uid,
          },
        );

        return AuthResult.success();
      }

      return AuthResult.error('Registration failed');
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AuthProvider: Email registration error: ${e.code} - ${e.message}');
      return AuthResult.error(_getAuthErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  /// Send password reset email
  Future<AuthResult> forgotPassword(String email) async {
    try {
      _setLoading(true);

      await _auth.sendPasswordResetEmail(email: email);

      return AuthResult.success();
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AuthProvider: Password reset error: ${e.code} - ${e.message}');
      return AuthResult.error(_getAuthErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // ==================== SOCIAL AUTHENTICATION ====================

  /// Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      _setLoading(true);

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return AuthResult.error('Google sign-in cancelled');
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        _firebaseUser = userCredential.user;
        await loadCurrentUser();

        // Log analytics
        await _configService.logEvent(
          name: 'user_login',
          parameters: {
            'method': 'google',
            'user_id': userCredential.user!.uid,
          },
        );

        return AuthResult.success();
      }

      return AuthResult.error('Google sign-in failed');
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AuthProvider: Google sign-in error: ${e.code} - ${e.message}');
      return AuthResult.error(_getAuthErrorMessage(e));
    } catch (e) {
      debugPrint('AuthProvider: Google sign-in error: $e');
      return AuthResult.error('Google sign-in failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    try {
      _setLoading(true);

      // Trigger Apple Sign-In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuth credential
      final oauthCredential =
          firebase_auth.OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      if (userCredential.user != null) {
        _firebaseUser = userCredential.user;
        await loadCurrentUser();

        // Log analytics
        await _configService.logEvent(
          name: 'user_login',
          parameters: {
            'method': 'apple',
            'user_id': userCredential.user!.uid,
          },
        );

        return AuthResult.success();
      }

      return AuthResult.error('Apple sign-in failed');
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('AuthProvider: Apple sign-in error: ${e.code} - ${e.message}');
      return AuthResult.error(_getAuthErrorMessage(e));
    } catch (e) {
      debugPrint('AuthProvider: Apple sign-in error: $e');
      return AuthResult.error('Apple sign-in failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ==================== LOGOUT ====================

  /// Sign out user
  Future<void> logout() async {
    try {
      _setLoading(true);

      // Sign out from Google if signed in
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      // Sign out from Firebase
      await _auth.signOut();

      // Clear local state
      _firebaseUser = null;
      _currentUser = null;

      debugPrint('AuthProvider: User signed out successfully');
    } catch (e) {
      debugPrint('AuthProvider: Logout error: $e');
      // Clear local state even if logout fails
      _firebaseUser = null;
      _currentUser = null;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== ROUTE MANAGEMENT ====================

  /// Get initial route based on authentication state
  String getInitialRoute() {
    if (!_isInitialized) {
      return '/splash'; // Show splash while initializing
    }

    if (isAuthenticated) {
      return '/dashboard'; // User is authenticated, go to main app
    } else {
      return '/login'; // User is not authenticated, go to login
    }
  }

  /// Check if user should be redirected to login
  bool shouldRedirectToLogin() {
    return _isInitialized && !isAuthenticated;
  }

  /// Check if user should be redirected to dashboard
  bool shouldRedirectToDashboard() {
    return _isInitialized && isAuthenticated;
  }

  // ==================== UTILITY METHODS ====================

  /// Get user-friendly error message from Firebase Auth exception
  String _getAuthErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email address.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error state
  void _setError(String error) {
    debugPrint('AuthProvider Error: $error');
    // You can add error state management here if needed
  }

  /// Dispose resources
  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool success;
  final String? error;
  final String? errorCode;

  AuthResult._({
    required this.success,
    this.error,
    this.errorCode,
  });

  factory AuthResult.success() => AuthResult._(success: true);

  factory AuthResult.error(String error, [String? errorCode]) => AuthResult._(
        success: false,
        error: error,
        errorCode: errorCode,
      );
}

/// Extension to provide easy access to AuthProvider from BuildContext
extension AuthProviderExtension on BuildContext {
  AuthProvider get auth => Provider.of<AuthProvider>(this, listen: false);
}
