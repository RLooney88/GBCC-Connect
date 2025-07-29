import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/providers/auth_provider.dart';
import '../../app.dart';
import '../../core/routes/app_routes.dart';
import 'package:flutter/foundation.dart';

/// Email verification screen shown after registration
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isCheckingVerification = false;
  String? _errorMessage;
  String? _successMessage;
  Timer? _verificationCheckTimer;
  int _checkCount = 0;
  static const int _maxChecks = 120; // 10 minutes of checking (5 seconds * 120)
  static const int _checkInterval =
      2; // Check every 2 seconds for faster detection

  // Track if listener is added
  bool _listenerAdded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _startVerificationCheck();
    _setupAuthListener();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ensure listener is set up when dependencies change
    if (!_listenerAdded) {
      _setupAuthListener();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _verificationCheckTimer?.cancel();
    _removeAuthListener();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Check for email verification when app resumes
    if (state == AppLifecycleState.resumed) {
      debugPrint(
          'EmailVerificationScreen: App resumed, checking verification status');
      // Force reload user data and check verification status when app resumes
      _forceReloadAndCheck();
    }
  }

  /// Force reload user data and check verification
  Future<void> _forceReloadAndCheck() async {
    try {
      debugPrint('EmailVerificationScreen: Force reloading user data...');
      final authProvider = context.read<AuthProvider>();

      // Force reload user data from Firestore
      await authProvider.forceReloadUserData();

      // Then check verification status
      await _checkEmailVerification();
    } catch (e) {
      debugPrint('EmailVerificationScreen: Error in force reload: $e');
    }
  }

  /// Set up auth provider listener
  void _setupAuthListener() {
    try {
      final authProvider = context.read<AuthProvider>();
      if (!_listenerAdded) {
        authProvider.addListener(_onAuthProviderChanged);
        _listenerAdded = true;
        debugPrint('EmailVerificationScreen: Auth listener added successfully');
      }
    } catch (e) {
      debugPrint('EmailVerificationScreen: Error setting up auth listener: $e');
    }
  }

  /// Remove auth provider listener
  void _removeAuthListener() {
    try {
      final authProvider = context.read<AuthProvider>();
      if (_listenerAdded) {
        authProvider.removeListener(_onAuthProviderChanged);
        _listenerAdded = false;
        debugPrint(
            'EmailVerificationScreen: Auth listener removed successfully');
      }
    } catch (e) {
      debugPrint('EmailVerificationScreen: Error removing auth listener: $e');
    }
  }

  /// Handle auth provider changes
  void _onAuthProviderChanged() {
    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final firebaseUser = authProvider.firebaseUser;

    debugPrint('EmailVerificationScreen: Auth provider changed');
    debugPrint('EmailVerificationScreen: Current user: ${currentUser?.name}');
    debugPrint('EmailVerificationScreen: User status: ${currentUser?.status}');
    debugPrint(
        'EmailVerificationScreen: Firebase email verified: ${firebaseUser?.emailVerified}');

    // Check if user status changed to active
    if (currentUser != null && currentUser.status == 'active') {
      debugPrint('EmailVerificationScreen: User is now active, redirecting...');

      setState(() {
        _successMessage = 'Email verified successfully! Redirecting...';
        _errorMessage = null; // Clear any error messages
      });

      // Stop the timer
      _verificationCheckTimer?.cancel();

      // Navigate to dashboard after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
        }
      });
    }
    // Also check if Firebase email verification status changed but user status hasn't updated yet
    else if (firebaseUser != null &&
        firebaseUser.emailVerified &&
        currentUser != null &&
        currentUser.status != 'active') {
      debugPrint(
          'EmailVerificationScreen: Firebase email verified but user status not updated yet');

      setState(() {
        _successMessage = 'Email verification detected! Updating status...';
      });

      // Force a manual check to update the user status
      _manualCheckVerification();
    }
  }

  /// Start periodic verification check
  void _startVerificationCheck() {
    _verificationCheckTimer =
        Timer.periodic(const Duration(seconds: _checkInterval), (timer) {
      _checkEmailVerification();
    });
  }

  /// Check if email is verified
  Future<void> _checkEmailVerification() async {
    if (_isCheckingVerification) return;

    setState(() {
      _isCheckingVerification = true;
      _checkCount++;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      // Debug: Check current user state
      final currentUser = authProvider.currentUser;
      final firebaseUser = authProvider.firebaseUser;

      debugPrint('Email verification check #$_checkCount:');
      debugPrint(
          '  - Current user: ${currentUser?.name} (${currentUser?.email})');
      debugPrint('  - User status: ${currentUser?.status}');
      debugPrint('  - Firebase user: ${firebaseUser?.uid}');
      debugPrint('  - Firebase email verified: ${firebaseUser?.emailVerified}');

      // First, try to force refresh the Firebase user to get latest verification status
      if (firebaseUser != null) {
        try {
          await firebaseUser.reload();
          debugPrint('  - Firebase user reloaded successfully');
          debugPrint(
              '  - Updated Firebase email verified: ${firebaseUser.emailVerified}');
        } catch (e) {
          debugPrint('  - Error reloading Firebase user: $e');
        }
      }

      // Use the new method that checks and updates verification status
      final isVerified = await authProvider.checkAndUpdateEmailVerification();
      debugPrint('  - checkAndUpdateEmailVerification() result: $isVerified');

      if (isVerified) {
        debugPrint('  - Email is verified and status updated!');

        setState(() {
          _successMessage = 'Email verified successfully! Redirecting...';
          _errorMessage = null; // Clear any error messages
        });

        // Stop the timer
        _verificationCheckTimer?.cancel();

        // Navigate to dashboard after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
          }
        });
      } else {
        // Check if we should stop checking
        if (_checkCount >= _maxChecks) {
          // Stop checking after max attempts
          _verificationCheckTimer?.cancel();
          setState(() {
            _errorMessage =
                'Automatic verification check stopped. Please use the manual check button or resend the verification email.';
          });
        } else {
          // Continue checking, but show progress
          debugPrint('  - Email not verified yet, continuing to check...');
        }
      }
    } catch (e) {
      debugPrint('Error checking email verification: $e');
      setState(() {
        _errorMessage = 'Error checking verification status. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingVerification = false;
        });
      }
    }
  }

  /// Manual verification check
  Future<void> _manualCheckVerification() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      debugPrint('EmailVerificationScreen: Manual verification check started');

      final authProvider = context.read<AuthProvider>();

      // Get real-time verification status
      final status = await authProvider.getRealTimeVerificationStatus();

      debugPrint('EmailVerificationScreen: Real-time status: $status');

      if (status['error'] != null) {
        setState(() {
          _errorMessage = 'Error: ${status['error']}';
        });
        return;
      }

      final isVerified = status['isVerified'] as bool;
      final firebaseVerified = status['firebaseVerified'] as bool;
      final userStatus = status['userStatus'] as String?;

      if (isVerified) {
        setState(() {
          _successMessage = 'Email verified successfully! Redirecting...';
        });

        // Stop the timer
        _verificationCheckTimer?.cancel();

        // Navigate to dashboard after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
          }
        });
      } else if (firebaseVerified && userStatus != 'active') {
        // Firebase says verified but user status not updated - force update
        debugPrint(
            'EmailVerificationScreen: Firebase verified but user status not active, forcing update');

        setState(() {
          _successMessage = 'Email verification detected! Updating status...';
        });

        // Force refresh and check verification
        final forceVerified =
            await authProvider.forceRefreshAndCheckVerification();

        if (forceVerified) {
          setState(() {
            _successMessage = 'Email verified successfully! Redirecting...';
          });

          // Stop the timer
          _verificationCheckTimer?.cancel();

          // Navigate to dashboard after a short delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
            }
          });
        } else {
          setState(() {
            _successMessage =
                'Email verification detected but status update failed. Please try again.';
          });
        }
      } else {
        setState(() {
          _successMessage =
              'Email not verified yet. Please check your email and click the verification link.';
        });
      }
    } catch (e) {
      debugPrint('Error in manual verification check: $e');
      setState(() {
        _errorMessage = 'Error checking verification status. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Resend verification email
  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await context.read<AuthProvider>().sendEmailVerification();

      if (result.success) {
        setState(() {
          _successMessage = 'Verification email sent successfully!';
        });

        // Restart automatic checking
        _verificationCheckTimer?.cancel();
        _checkCount = 0;
        _startVerificationCheck();

        debugPrint('Email verification resend: Restarted automatic checking');
      } else {
        setState(() {
          _errorMessage = result.error;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _navigateToLogin,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Main content
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Email icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: MyApp.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Icon(
                          Icons.email_outlined,
                          size: 40,
                          color: MyApp.primaryColor,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Title
                      Text(
                        'Verify Your Email',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Description
                      Text(
                        'We\'ve sent a verification email to your inbox. Please check your email and click the verification link to activate your account.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Resend button
                      ElevatedButton(
                        onPressed: _isLoading ? null : _resendVerificationEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MyApp.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      MyApp.primaryColor),
                                ),
                              )
                            : const Text(
                                'Resend Email',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),

                      const SizedBox(height: 12),

                      // Auto-check status
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Automatically checking for verification every $_checkInterval seconds... (Check #$_checkCount/$_maxChecks)',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Success message
                      if (_successMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _successMessage!,
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Error message
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red[700],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
                // Additional info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Didn\'t receive the email?',
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '• Check your spam/junk folder\n• Make sure you entered the correct email\n• Click the verification link in your email\n• Return to this app after clicking the link\n• The app will automatically detect verification when you return to it',
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Back to login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already verified? ',
                      style: TextStyle(
                        color: Colors.grey[600],
                      ),
                    ),
                    TextButton(
                      onPressed: _navigateToLogin,
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: MyApp.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
