import '../providers/firebase_provider.dart';
import 'user_service.dart';
import 'conversation_service.dart';
import 'message_service.dart';
import 'contact_service.dart';
import 'email_service.dart';

/// App-Level Provider: ServiceManager
/// Mission: Coordinate service initialization and provide access to all services
/// - Handles service initialization order
/// - Provides clean access to all services
/// - Acts as a facade/coordinator
/// - Pure Dart code with no Flutter dependencies
class ServiceManager {
  static ServiceManager? _instance;
  static ServiceManager get instance =>
      _instance ??= ServiceManager._internal();

  ServiceManager._internal();

  // Core services in specified order
  FirebaseProvider? _firebaseProvider;
  late final UserService _userService;
  late final ConversationService _conversationService;
  late final MessageService _messageService;
  late final ContactService _contactService;
  late final EmailService _emailService;

  // Application state
  bool _isInitialized = false;
  bool _isLoading = false;
  String? _error;

  // Getters
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Service exports - direct access to all services
  UserService get userService => _userService;
  ConversationService get conversationService => _conversationService;
  MessageService get messageService => _messageService;
  ContactService get contactService => _contactService;
  EmailService get emailService => _emailService;
  FirebaseProvider? get firebaseProvider => _firebaseProvider;

  /// Initialize all services with an existing FirebaseProvider
  Future<void> initialize(FirebaseProvider firebaseProvider) async {
    if (_isInitialized) {
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      // Use the provided FirebaseProvider instance
      _firebaseProvider = firebaseProvider;

      // Initialize services in dependency order
      // 1. UserService (no dependencies)
      _userService = UserService.instance;
      await _userService.initialize(_firebaseProvider!);

      // 2. ContactService (no dependencies)
      _contactService = ContactService.instance;
      await _contactService.initialize(_firebaseProvider!);

      // 3. ConversationService (no dependencies)
      _conversationService = ConversationService.instance;
      await _conversationService.initialize(_firebaseProvider!);

      // 4. MessageService (depends on ConversationService)
      _messageService = MessageService.instance;
      await _messageService.initialize(_firebaseProvider!);

      // 5. EmailService (no dependencies)
      _emailService = EmailService.instance;

      _isInitialized = true;
    } catch (e) {
      _setError('Service initialization failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ========== UTILITY METHODS ==========

  /// Clear error state
  void _clearError() {
    _error = null;
  }

  /// Set error state
  void _setError(String error) {
    _error = error;
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
  }

  /// Clear all data (useful for testing)
  void clearData() {
    _error = null;
  }

  /// Get debug information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isLoading': _isLoading,
      'error': _error,
    };
  }
}
