import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../services/service_manager.dart';

/// Provider for managing Firebase operations and state
class FirebaseProvider extends ChangeNotifier {
  final ServiceManager _serviceManager = ServiceManager.instance;

  // State variables
  User? _currentUser;
  List<Contact> _contacts = [];
  List<Message> _messages = [];
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get currentUser => _currentUser;
  List<Contact> get contacts => _contacts;
  List<Message> get messages => _messages;
  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase services
  Future<void> initialize() async {
    // Prevent multiple initializations
    if (_isInitialized) {
      debugPrint(
          'FirebaseProvider is already initialized, skipping initialization');
      return;
    }

    try {
      _setLoading(true);
      _clearError();

      await _serviceManager.initialize();

      // Listen to auth state changes
      _serviceManager.auth.authStateChanges.listen((user) {
        if (user != null) {
          _loadCurrentUser(user.uid);
        } else {
          _currentUser = null;
          notifyListeners();
        }
      });

      _isInitialized = true;
    } catch (e) {
      _setError('Failed to initialize Firebase: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load current user data
  Future<void> _loadCurrentUser(String userId) async {
    try {
      final user = await _serviceManager.users.getUserById(userId);
      if (user != null) {
        _currentUser = user;
        notifyListeners();

        // Load user's contacts
        await loadContacts();
      }
    } catch (e) {
      _setError('Failed to load user: $e');
    }
  }

  /// Create a new user
  Future<void> createUser(User user) async {
    try {
      _setLoading(true);
      _clearError();

      final userId = await _serviceManager.users.createUser(user);
      print('User created with ID: $userId');
    } catch (e) {
      _setError('Failed to create user: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update current user
  Future<void> updateCurrentUser(User user) async {
    try {
      _setLoading(true);
      _clearError();

      if (_currentUser != null) {
        await _serviceManager.users.updateUser(_currentUser!.id, user);
        _currentUser = user;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update user: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load user's contacts
  Future<void> loadContacts() async {
    try {
      if (_currentUser == null) return;

      _setLoading(true);
      _clearError();

      final contacts =
          await _serviceManager.contacts.getContactsByOwner(_currentUser!.id);
      _contacts = contacts;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load contacts: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new contact
  Future<void> createContact(Contact contact) async {
    try {
      _setLoading(true);
      _clearError();

      final contactId = await _serviceManager.contacts.createContact(contact);
      print('Contact created with ID: $contactId');

      // Reload contacts
      await loadContacts();
    } catch (e) {
      _setError('Failed to create contact: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update contact
  Future<void> updateContact(Contact contact) async {
    try {
      _setLoading(true);
      _clearError();

      await _serviceManager.contacts.updateContact(contact.id, contact);

      // Update in local list
      final index = _contacts.indexWhere((c) => c.id == contact.id);
      if (index != -1) {
        _contacts[index] = contact;
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update contact: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete contact
  Future<void> deleteContact(String contactId) async {
    try {
      _setLoading(true);
      _clearError();

      await _serviceManager.contacts.deleteContact(contactId);

      // Remove from local list
      _contacts.removeWhere((c) => c.id == contactId);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete contact: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle contact favorite status
  Future<void> toggleContactFavorite(String contactId, bool isFavorite) async {
    try {
      await _serviceManager.contacts.toggleFavorite(contactId, isFavorite);

      // Update in local list
      final index = _contacts.indexWhere((c) => c.id == contactId);
      if (index != -1) {
        _contacts[index] = _contacts[index].copyWith(isFavorite: isFavorite);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to toggle favorite: $e');
    }
  }

  /// Load conversation between two users
  Future<void> loadConversation(String user1Id, String user2Id) async {
    try {
      _setLoading(true);
      _clearError();

      final messages =
          await _serviceManager.messages.getConversation(user1Id, user2Id);
      _messages = messages;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load conversation: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Send a message
  Future<void> sendMessage(Message message) async {
    try {
      _setLoading(true);
      _clearError();

      final messageId = await _serviceManager.messages.createMessage(message);
      print('Message sent with ID: $messageId');

      // Add to local list
      _messages.add(message.copyWith(id: messageId));
      notifyListeners();
    } catch (e) {
      _setError('Failed to send message: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load all users
  Future<void> loadUsers() async {
    try {
      _setLoading(true);
      _clearError();

      final users = await _serviceManager.users.getUsers();
      _users = users;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load users: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Search users
  Future<List<User>> searchUsers(String searchTerm) async {
    try {
      return await _serviceManager.users.searchUsers(searchTerm);
    } catch (e) {
      _setError('Failed to search users: $e');
      return [];
    }
  }

  /// Search contacts
  Future<List<Contact>> searchContacts(String searchTerm) async {
    try {
      if (_currentUser == null) return [];
      return await _serviceManager.contacts
          .searchContacts(_currentUser!.id, searchTerm);
    } catch (e) {
      _setError('Failed to search contacts: $e');
      return [];
    }
  }

  /// Get contact statistics
  Future<Map<String, int>> getContactStats() async {
    try {
      if (_currentUser == null) return {};
      return await _serviceManager.contacts.getContactStats(_currentUser!.id);
    } catch (e) {
      _setError('Failed to get contact stats: $e');
      return {};
    }
  }

  /// Get message statistics
  Future<Map<String, int>> getMessageStats() async {
    try {
      if (_currentUser == null) return {};
      return await _serviceManager.messages.getMessageStats(_currentUser!.id);
    } catch (e) {
      _setError('Failed to get message stats: $e');
      return {};
    }
  }

  /// Stream contacts in real-time
  Stream<List<Contact>> streamContacts() {
    if (_currentUser == null) return Stream.value([]);
    return _serviceManager.contacts.streamContactsByOwner(_currentUser!.id);
  }

  /// Stream conversation in real-time
  Stream<List<Message>> streamConversation(String user1Id, String user2Id) {
    return _serviceManager.messages.streamConversation(user1Id, user2Id);
  }

  /// Stream users in real-time
  Stream<List<User>> streamUsers() {
    return _serviceManager.users.streamUsers();
  }

  /// Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear all data
  void clearData() {
    _currentUser = null;
    _contacts.clear();
    _messages.clear();
    _users.clear();
    _error = null;
    _isInitialized = false;
    notifyListeners();
  }

  /// Dispose provider
  @override
  void dispose() {
    super.dispose();
  }
}
