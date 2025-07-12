import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseConfigService {
  static FirebaseConfigService? _instance;
  static FirebaseConfigService get instance =>
      _instance ??= FirebaseConfigService._internal();

  FirebaseConfigService._internal();

  late FirebaseAnalytics _analytics;
  late FirebaseCrashlytics _crashlytics;
  late FirebasePerformance _performance;
  late FirebaseRemoteConfig _remoteConfig;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseCrashlytics get crashlytics => _crashlytics;
  FirebasePerformance get performance => _performance;
  FirebaseRemoteConfig get remoteConfig => _remoteConfig;

  /// Initialize Firebase with proper configuration
  Future<void> initialize() async {
    try {
      // Check if Firebase is already initialized
      if (Firebase.apps.isNotEmpty) {
        debugPrint('Firebase is already initialized, skipping initialization');
        return;
      }

      // Load environment variables
      await dotenv.load(fileName: ".env");

      // Check if required Firebase configuration is available
      final apiKey = dotenv.env['FIREBASE_API_KEY'];
      final appId = dotenv.env['FIREBASE_APP_ID'];
      final projectId = dotenv.env['FIREBASE_PROJECT_ID'];

      if (apiKey == null || appId == null || projectId == null) {
        throw Exception(
            'Firebase configuration is missing. Please ensure you have:\n'
            '1. Created a .env file with your Firebase configuration\n'
            '2. Added google-services.json to android/app/\n'
            '3. Added GoogleService-Info.plist to ios/Runner/\n'
            'Required environment variables: FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_PROJECT_ID');
      }

      // Initialize Firebase Core
      await Firebase.initializeApp(
        options: _getFirebaseOptions(),
      );

      // Initialize Firebase services
      await _initializeAnalytics();
      await _initializeCrashlytics();
      await _initializePerformance();
      await _initializeRemoteConfig();

      debugPrint('Firebase initialized successfully');
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      if (kDebugMode) {
        rethrow;
      }
    }
  }

  /// Get Firebase options based on platform
  FirebaseOptions _getFirebaseOptions() {
    // Get required configuration values
    final apiKey = dotenv.env['FIREBASE_API_KEY'];
    final appId = dotenv.env['FIREBASE_APP_ID'];
    final messagingSenderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'];
    final projectId = dotenv.env['FIREBASE_PROJECT_ID'];
    final storageBucket = dotenv.env['FIREBASE_STORAGE_BUCKET'];
    final authDomain = dotenv.env['FIREBASE_AUTH_DOMAIN'];
    final measurementId = dotenv.env['FIREBASE_MEASUREMENT_ID'];

    // Validate required fields
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('FIREBASE_API_KEY is missing or empty in .env file');
    }
    if (appId == null || appId.isEmpty) {
      throw Exception('FIREBASE_APP_ID is missing or empty in .env file');
    }
    if (projectId == null || projectId.isEmpty) {
      throw Exception('FIREBASE_PROJECT_ID is missing or empty in .env file');
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId ?? '',
      projectId: projectId,
      storageBucket: storageBucket ?? '$projectId.appspot.com',
      authDomain: authDomain ?? '$projectId.firebaseapp.com',
      measurementId: measurementId ?? '',
    );
  }

  /// Initialize Firebase Analytics
  Future<void> _initializeAnalytics() async {
    if (dotenv.env['ENABLE_ANALYTICS'] == 'true') {
      _analytics = FirebaseAnalytics.instance;

      // Set user properties
      await _analytics.setUserProperty(name: 'app_version', value: '1.0.0');
      await _analytics.setUserProperty(
          name: 'environment', value: dotenv.env['ENVIRONMENT']);

      debugPrint('Firebase Analytics initialized');
    }
  }

  /// Initialize Firebase Crashlytics
  Future<void> _initializeCrashlytics() async {
    if (dotenv.env['ENABLE_CRASHLYTICS'] == 'true') {
      _crashlytics = FirebaseCrashlytics.instance;

      // Enable Crashlytics collection
      await _crashlytics.setCrashlyticsCollectionEnabled(true);

      // Set user identifier when available
      // await _crashlytics.setUserIdentifier('user-id');

      debugPrint('Firebase Crashlytics initialized');
    }
  }

  /// Initialize Firebase Performance
  Future<void> _initializePerformance() async {
    if (dotenv.env['ENABLE_PERFORMANCE'] == 'true') {
      _performance = FirebasePerformance.instance;

      // Enable performance collection
      await _performance.setPerformanceCollectionEnabled(true);

      debugPrint('Firebase Performance initialized');
    }
  }

  /// Initialize Firebase Remote Config
  Future<void> _initializeRemoteConfig() async {
    _remoteConfig = FirebaseRemoteConfig.instance;

    // Set minimum fetch interval
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Set default values
    await _remoteConfig.setDefaults(const {
      'welcome_message': 'Welcome to GBCC Connect!',
      'feature_flags': '{}',
      'app_config': '{}',
    });

    // Fetch and activate config
    try {
      await _remoteConfig.fetchAndActivate();
      debugPrint('Firebase Remote Config initialized');
    } catch (e) {
      debugPrint('Error fetching remote config: $e');
    }
  }

  /// Log custom event to Analytics
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters as Map<String, Object>?,
      );
    } catch (e) {
      debugPrint('Error logging analytics event: $e');
    }
  }

  /// Log error to Crashlytics
  Future<void> logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? reason,
  }) async {
    try {
      await _crashlytics.recordError(
        error,
        stackTrace,
        reason: reason,
      );
    } catch (e) {
      debugPrint('Error logging to Crashlytics: $e');
    }
  }

  /// Get remote config value
  String getRemoteConfigValue(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      debugPrint('Error getting remote config value: $e');
      return '';
    }
  }

  /// Get remote config value as boolean
  bool getRemoteConfigBool(String key) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      debugPrint('Error getting remote config bool: $e');
      return false;
    }
  }

  /// Get remote config value as int
  int getRemoteConfigInt(String key) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      debugPrint('Error getting remote config int: $e');
      return 0;
    }
  }

  /// Get remote config value as double
  double getRemoteConfigDouble(String key) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      debugPrint('Error getting remote config double: $e');
      return 0.0;
    }
  }
}
