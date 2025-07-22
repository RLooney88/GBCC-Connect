import 'package:flutter/material.dart';
import 'package:gbcc_connect_app/src/core/constants/constants.dart';
import '../providers/auth_provider.dart';
import '../../app.dart';

/// Splash screen that handles initial authentication state
class AuthSplashScreen extends StatefulWidget {
  const AuthSplashScreen({super.key});

  @override
  State<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      // Initialize the auth provider
      await AuthProvider.instance.initialize();

      // Navigate based on auth state
      _navigateBasedOnAuthState();
    } catch (e) {
      debugPrint('AuthSplashScreen: Initialization error: $e');
      // On error, go to login
      _navigateToLogin();
    }
  }

  void _navigateBasedOnAuthState() {
    final authProvider = AuthProvider.instance;

    if (authProvider.isAuthenticated) {
      _navigateToDashboard();
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToDashboard() {
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyApp.primaryColor,
      body: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo or icon
                Icon(
                  Icons.connect_without_contact,
                  size: 80,
                  color: Colors.white,
                ),
                SizedBox(height: 24),
                // App name
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 48),
                // Loading indicator
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 24),
                // Loading text
                Text(
                  'Initializing...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // App version at top-right
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: Text(
              'v${AppConstants.appVersion}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
