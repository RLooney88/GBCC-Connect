import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/user.dart';
import '../models/contact.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../services/service_manager.dart';

/// Provider for managing Firebase operations and state
class FirebaseProvider extends ChangeNotifier {
  final ServiceManager _serviceManager = ServiceManager.instance;

  // State variables
  User? _currentUser;
  List<Contact> _contacts = [];
  List<Message> _messages = [];
  List<Conversation> _conversations = [];
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  User? get currentUser => _currentUser;
  List<Contact> get contacts => _contacts;
  List<Message> get messages => _messages;
  List<Conversation> get conversations => _conversations;
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
      debugPrint('FirebaseProvider: Starting initialization...');
      _setLoading(true);
      _clearError();

      // Add timeout to prevent hanging
      final timeout = const Duration(seconds: 30);
      await _serviceManager.initialize().timeout(timeout, onTimeout: () {
        throw TimeoutException(
            'ServiceManager initialization timed out', timeout);
      });
      debugPrint('FirebaseProvider: ServiceManager initialized successfully');

      _isInitialized = true;
      debugPrint('FirebaseProvider: Initialization completed successfully');
    } catch (e) {
      debugPrint('FirebaseProvider: Initialization failed with error: $e');
      _setError('Failed to initialize Firebase: $e');
    } finally {
      _setLoading(false);
      debugPrint('FirebaseProvider: Loading state set to false');
    }
  }

  /// Load current user data when authentication state changes
  /// This method should be called by AuthProvider when user logs in
  Future<void> onUserAuthenticated(String userId) async {
    try {
      debugPrint(
          'FirebaseProvider: User authenticated, loading additional data for: $userId');

      // Load user's contacts and conversations
      debugPrint(
          'FirebaseProvider: Loading user contacts and conversations...');
      await Future.wait([
        loadContacts(),
        loadConversations(),
      ]);
      debugPrint('FirebaseProvider: Additional user data loading completed');
    } catch (e) {
      debugPrint(
          'FirebaseProvider: Error loading additional user data after authentication: $e');
      _setError('Failed to load additional user data: $e');
    }
  }

  /// Clear user data when user logs out
  /// This method should be called by AuthProvider when user logs out
  void onUserLoggedOut() {
    debugPrint('FirebaseProvider: User logged out, clearing data');
    _contacts.clear();
    _messages.clear();
    _conversations.clear();
    _error = null;
    notifyListeners();
  }

  /// Load current user data (public method)
  Future<void> loadCurrentUser() async {
    try {
      final currentAuthUser = _serviceManager.auth.currentUser;
      if (currentAuthUser != null) {
        // Get user data from AuthProvider instead of loading directly
        final user =
            await _serviceManager.users.getUserById(currentAuthUser.uid);
        if (user != null) {
          _currentUser = user;
          notifyListeners();

          // Load additional data
          await Future.wait([
            loadContacts(),
            loadConversations(),
          ]);
        }
      } else {
        debugPrint('FirebaseProvider: No authenticated user found');
      }
    } catch (e) {
      debugPrint('FirebaseProvider: Error loading current user: $e');
      _setError('Failed to load current user: $e');
    }
  }

  /// Force refresh current user data from Firebase
  Future<void> refreshCurrentUser() async {
    try {
      final currentAuthUser = _serviceManager.auth.currentUser;
      if (currentAuthUser != null) {
        debugPrint('FirebaseProvider: Force refreshing current user data...');

        // Refresh user data
        final user =
            await _serviceManager.users.getUserById(currentAuthUser.uid);
        if (user != null) {
          _currentUser = user;
          notifyListeners();
        }

        // Refresh additional data
        await Future.wait([
          loadContacts(),
          loadConversations(),
        ]);

        debugPrint(
            'FirebaseProvider: Current user data refreshed successfully');
      } else {
        debugPrint('FirebaseProvider: No authenticated user found for refresh');
      }
    } catch (e) {
      debugPrint('FirebaseProvider: Error refreshing current user: $e');
      _setError('Failed to refresh current user: $e');
      rethrow;
    }
  }

  /// Ensure current user exists in Firebase
  Future<void> ensureCurrentUserExists() async {
    try {
      final currentAuthUser = _serviceManager.auth.currentUser;
      if (currentAuthUser == null) {
        debugPrint('FirebaseProvider: No authenticated user found');
        return;
      }

      // Check if user exists in Firebase
      final existingUser =
          await _serviceManager.users.getUserById(currentAuthUser.uid);

      if (existingUser == null) {
        debugPrint(
            'FirebaseProvider: User not found in Firebase, this should be handled by AuthProvider');
        // User creation is now handled by AuthProvider
        return;
      } else {
        debugPrint('FirebaseProvider: User already exists in Firebase');
        // Update local user data
        _currentUser = existingUser;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('FirebaseProvider: Error ensuring user exists: $e');
      _setError('Failed to ensure user exists: $e');
      rethrow;
    }
  }

  /// Create a new user
  Future<void> createUser(User user) async {
    try {
      _setLoading(true);
      _clearError();

      final userId = await _serviceManager.users.createUser(user);
      debugPrint('User created with ID: $userId');
    } catch (e) {
      _setError('Failed to create user: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Check if current user exists in Firebase
  Future<bool> doesCurrentUserExist() async {
    try {
      final currentAuthUser = _serviceManager.auth.currentUser;
      if (currentAuthUser == null) {
        return false;
      }

      final user = await _serviceManager.users.getUserById(currentAuthUser.uid);
      return user != null;
    } catch (e) {
      debugPrint('FirebaseProvider: Error checking if user exists: $e');
      return false;
    }
  }

  /// Update current user
  Future<void> updateCurrentUser(User user) async {
    try {
      debugPrint(
          'FirebaseProvider: Starting user update for user ID: ${user.id}');
      _setLoading(true);
      _clearError();

      // Get the current authenticated user
      final currentAuthUser = _serviceManager.auth.currentUser;
      if (currentAuthUser == null) {
        throw Exception('No authenticated user found');
      }

      // Validate user ID matches the authenticated user
      if (user.id != currentAuthUser.uid) {
        throw Exception(
            'User ID mismatch: authenticated=${currentAuthUser.uid}, update=${user.id}');
      }

      // Validate required fields
      if (user.name.trim().isEmpty) {
        throw Exception('Name cannot be empty');
      }

      if (user.email.trim().isEmpty) {
        throw Exception('Email cannot be empty');
      }

      // Check if user exists in Firebase before updating
      final userExists = await doesCurrentUserExist();
      if (!userExists) {
        debugPrint(
            'FirebaseProvider: User does not exist in Firebase, creating...');
        await ensureCurrentUserExists();
      }

      // Get the current user from Firebase to ensure we have the latest data
      final existingUser = await _serviceManager.users.getUserById(user.id);
      if (existingUser == null) {
        throw Exception('User not found in Firebase database');
      }

      // Create updated user with current timestamp and preserve existing fields
      final updatedUser = existingUser.copyWith(
        name: user.name,
        email: user.email,
        displayName: user.displayName,
        phone: user.phone,
        address: user.address,
        title: user.title,
        website: user.website,
        notes: user.notes,
        instagram: user.instagram,
        facebook: user.facebook,
        youtube: user.youtube,
        linkedin: user.linkedin,
        pinterest: user.pinterest,
        chamberMember: user.chamberMember,
        isOwner: user.isOwner,
        company: user.company,
        companyPhone: user.companyPhone,
        companyEmail: user.companyEmail,
        status: user.status,
        updatedAt: DateTime.now(), // Update timestamp
      );

      debugPrint('FirebaseProvider: Calling service manager to update user');

      // Update user in Firebase
      await _serviceManager.users.updateUser(user.id, updatedUser);

      debugPrint('FirebaseProvider: User updated successfully in Firebase');

      // Update local state
      _currentUser = updatedUser;
      notifyListeners();

      debugPrint(
          'FirebaseProvider: Local state updated and listeners notified');
    } catch (e) {
      debugPrint('FirebaseProvider: Error updating user: $e');
      _setError('Failed to update user: $e');
      rethrow; // Re-throw to allow calling code to handle the error
    } finally {
      _setLoading(false);
      debugPrint('FirebaseProvider: Loading state set to false');
    }
  }

  /// Load user's contacts
  Future<void> loadContacts() async {
    try {
      if (_currentUser == null) {
        debugPrint('loadContacts: No current user, returning early');
        return;
      }

      debugPrint('loadContacts: Loading contacts for user ${_currentUser!.id}');
      _setLoading(true);
      _clearError();

      final contacts =
          await _serviceManager.contacts.getContactsByOwner(_currentUser!.id);
      debugPrint(
          'loadContacts: Retrieved ${contacts.length} contacts from service');
      _contacts = contacts;
      notifyListeners();
      debugPrint('loadContacts: Updated contacts list and notified listeners');
    } catch (e) {
      debugPrint('loadContacts: Error loading contacts: $e');
      _setError('Failed to load contacts: $e');
    } finally {
      _setLoading(false);
      debugPrint('loadContacts: Loading state set to false');
    }
  }

  /// Create a new contact
  Future<void> createContact(Contact contact) async {
    try {
      _setLoading(true);
      _clearError();

      final contactId = await _serviceManager.contacts.createContact(contact);
      debugPrint('Contact created with ID: $contactId');

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
  Future<void> loadConversation(String ownerId, String participantId) async {
    try {
      _setLoading(true);
      _clearError();

      final messages = await _serviceManager.messages
          .getMessagesBetweenUsers(ownerId, participantId);
      _messages = messages;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load conversation: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Send a message
  Future<void> sendMessage(
    String receiverId,
    String content, {
    String? attachmentUrl,
    String messageType = 'text',
  }) async {
    try {
      if (_currentUser == null) {
        _setError('User not authenticated');
        return;
      }

      _setLoading(true);
      _clearError();

      final messageId = await _serviceManager.messages.sendMessage(
        _currentUser!.id,
        receiverId,
        content,
        attachmentUrl: attachmentUrl,
        messageType: messageType,
      );

      debugPrint('Message sent with ID: $messageId');

      // Reload conversations to update last message
      await loadConversations();
    } catch (e) {
      _setError('Failed to send message: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load messages for a specific conversation
  Future<void> loadMessagesForConversation(String conversationId) async {
    try {
      _setLoading(true);
      _clearError();

      final messages = await _serviceManager.messages
          .getMessagesForConversation(conversationId);
      _messages = messages;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load messages for conversation: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get or create conversation between two users
  Future<Conversation?> getOrCreateConversation(
      String user1Id, String user2Id) async {
    try {
      return await _serviceManager.conversations
          .getOrCreateConversation(user1Id, user2Id);
    } catch (e) {
      _setError('Failed to get or create conversation: $e');
      return null;
    }
  }

  /// Create a new conversation
  Future<Conversation?> createConversation(
      String ownerId, String participantId) async {
    try {
      return await _serviceManager.conversations
          .createConversation(ownerId, participantId);
    } catch (e) {
      _setError('Failed to create conversation: $e');
      return null;
    }
  }

  /// Archive or unarchive conversation
  Future<void> toggleConversationArchive(
      String conversationId, bool isActive) async {
    try {
      await _serviceManager.conversations
          .toggleConversationArchive(conversationId, isActive);

      // Reload conversations to reflect changes
      await loadConversations();
    } catch (e) {
      _setError('Failed to toggle conversation archive: $e');
    }
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _serviceManager.conversations.deleteConversation(conversationId);

      // Reload conversations to reflect changes
      await loadConversations();
    } catch (e) {
      _setError('Failed to delete conversation: $e');
    }
  }

  /// Get active conversations
  Future<List<Conversation>> getActiveConversations() async {
    try {
      if (_currentUser == null) return [];
      return await _serviceManager.conversations
          .getActiveConversations(_currentUser!.id);
    } catch (e) {
      _setError('Failed to get active conversations: $e');
      return [];
    }
  }

  /// Get archived conversations
  Future<List<Conversation>> getArchivedConversations() async {
    try {
      if (_currentUser == null) return [];
      return await _serviceManager.conversations
          .getArchivedConversations(_currentUser!.id);
    } catch (e) {
      _setError('Failed to get archived conversations: $e');
      return [];
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

  /// Load user's conversations
  Future<void> loadConversations() async {
    try {
      if (_currentUser == null) return;

      _setLoading(true);
      _clearError();

      final conversations = await _serviceManager.conversations
          .getConversationsForUser(_currentUser!.id);
      _conversations = conversations;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load conversations: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Get conversation statistics
  Future<Map<String, int>> getConversationStats() async {
    try {
      if (_currentUser == null) return {};
      return await _serviceManager.conversations
          .getConversationStats(_currentUser!.id);
    } catch (e) {
      _setError('Failed to get conversation stats: $e');
      return {};
    }
  }

  /// Get unread message count
  Future<int> getUnreadMessageCount() async {
    try {
      if (_currentUser == null) return 0;
      return await _serviceManager.conversations
          .getUnreadMessageCount(_currentUser!.id);
    } catch (e) {
      _setError('Failed to get unread message count: $e');
      return 0;
    }
  }

  /// Mark messages as read between two users
  Future<void> markMessagesAsRead(String senderId) async {
    try {
      if (_currentUser == null) return;

      await _serviceManager.messages
          .markMessagesAsRead(_currentUser!.id, senderId);

      // Reload conversations to update unread counts
      await loadConversations();
    } catch (e) {
      _setError('Failed to mark messages as read: $e');
    }
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      if (_currentUser == null) return;
      await _serviceManager.conversations
          .markConversationAsRead(conversationId, _currentUser!.id);

      // Reload conversations to update unread counts
      await loadConversations();
    } catch (e) {
      _setError('Failed to mark conversation as read: $e');
    }
  }

  /// Stream conversations in real-time
  Stream<List<Conversation>> streamConversations() {
    if (_currentUser == null) return Stream.value([]);
    return _serviceManager.conversations
        .streamConversationsForUser(_currentUser!.id);
  }

  /// Stream contacts in real-time
  Stream<List<Contact>> streamContacts() {
    if (_currentUser == null) {
      debugPrint('streamContacts: No current user, returning empty stream');
      return Stream.value([]);
    }
    debugPrint('streamContacts: Creating stream for user ${_currentUser!.id}');
    return _serviceManager.contacts.streamContactsByOwner(_currentUser!.id);
  }

  /// Stream conversation in real-time
  Stream<List<Message>> streamConversation(String user1Id, String user2Id) {
    return _serviceManager.messages
        .streamMessagesBetweenUsers(user1Id, user2Id);
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
    _conversations.clear();
    _users.clear();
    _error = null;
    _isInitialized = false;
    notifyListeners();
  }

  /// Debug method to get current state information
  Map<String, dynamic> getDebugInfo() {
    return {
      'isInitialized': _isInitialized,
      'isLoading': _isLoading,
      'hasCurrentUser': _currentUser != null,
      'currentUserId': _currentUser?.id,
      'currentUserName': _currentUser?.name,
      'authUserExists': _serviceManager.auth.currentUser != null,
      'authUserId': _serviceManager.auth.currentUser?.uid,
      'error': _error,
      'contactsCount': _contacts.length,
      'conversationsCount': _conversations.length,
    };
  }

  /// Dispose provider
  @override
  void dispose() {
    super.dispose();
  }
}
