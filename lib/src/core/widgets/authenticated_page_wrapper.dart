import 'package:flutter/material.dart';
import 'package:gbcc_connect_app/src/app.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/firebase_provider.dart';
import '../services/service_manager.dart';
import '../models/user.dart';
import '../routes/app_routes.dart';

/// AuthenticatedPageWrapper
///
/// A reusable wrapper that provides authentication protection and service initialization
/// for pages that require user authentication. This wrapper:
///
/// - Checks authentication status using AuthProvider
/// - Redirects to login page if user is not authenticated
/// - Initializes ServiceManager using FirebaseProvider
/// - Provides authenticated User and ServiceManager to child pages
///
/// Usage:
/// ```dart
/// AuthenticatedPageWrapper(
///   child: (context, user, serviceManager) => YourPage(
///     user: user,
///     serviceManager: serviceManager,
///   ),
/// )
/// ```
class AuthenticatedPageWrapper extends StatefulWidget {
  final Widget Function(
      BuildContext context, User user, ServiceManager serviceManager) child;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final String? redirectRoute;

  const AuthenticatedPageWrapper({
    super.key,
    required this.child,
    this.loadingWidget,
    this.errorWidget,
    this.redirectRoute,
  });

  @override
  State<AuthenticatedPageWrapper> createState() =>
      _AuthenticatedPageWrapperState();
}

class _AuthenticatedPageWrapperState extends State<AuthenticatedPageWrapper> {
  ServiceManager? _serviceManager;
  bool _isInitializing = true;
  bool _hasAttemptedInitialization = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Don't initialize here, wait for the first build
  }

  /// Initialize ServiceManager and FirebaseProvider
  Future<void> _initializeServices(BuildContext context) async {
    if (_hasAttemptedInitialization) return;

    try {
      setState(() {
        _isInitializing = true;
        _error = null;
        _hasAttemptedInitialization = true;
      });

      // Get the existing FirebaseProvider instance from Provider
      final firebaseProvider = context.read<FirebaseProvider>();

      // Initialize ServiceManager with the existing FirebaseProvider
      _serviceManager = ServiceManager.instance;
      await _serviceManager!.initialize(firebaseProvider);

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      debugPrint('AuthenticatedPageWrapper: Service initialization error: $e');
      setState(() {
        _isInitializing = false;
        _error = 'Failed to initialize services: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Initialize services on first build if not already done
        if (!_hasAttemptedInitialization) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeServices(context);
          });
        }

        // Check if auth provider is still initializing
        if (authProvider.isLoading || _isInitializing) {
          return widget.loadingWidget ?? _buildDefaultLoadingWidget();
        }

        // Check if there's an error
        if (_error != null) {
          return widget.errorWidget ?? _buildDefaultErrorWidget();
        }

        // Check if user is authenticated
        final currentUser = authProvider.currentUser;
        if (currentUser == null) {
          // Redirect to login page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _redirectToLogin();
          });
          return widget.loadingWidget ?? _buildDefaultLoadingWidget();
        }

        // Check if ServiceManager is ready
        if (_serviceManager == null || !_serviceManager!.isInitialized) {
          return widget.loadingWidget ?? _buildDefaultLoadingWidget();
        }

        // User is authenticated and services are ready
        return widget.child(context, currentUser, _serviceManager!);
      },
    );
  }

  /// Redirect to login page
  void _redirectToLogin() {
    final route = widget.redirectRoute ?? AppRoutes.login;

    // Use Navigator to push and replace the current route
    Navigator.of(context).pushNamedAndRemoveUntil(
      route,
      (route) => false, // Remove all previous routes
    );
  }

  /// Default loading widget
  Widget _buildDefaultLoadingWidget() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: MyApp.primaryColor,
            ),
            SizedBox(height: 16),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }

  /// Default error widget
  Widget _buildDefaultErrorWidget() {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initializeServices(context),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension to provide easy access to authenticated user and services
extension AuthenticatedPageExtension on BuildContext {
  /// Get the authenticated user from the nearest AuthenticatedPageWrapper
  User? get authenticatedUser {
    final authProvider = read<AuthProvider>();
    return authProvider.currentUser;
  }

  /// Get the ServiceManager from the nearest AuthenticatedPageWrapper
  ServiceManager? get serviceManager {
    try {
      return ServiceManager.instance;
    } catch (e) {
      return null;
    }
  }
}
