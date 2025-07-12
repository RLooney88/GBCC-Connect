import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'firebase_config_service.dart';

class FirebaseAuthService {
  static FirebaseAuthService? _instance;
  static FirebaseAuthService get instance =>
      _instance ??= FirebaseAuthService._internal();

  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FirebaseConfigService _configService = FirebaseConfigService.instance;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Log analytics event
      await _configService.logEvent(
        name: 'user_login',
        parameters: {
          'method': 'email',
          'user_id': credential.user?.uid,
        },
      );

      // Set user identifier for crashlytics
      if (credential.user?.uid != null) {
        await _configService.crashlytics
            .setUserIdentifier(credential.user!.uid);
      }

      return credential;
    } on FirebaseAuthException catch (e, stackTrace) {
      await _configService.logError(e, stackTrace, reason: 'Sign in failed');
      rethrow;
    }
  }

  /// Sign up with email and password
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user profile
      await credential.user?.updateDisplayName(displayName);

      // Create user document in Firestore
      await _createUserDocument(credential.user!, displayName);

      // Log analytics event
      await _configService.logEvent(
        name: 'user_signup',
        parameters: {
          'method': 'email',
          'user_id': credential.user?.uid,
        },
      );

      return credential;
    } on FirebaseAuthException catch (e, stackTrace) {
      await _configService.logError(e, stackTrace, reason: 'Sign up failed');
      rethrow;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();

      // Clear secure storage
      await _secureStorage.deleteAll();

      // Log analytics event
      await _configService.logEvent(
        name: 'user_logout',
        parameters: {
          'user_id': currentUser?.uid,
        },
      );

      // Clear crashlytics user identifier
      await _configService.crashlytics.setUserIdentifier('');
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace, reason: 'Sign out failed');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);

      // Log analytics event
      await _configService.logEvent(
        name: 'password_reset_requested',
        parameters: {
          'email': email,
        },
      );
    } on FirebaseAuthException catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Password reset failed');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      // Update Firestore document
      await _updateUserDocument(user.uid, {
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log analytics event
      await _configService.logEvent(
        name: 'profile_updated',
        parameters: {
          'user_id': user.uid,
          'has_photo': photoURL != null,
        },
      );
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Profile update failed');
      rethrow;
    }
  }

  /// Delete user account
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      // Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user account
      await user.delete();

      // Clear secure storage
      await _secureStorage.deleteAll();

      // Log analytics event
      await _configService.logEvent(
        name: 'account_deleted',
        parameters: {
          'user_id': user.uid,
        },
      );
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Account deletion failed');
      rethrow;
    }
  }

  /// Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'displayName': displayName,
        'photoURL': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'User document creation failed');
      rethrow;
    }
  }

  /// Update user document in Firestore
  Future<void> _updateUserDocument(
      String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'User document update failed');
      rethrow;
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Get user data failed');
      return null;
    }
  }

  /// Store sensitive data securely
  Future<void> storeSecureData(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Secure storage failed');
      rethrow;
    }
  }

  /// Retrieve sensitive data securely
  Future<String?> getSecureData(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Secure retrieval failed');
      return null;
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get authentication error message
  String getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email address. Please check your email or contact support.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'invalid-email':
        return 'Invalid email address. Please enter a valid email.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This operation is not allowed. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      // Begin interactive sign-in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      if (gUser == null) {
        throw FirebaseAuthException(
          code: 'sign_in_canceled',
          message: 'Sign in was canceled by the user.',
        );
      }

      // Obtain auth details from request
      final GoogleSignInAuthentication gAuth = await gUser.authentication;

      // Create new credential for user
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );

      // Sign in to Firebase with credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Check if user document exists, if not create one
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!userDoc.exists) {
        await _createUserDocument(userCredential.user!,
            userCredential.user!.displayName ?? 'Google User');
      } else {
        // Update last login
        await _updateUserDocument(userCredential.user!.uid, {
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }

      // Log analytics event
      await _configService.logEvent(
        name: 'user_login',
        parameters: {
          'method': 'google',
          'user_id': userCredential.user?.uid,
        },
      );

      // Set user identifier for crashlytics
      if (userCredential.user?.uid != null) {
        await _configService.crashlytics
            .setUserIdentifier(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Google sign in failed');
      rethrow;
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Google sign in failed');
      throw FirebaseAuthException(
        code: 'google_sign_in_failed',
        message: 'Google sign in failed. Please try again.',
      );
    }
  }

  /// Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    try {
      // Check if Apple Sign In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        throw FirebaseAuthException(
          code: 'apple_sign_in_not_available',
          message: 'Apple Sign In is not available on this device.',
        );
      }

      // Begin interactive sign-in process
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuthCredential for Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase with credential
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Check if user document exists, if not create one
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!userDoc.exists) {
        final displayName =
            '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'
                .trim();
        await _createUserDocument(userCredential.user!,
            displayName.isNotEmpty ? displayName : 'Apple User');
      } else {
        // Update last login
        await _updateUserDocument(userCredential.user!.uid, {
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
      }

      // Log analytics event
      await _configService.logEvent(
        name: 'user_login',
        parameters: {
          'method': 'apple',
          'user_id': userCredential.user?.uid,
        },
      );

      // Set user identifier for crashlytics
      if (userCredential.user?.uid != null) {
        await _configService.crashlytics
            .setUserIdentifier(userCredential.user!.uid);
      }

      return userCredential;
    } on FirebaseAuthException catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Apple sign in failed');
      rethrow;
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Apple sign in failed');
      throw FirebaseAuthException(
        code: 'apple_sign_in_failed',
        message: 'Apple sign in failed. Please try again.',
      );
    }
  }
}
