import 'package:flutter/foundation.dart';
import 'firebase_config_service.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';
import 'user_service.dart';
import 'contact_service.dart';
import 'message_service.dart';
import 'conversation_service.dart';

/// Central service manager that provides access to all Firebase services
class ServiceManager {
  static ServiceManager? _instance;
  static ServiceManager get instance =>
      _instance ??= ServiceManager._internal();

  ServiceManager._internal();

  // Firebase services
  late final FirebaseConfigService _configService;
  late final FirebaseAuthService _authService;
  late final FirestoreService _firestoreService;
  late final UserService _userService;
  late final ContactService _contactService;
  late final MessageService _messageService;
  late final ConversationService _conversationService;

  // Track initialization status
  bool _isInitialized = false;

  /// Initialize all services
  Future<void> initialize() async {
    // Prevent multiple initializations
    if (_isInitialized) {
      debugPrint(
          'ServiceManager is already initialized, skipping initialization');
      return;
    }

    try {
      // Initialize Firebase configuration first
      _configService = FirebaseConfigService.instance;
      await _configService.initialize();

      // Initialize other services
      _authService = FirebaseAuthService.instance;
      _firestoreService = FirestoreService.instance;
      _userService = UserService.instance;
      _contactService = ContactService.instance;
      _messageService = MessageService.instance;
      _conversationService = ConversationService.instance;

      // Enable offline persistence for Firestore
      await _firestoreService.enableOfflinePersistence();

      // Mark as initialized
      _isInitialized = true;

      // Log initialization success
      await _configService.logEvent(
        name: 'services_initialized',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Service initialization failed');
      rethrow;
    }
  }

  /// Get Firebase configuration service
  FirebaseConfigService get config => _configService;

  /// Get Firebase authentication service
  FirebaseAuthService get auth => _authService;

  /// Get Firestore service
  FirestoreService get firestore => _firestoreService;

  /// Get user service
  UserService get users => _userService;

  /// Get contact service
  ContactService get contacts => _contactService;

  /// Get message service
  MessageService get messages => _messageService;

  /// Get conversation service
  ConversationService get conversations => _conversationService;

  /// Check if services are initialized
  bool get isInitialized => _isInitialized;

  /// Dispose all services (useful for testing)
  Future<void> dispose() async {
    try {
      // Clear Firestore cache
      await _firestoreService.clearOfflineCache();

      // Reset initialization flag
      _isInitialized = false;

      // Log disposal
      await _configService.logEvent(
        name: 'services_disposed',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Service disposal failed');
    }
  }

  /// Get service health status
  Future<Map<String, bool>> getHealthStatus() async {
    try {
      final status = <String, bool>{};

      // Check each service
      status['config'] = _configService != null;
      status['auth'] = _authService != null;
      status['firestore'] = _firestoreService != null;
      status['users'] = _userService != null;
      status['contacts'] = _contactService != null;
      status['messages'] = _messageService != null;
      status['conversations'] = _conversationService != null;

      return status;
    } catch (e) {
      return <String, bool>{
        'config': false,
        'auth': false,
        'firestore': false,
        'users': false,
        'contacts': false,
        'messages': false,
        'conversations': false,
      };
    }
  }

  /// Get service statistics
  Future<Map<String, dynamic>> getServiceStats() async {
    try {
      final stats = <String, dynamic>{};

      // Get user stats if authenticated
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        try {
          stats['userStats'] =
              await _userService.getUserById(currentUser.uid) != null
                  ? 'User found'
                  : 'User not found';
        } catch (e) {
          stats['userStats'] = 'Error: $e';
        }

        try {
          final contactStats =
              await _contactService.getContactStats(currentUser.uid);
          stats['contactStats'] = contactStats;
        } catch (e) {
          stats['contactStats'] = 'Error: $e';
        }

        try {
          final messageStats =
              await _messageService.getMessageStats(currentUser.uid);
          stats['messageStats'] = messageStats;
        } catch (e) {
          stats['messageStats'] = 'Error: $e';
        }

        try {
          final conversationStats =
              await _conversationService.getConversationStats(currentUser.uid);
          stats['conversationStats'] = conversationStats;
        } catch (e) {
          stats['conversationStats'] = 'Error: $e';
        }
      }

      // Get Firestore stats
      stats['firestore'] = {
        'offlineEnabled':
            _firestoreService.firestore.settings.persistenceEnabled,
        'cacheSize': _firestoreService.firestore.settings.cacheSizeBytes,
      };

      return stats;
    } catch (e) {
      return <String, dynamic>{
        'error': 'Failed to get service stats: $e',
      };
    }
  }

  /// Perform a health check on all services
  Future<bool> performHealthCheck() async {
    try {
      final healthStatus = await getHealthStatus();
      final allHealthy = healthStatus.values.every((status) => status);

      if (allHealthy) {
        await _configService.logEvent(
          name: 'health_check_passed',
          parameters: {
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } else {
        await _configService.logEvent(
          name: 'health_check_failed',
          parameters: {
            'timestamp': DateTime.now().toIso8601String(),
            'status': healthStatus.toString(),
          },
        );
      }

      return allHealthy;
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Health check failed');
      return false;
    }
  }

  /// Reset all services (useful for testing or debugging)
  Future<void> reset() async {
    try {
      await dispose();
      await initialize();

      await _configService.logEvent(
        name: 'services_reset',
        parameters: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Service reset failed');
      rethrow;
    }
  }
}
