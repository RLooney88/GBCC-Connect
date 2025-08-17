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
  StreamSubscription<firebase_auth.User?>? _userChangesSubscription;
  bool _isHandlingRegistration =
      false; // Flag to prevent auto-update during registration

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
    _userChangesSubscription?.cancel();

    // Listen to auth state changes (sign in/out)
    _authStateSubscription = _auth.authStateChanges().listen(
      (firebaseUser) async {
        debugPrint(
            'AuthProvider: Auth state changed - user: ${firebaseUser?.uid}');

        if (firebaseUser != null) {
          _firebaseUser = firebaseUser;
          await loadCurrentUser();

          // Set up user changes listener for this user
          _listenToUserChanges(firebaseUser);
        } else {
          _firebaseUser = null;
          _currentUser = null;
          _userChangesSubscription?.cancel();
        }

        notifyListeners();
      },
      onError: (error) {
        debugPrint('AuthProvider: Auth state listener error: $error');
        _setError('Authentication state error: $error');
      },
    );
  }

  /// Listen to user metadata changes (including email verification)
  void _listenToUserChanges(firebase_auth.User user) {
    _userChangesSubscription?.cancel();

    _userChangesSubscription = _auth.userChanges().listen(
      (firebase_auth.User? user) async {
        if (user != null) {
          debugPrint('AuthProvider: User metadata changed - user: ${user.uid}');
          debugPrint('AuthProvider: Email verified: ${user.emailVerified}');
          debugPrint(
              'AuthProvider: Handling registration: $_isHandlingRegistration');
          debugPrint(
              'AuthProvider: Current user status: ${_currentUser?.status}');

          // Update the current user reference
          _firebaseUser = user;

          // If email was just verified, update user status
          // But only if we're not in the middle of handling registration
          if (user.emailVerified &&
              _currentUser != null &&
              _currentUser!.status != 'active' &&
              !_isHandlingRegistration) {
            debugPrint(
                'AuthProvider: Email verified, updating user status to active');

            try {
              await updateUserStatusToActive();
              debugPrint(
                  'AuthProvider: User status updated to active successfully via real-time detection');

              // Force reload user data to ensure consistency
              await loadCurrentUser();

              // Notify listeners of the status change
              notifyListeners();
            } catch (e) {
              debugPrint(
                  'AuthProvider: Error updating user status via real-time detection: $e');
            }
          }

          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint('AuthProvider: User changes listener error: $error');
        // Attempt to restart the listener after a delay
        Future.delayed(const Duration(seconds: 5), () {
          if (_firebaseUser != null && _auth.currentUser != null) {
            debugPrint(
                'AuthProvider: Restarting user changes listener after error');
            _listenToUserChanges(_firebaseUser!);
          }
        });
      },
    );
  }

  /// Check current authentication status on app start
  Future<void> _checkCurrentAuthStatus() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      _firebaseUser = firebaseUser;
      await loadCurrentUser();

      // Set up user changes listener for existing user
      _listenToUserChanges(firebaseUser);
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
        status: 'active', // Default to active for social auth
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

        // Check if email is verified for email/password users
        if (!credential.user!.emailVerified) {
          // Sign out the user since they're not verified
          await _auth.signOut();
          _firebaseUser = null;
          _currentUser = null;
          return AuthResult.error(
              'Please verify your email before signing in. Check your inbox for a verification email.');
        }

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
      _isHandlingRegistration = true; // Set flag to prevent auto-update

      debugPrint('AuthProvider: Starting registration for email: $email');

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        debugPrint(
            'AuthProvider: User created successfully with ID: ${credential.user!.uid}');

        // Update display name
        await credential.user!.updateDisplayName(displayName);
        debugPrint('AuthProvider: Display name updated to: $displayName');

        // Send email verification
        debugPrint('AuthProvider: Sending email verification...');
        await credential.user!.sendEmailVerification();
        debugPrint('AuthProvider: Email verification sent successfully');
        debugPrint(
            'AuthProvider: Please check spam/junk folder if email not received');

        // Create user document with inactive status
        _firebaseUser = credential.user;
        await _createUserDocumentWithStatus(displayName, 'inactive');

        // Log analytics
        await _configService.logEvent(
          name: 'user_signup',
          parameters: {
            'method': 'email',
            'user_id': credential.user!.uid,
          },
        );

        debugPrint('AuthProvider: Registration completed successfully');
        return AuthResult.success();
      }

      return AuthResult.error('Registration failed');
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AuthProvider: Email registration error: ${e.code} - ${e.message}');

      // Handle existing user case
      if (e.code == 'email-already-in-use') {
        return await _handleExistingUser(email, password, displayName);
      }

      return AuthResult.error(_getAuthErrorMessage(e));
    } finally {
      _setLoading(false);
      _isHandlingRegistration = false; // Clear flag
    }
  }

  /// Handle existing user during registration
  Future<AuthResult> _handleExistingUser(
      String email, String password, String displayName) async {
    try {
      _isHandlingRegistration = true; // Set flag to prevent auto-update
      debugPrint('AuthProvider: Handling existing user for email: $email');

      // Try to sign in to get the user ID
      final signInResult = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (signInResult.user != null) {
        final userId = signInResult.user!.uid;

        // Check user status in Firestore
        final userDoc = await _firestore.collection('users').doc(userId).get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final userStatus = userData['status'] as String? ?? 'active';

          debugPrint('AuthProvider: Existing user status: $userStatus');

          if (userStatus == 'inactive') {
            // User exists but is inactive - continue with email verification
            debugPrint(
                'AuthProvider: Existing inactive user - continuing verification');

            // Update display name if different
            if (signInResult.user!.displayName != displayName) {
              await signInResult.user!.updateDisplayName(displayName);
            }

            // Send verification email if not already verified
            if (!signInResult.user!.emailVerified) {
              await signInResult.user!.sendEmailVerification();
              debugPrint(
                  'AuthProvider: Verification email sent to existing user');
            }

            // Set current user
            _firebaseUser = signInResult.user;
            _currentUser = User.fromJson({
              'id': userDoc.id,
              ...userData,
            });

            return AuthResult.success();
          } else if (userStatus == 'active') {
            // User exists and is active - sign out and show message
            await _auth.signOut();
            return AuthResult.error(
                'An account with this email already exists and is verified. Please sign in instead.',
                'user-already-active');
          }
        } else {
          // User exists in Firebase Auth but not in Firestore - create document
          debugPrint(
              'AuthProvider: User exists in Auth but not Firestore - creating document');

          // Update display name
          await signInResult.user!.updateDisplayName(displayName);

          // Send verification email
          await signInResult.user!.sendEmailVerification();

          // Create user document with inactive status
          _firebaseUser = signInResult.user;
          await _createUserDocumentWithStatus(displayName, 'inactive');

          return AuthResult.success();
        }
      }

      // If we can't sign in, the password is wrong
      return AuthResult.error(
          'An account with this email already exists. Please use the correct password to sign in.',
          'wrong-password-for-existing-user');
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AuthProvider: Error handling existing user: ${e.code} - ${e.message}');

      if (e.code == 'wrong-password') {
        return AuthResult.error(
            'An account with this email already exists. Please use the correct password to sign in.',
            'wrong-password-for-existing-user');
      }

      return AuthResult.error(_getAuthErrorMessage(e));
    } catch (e) {
      debugPrint('AuthProvider: Unexpected error handling existing user: $e');
      return AuthResult.error(
          'An unexpected error occurred. Please try again.');
    } finally {
      _isHandlingRegistration = false; // Clear flag
    }
  }

  /// Create user document with specific status
  Future<void> _createUserDocumentWithStatus(
      String displayName, String status) async {
    if (_firebaseUser == null) return;

    try {
      final newUser = User(
        id: _firebaseUser!.uid,
        name: displayName,
        email: _firebaseUser!.email ?? '',
        phone: _firebaseUser!.phoneNumber,
        status: status,
      );

      await _firestore
          .collection('users')
          .doc(_firebaseUser!.uid)
          .set(newUser.toJson());

      _currentUser = newUser;
      debugPrint('AuthProvider: User document created with status: $status');
    } catch (e) {
      debugPrint('AuthProvider: Error creating user document: $e');
      _setError('Failed to create user profile');
    }
  }

  /// Send email verification
  Future<AuthResult> sendEmailVerification() async {
    try {
      _setLoading(true);

      if (_firebaseUser == null) {
        debugPrint('AuthProvider: No user signed in for email verification');
        return AuthResult.error('No user is currently signed in');
      }

      debugPrint(
          'AuthProvider: Sending verification email to: ${_firebaseUser!.email}');
      debugPrint('AuthProvider: User ID: ${_firebaseUser!.uid}');
      debugPrint(
          'AuthProvider: Email verified status: ${_firebaseUser!.emailVerified}');

      await _firebaseUser!.sendEmailVerification();

      debugPrint('AuthProvider: Verification email sent successfully');
      debugPrint(
          'AuthProvider: Please check spam/junk folder if email not received');

      return AuthResult.success();
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AuthProvider: Email verification error: ${e.code} - ${e.message}');

      // Handle specific Firebase Auth errors
      switch (e.code) {
        case 'user-not-found':
          return AuthResult.error('User not found. Please sign in again.');
        case 'too-many-requests':
          return AuthResult.error(
              'Too many verification requests. Please wait before trying again.');
        case 'network-request-failed':
          return AuthResult.error(
              'Network error. Please check your internet connection.');
        default:
          return AuthResult.error(_getAuthErrorMessage(e));
      }
    } catch (e) {
      debugPrint(
          'AuthProvider: Unexpected error during email verification: $e');
      return AuthResult.error(
          'An unexpected error occurred. Please try again.');
    } finally {
      _setLoading(false);
    }
  }

  /// Debug method to check current user state
  void debugUserState() {
    final user = _auth.currentUser;
    if (user != null) {
      debugPrint('=== DEBUG USER STATE ===');
      debugPrint('User ID: ${user.uid}');
      debugPrint('Email: ${user.email}');
      debugPrint('Email Verified: ${user.emailVerified}');
      debugPrint('Display Name: ${user.displayName}');
      debugPrint('Phone: ${user.phoneNumber}');
      debugPrint(
          'Provider ID: ${user.providerData.map((p) => p.providerId).join(', ')}');
      debugPrint('Creation Time: ${user.metadata.creationTime}');
      debugPrint('Last Sign In: ${user.metadata.lastSignInTime}');
      debugPrint('=======================');
    } else {
      debugPrint('=== DEBUG USER STATE ===');
      debugPrint('No user currently signed in');
      debugPrint('=======================');
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    if (_firebaseUser == null) {
      debugPrint('AuthProvider: isEmailVerified - No Firebase user');
      return false;
    }

    debugPrint(
        'AuthProvider: isEmailVerified - Before reload: ${_firebaseUser!.emailVerified}');

    // Reload user to get latest verification status
    await _firebaseUser!.reload();

    final isVerified = _firebaseUser!.emailVerified;
    debugPrint('AuthProvider: isEmailVerified - After reload: $isVerified');

    return isVerified;
  }

  /// Update user status to active after email verification
  Future<void> updateUserStatusToActive() async {
    if (_firebaseUser == null || _currentUser == null) {
      debugPrint('AuthProvider: updateUserStatusToActive - Missing user data');
      debugPrint('  - Firebase user: ${_firebaseUser?.uid}');
      debugPrint('  - Current user: ${_currentUser?.name}');
      return;
    }

    try {
      debugPrint(
          'AuthProvider: updateUserStatusToActive - Current status: ${_currentUser!.status}');

      // Only update if status is not already active
      if (_currentUser!.status == 'active') {
        debugPrint(
            'AuthProvider: User status is already active, skipping update');
        return;
      }

      final updatedUser = _currentUser!.copyWith(status: 'active');
      await updateUser(updatedUser);

      debugPrint('AuthProvider: User status updated to active successfully');

      // Ensure listeners are notified of the status change
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: Error updating user status: $e');
      _setError('Failed to update user status');
    }
  }

  /// Check and update email verification status manually
  /// This should be called when the user returns to the app after clicking verification link
  Future<bool> checkAndUpdateEmailVerification() async {
    if (_firebaseUser == null) {
      debugPrint(
          'AuthProvider: checkAndUpdateEmailVerification - No Firebase user');
      return false;
    }

    try {
      debugPrint(
          'AuthProvider: checkAndUpdateEmailVerification - Starting check');

      // Reload the user to get the latest verification status
      await _firebaseUser!.reload();

      final isVerified = _firebaseUser!.emailVerified;
      debugPrint(
          'AuthProvider: checkAndUpdateEmailVerification - Email verified: $isVerified');

      if (isVerified &&
          _currentUser != null &&
          _currentUser!.status != 'active') {
        debugPrint(
            'AuthProvider: checkAndUpdateEmailVerification - Updating status to active');
        await updateUserStatusToActive();
        return true;
      }

      return isVerified;
    } catch (e) {
      debugPrint('AuthProvider: checkAndUpdateEmailVerification - Error: $e');
      return false;
    }
  }

  /// Force refresh Firebase user and check verification status
  /// This is useful when the app resumes after user clicks verification link
  Future<bool> forceRefreshAndCheckVerification() async {
    if (_firebaseUser == null) {
      debugPrint(
          'AuthProvider: forceRefreshAndCheckVerification - No Firebase user');
      return false;
    }

    try {
      debugPrint(
          'AuthProvider: forceRefreshAndCheckVerification - Force refreshing user');

      // Force reload the Firebase user to get latest verification status
      await _firebaseUser!.reload();

      final isVerified = _firebaseUser!.emailVerified;
      debugPrint(
          'AuthProvider: forceRefreshAndCheckVerification - Email verified: $isVerified');

      if (isVerified &&
          _currentUser != null &&
          _currentUser!.status != 'active') {
        debugPrint(
            'AuthProvider: forceRefreshAndCheckVerification - Updating status to active');
        await updateUserStatusToActive();
        notifyListeners(); // Notify listeners of the status change
        return true;
      }

      return isVerified;
    } catch (e) {
      debugPrint('AuthProvider: forceRefreshAndCheckVerification - Error: $e');
      return false;
    }
  }

  /// Force reload user data from Firestore
  /// This ensures we have the latest user status from the database
  Future<void> forceReloadUserData() async {
    if (_firebaseUser == null) {
      debugPrint('AuthProvider: forceReloadUserData - No Firebase user');
      return;
    }

    try {
      debugPrint(
          'AuthProvider: forceReloadUserData - Force reloading user data from Firestore');

      // Force reload the Firebase user
      await _firebaseUser!.reload();

      // Reload user data from Firestore
      await loadCurrentUser();

      debugPrint(
          'AuthProvider: forceReloadUserData - User data reloaded successfully');
      debugPrint(
          '  - Firebase email verified: ${_firebaseUser!.emailVerified}');
      debugPrint('  - User status: ${_currentUser?.status}');

      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider: forceReloadUserData - Error: $e');
    }
  }

  /// Real-time email verification status check
  /// This method provides immediate feedback about verification status
  Future<Map<String, dynamic>> getRealTimeVerificationStatus() async {
    if (_firebaseUser == null) {
      return {
        'isVerified': false,
        'firebaseVerified': false,
        'userStatus': null,
        'error': 'No Firebase user found'
      };
    }

    try {
      // Force reload the Firebase user to get latest verification status
      await _firebaseUser!.reload();

      final firebaseVerified = _firebaseUser!.emailVerified;
      final userStatus = _currentUser?.status;
      final isVerified = firebaseVerified && userStatus == 'active';

      debugPrint('AuthProvider: Real-time verification status:');
      debugPrint('  - Firebase verified: $firebaseVerified');
      debugPrint('  - User status: $userStatus');
      debugPrint('  - Is verified: $isVerified');

      return {
        'isVerified': isVerified,
        'firebaseVerified': firebaseVerified,
        'userStatus': userStatus,
        'error': null
      };
    } catch (e) {
      debugPrint(
          'AuthProvider: Error getting real-time verification status: $e');
      return {
        'isVerified': false,
        'firebaseVerified': false,
        'userStatus': _currentUser?.status,
        'error': 'Error checking verification status: $e'
      };
    }
  }

  /// Force update user status to active (for manual verification)
  Future<bool> forceUpdateUserStatusToActive() async {
    if (_firebaseUser == null || _currentUser == null) {
      debugPrint(
          'AuthProvider: forceUpdateUserStatusToActive - Missing user data');
      return false;
    }

    try {
      debugPrint(
          'AuthProvider: forceUpdateUserStatusToActive - Forcing status update');
      await updateUserStatusToActive();
      return true;
    } catch (e) {
      debugPrint('AuthProvider: forceUpdateUserStatusToActive - Error: $e');
      return false;
    }
  }

  /// Send password reset email
  Future<AuthResult> forgotPassword(String email) async {
    try {
      _setLoading(true);

      await _auth.sendPasswordResetEmail(email: email);

      // Log analytics event
      await _configService.logEvent(
        name: 'password_reset_requested',
        parameters: {
          'email': email,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      debugPrint(
          'AuthProvider: Password reset email sent successfully to: $email');
      return AuthResult.success();
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint(
          'AuthProvider: Password reset error: ${e.code} - ${e.message}');

      // Log analytics event for failed password reset
      await _configService.logEvent(
        name: 'password_reset_failed',
        parameters: {
          'email': email,
          'error_code': e.code,
          'error_message': e.message ?? 'Unknown error',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

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
      // Password reset specific errors
      case 'missing-email':
        return 'Please enter your email address.';
      case 'invalid-action-code':
        return 'The password reset link is invalid or has expired. Please request a new one.';
      case 'expired-action-code':
        return 'The password reset link has expired. Please request a new one.';
      case 'user-mismatch':
        return 'The password reset link is for a different account.';
      case 'weak-password':
        return 'The new password is too weak. Please choose a stronger password.';
      case 'requires-recent-login':
        return 'For security reasons, please sign in again before changing your password.';
      default:
        return e.message ?? 'An error occurred. Please try again.';
    }
  }

  /// Get user-friendly error message for custom error codes
  String _getCustomErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-already-active':
        return 'An account with this email already exists and is verified. Please sign in instead.';
      case 'wrong-password-for-existing-user':
        return 'An account with this email already exists. Please use the correct password to sign in.';
      default:
        return 'An error occurred. Please try again.';
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
    _userChangesSubscription?.cancel();
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
