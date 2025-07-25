import '../models/conversation.dart';
import '../models/user.dart';
import '../models/message.dart';
import '../providers/firebase_provider.dart';
import 'package:flutter/foundation.dart';

/// Domain/Business Logic Layer: ConversationService
/// Mission: Implement conversation-specific logic and transform data for the UI
/// - Business logic for conversations (creating, fetching, updating, deleting, etc.)
/// - Pure Dart code (no Flutter imports)
/// - Abstracts over FirebaseProvider or any data source
/// - Handles data mapping/DTOs if necessary
class ConversationService {
  static ConversationService? _instance;
  static ConversationService get instance =>
      _instance ??= ConversationService._internal();

  ConversationService._internal();

  FirebaseProvider? _firebaseProvider;
  static const String _collection = 'conversations';

  /// Initialize the service with FirebaseProvider
  Future<void> initialize(FirebaseProvider firebaseProvider) async {
    _firebaseProvider = firebaseProvider;
  }

  /// Generate a consistent conversation ID from two email addresses
  /// This ensures the same conversation ID regardless of the order of emails
  String _generateConversationId(String email1, String email2) {
    final emails = [email1, email2]..sort();
    return '${emails[0]}_${emails[1]}';
  }

  /// Create or get a conversation between two users by email
  /// This works for both registered and unregistered users
  Future<Conversation> createOrGetConversationByEmail(
    String ownerEmail,
    String participantEmail,
  ) async {
    try {
      // Create a unique conversation ID based on emails (sorted to ensure consistency)
      final conversationId =
          _generateConversationId(ownerEmail, participantEmail);

      // Check if conversation already exists
      final existingDoc = await _firebaseProvider!.getDocument(
        _collection,
        conversationId,
      );

      if (existingDoc != null && existingDoc.exists) {
        // Return existing conversation
        final data = existingDoc.data() as Map<String, dynamic>;
        return Conversation.fromJson({
          'id': existingDoc.id,
          ...data,
        });
      }

      // Get user details (owner should be registered)
      final ownerUser = await _getUserByEmail(ownerEmail);
      final participantUser = await _getUserByEmail(participantEmail);

      // Create new conversation
      final conversation = Conversation(
        id: conversationId,
        ownerId: ownerUser?.id ?? ownerEmail, // Use email if user not found
        participantId: participantUser?.id ??
            participantEmail, // Use email if user not found
        owner: ownerUser,
        participant: participantUser,
        lastMessage: null,
        isActive: true,
      );

      // Save to Firestore with specific document ID
      final conversationData = conversation.toJson();
      conversationData.remove('id'); // Remove id field to avoid duplication
      await _firebaseProvider!.createDocumentWithId(
        _collection,
        conversationId,
        conversationData,
      );

      return conversation;
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Get conversation between two users by email
  Future<Conversation?> getConversationByEmail(
    String ownerEmail,
    String participantEmail,
  ) async {
    try {
      final conversationId =
          _generateConversationId(ownerEmail, participantEmail);

      debugPrint(
          'ConversationService: Looking for conversation with ID: $conversationId');
      debugPrint(
          'ConversationService: Between $ownerEmail and $participantEmail');

      final doc = await _firebaseProvider!.getDocument(
        _collection,
        conversationId,
      );

      if (doc == null || !doc.exists) {
        debugPrint(
            'ConversationService: No conversation found with ID: $conversationId');
        return null;
      }

      debugPrint('ConversationService: Found conversation: ${doc.id}');
      return Conversation.fromJson({
        'id': doc.id,
        ...(doc.data() as Map<String, dynamic>),
      });
    } catch (e) {
      debugPrint('ConversationService: Error getting conversation: $e');
      throw Exception('Failed to get conversation: $e');
    }
  }

  /// Get conversation between two users by user IDs (for registered users)
  Future<Conversation?> getConversationBetweenUsers(
    String ownerId,
    String participantId,
  ) async {
    try {
      // Get user emails to generate conversation ID
      final ownerUser = await _getUserById(ownerId);
      final participantUser = await _getUserById(participantId);

      if (ownerUser == null || participantUser == null) {
        // If users not found, try to find by user IDs directly
        final filters = [
          MapEntry('ownerId', ownerId),
          MapEntry('participantId', participantId),
        ];

        final querySnapshot = await _firebaseProvider!.getDocuments(
          _collection,
          filters: filters,
          limit: 1,
        );

        if (querySnapshot.docs.isNotEmpty) {
          final doc = querySnapshot.docs.first;
          return Conversation.fromJson({
            'id': doc.id,
            ...(doc.data() as Map<String, dynamic>),
          });
        }
        return null;
      }

      // Generate conversation ID from emails
      final conversationId = _generateConversationId(
        ownerUser.email,
        participantUser.email,
      );

      final doc = await _firebaseProvider!.getDocument(
        _collection,
        conversationId,
      );

      if (doc == null || !doc.exists) return null;

      return Conversation.fromJson({
        'id': doc.id,
        ...(doc.data() as Map<String, dynamic>),
      });
    } catch (e) {
      throw Exception('Failed to get conversation between users: $e');
    }
  }

  /// Stream conversations for a user (by email or user ID)
  /// This will return conversations where the user is either the owner or participant
  Stream<List<Conversation>> streamConversationsForUser(String userIdentifier) {
    try {
      // Try to find conversations where user is owner OR participant
      // We need to use a compound query or multiple queries
      return _firebaseProvider!
          .listenToCollection(
        _collection,
        orderBy: 'updatedAt',
        descending: true,
      )
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Conversation.fromJson({
            'id': doc.id,
            ...data,
          });
        }).where((conversation) {
          // Filter conversations where user is owner or participant
          return conversation.owner?.email == userIdentifier ||
              conversation.participant?.email == userIdentifier;
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to stream conversations: $e');
    }
  }

  /// Stream conversations where user is the owner (by email or user ID)
  Stream<List<Conversation>> streamConversationsOwnedByUser(
      String userIdentifier) {
    try {
      final filters = [MapEntry('ownerId', userIdentifier)];
      return _firebaseProvider!
          .listenToCollection(
        _collection,
        filters: filters,
        orderBy: 'updatedAt',
        descending: true,
      )
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Conversation.fromJson({
            'id': doc.id,
            ...(doc.data() as Map<String, dynamic>),
          });
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to stream owned conversations: $e');
    }
  }

  /// Update conversation with last message
  Future<void> updateConversationWithMessage(
    String conversationId,
    Message message,
  ) async {
    try {
      await _firebaseProvider!.updateDocument(
        _collection,
        conversationId,
        {
          'lastMessage': message.toJson(),
        },
      );
    } catch (e) {
      throw Exception('Failed to update conversation: $e');
    }
  }

  /// Update unread count for a conversation
  Future<void> updateUnreadCount(
    String conversationId,
    int unreadCount,
  ) async {
    try {
      await _firebaseProvider!.updateDocument(
        _collection,
        conversationId,
        {
          'unreadCount': unreadCount,
        },
      );
    } catch (e) {
      throw Exception('Failed to update unread count: $e');
    }
  }

  /// Mark conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      debugPrint(
          'ConversationService: Marking conversation as read: $conversationId');

      await _firebaseProvider!.updateDocument(
        _collection,
        conversationId,
        {
          'unreadCount': 0,
        },
      );

      debugPrint(
          'ConversationService: Conversation marked as read successfully');
    } catch (e) {
      debugPrint('ConversationService: Error marking conversation as read: $e');
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  /// Toggle conversation archive status
  Future<void> toggleConversationArchive(
    String conversationId,
    bool isActive,
  ) async {
    try {
      await _firebaseProvider!.updateDocument(
        _collection,
        conversationId,
        {
          'isActive': isActive,
        },
      );
    } catch (e) {
      throw Exception('Failed to toggle conversation archive: $e');
    }
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _firebaseProvider!.deleteDocument(_collection, conversationId);
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  /// Delete multiple conversations
  Future<void> deleteMultipleConversations(List<String> conversationIds) async {
    try {
      for (final id in conversationIds) {
        await _firebaseProvider!.deleteDocument(_collection, id);
      }
    } catch (e) {
      throw Exception('Failed to delete conversations: $e');
    }
  }

  /// Get user by email (returns null if not registered)
  Future<User?> _getUserByEmail(String email) async {
    try {
      final filters = [MapEntry('email', email)];
      final querySnapshot = await _firebaseProvider!.getDocuments(
        'users',
        filters: filters,
        limit: 1,
      );

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return User.fromJson({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }
      return null;
    } catch (e) {
      // Return null if user not found or error
      return null;
    }
  }

  /// Get user by ID (returns null if not found)
  Future<User?> _getUserById(String userId) async {
    try {
      final filters = [MapEntry('id', userId)];
      final querySnapshot = await _firebaseProvider!.getDocuments(
        'users',
        filters: filters,
        limit: 1,
      );

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return User.fromJson({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }
      return null;
    } catch (e) {
      // Return null if user not found or error
      return null;
    }
  }

  /// Migrate conversation when a contact registers
  /// This updates the conversation to use user IDs instead of emails
  Future<void> migrateConversationToUserIds(
    String conversationId,
    String userEmail,
    String userId,
  ) async {
    try {
      final conversationDoc = await _firebaseProvider!.getDocument(
        _collection,
        conversationId,
      );

      if (conversationDoc == null || !conversationDoc.exists) return;

      final data = conversationDoc.data() as Map<String, dynamic>;
      final updates = <String, dynamic>{};

      // Update ownerId if it matches the email
      if (data['ownerId'] == userEmail) {
        updates['ownerId'] = userId;
      }

      // Update participantId if it matches the email
      if (data['participantId'] == userEmail) {
        updates['participantId'] = userId;
      }

      // Update user objects if they match the email
      if (data['owner'] != null &&
          (data['owner'] as Map<String, dynamic>)['email'] == userEmail) {
        final user = await _getUserByEmail(userEmail);
        if (user != null) {
          updates['owner'] = user.toJson();
        }
      }

      if (data['participant'] != null &&
          (data['participant'] as Map<String, dynamic>)['email'] == userEmail) {
        final user = await _getUserByEmail(userEmail);
        if (user != null) {
          updates['participant'] = user.toJson();
        }
      }

      if (updates.isNotEmpty) {
        await _firebaseProvider!.updateDocument(
          _collection,
          conversationId,
          updates,
        );
      }
    } catch (e) {
      throw Exception('Failed to migrate conversation: $e');
    }
  }

  /// Validate conversation data
  bool validateConversation(Conversation conversation) {
    if (conversation.ownerId.isEmpty) return false;
    if (conversation.participantId.isEmpty) return false;
    if (conversation.ownerId == conversation.participantId) return false;
    return true;
  }

  /// Get conversations for a user (non-streaming)
  Future<List<Conversation>> _getConversationsForUser(
      String userIdentifier) async {
    try {
      final filters = [MapEntry('ownerId', userIdentifier)];
      final querySnapshot = await _firebaseProvider!.getDocuments(
        _collection,
        filters: filters,
        orderBy: 'updatedAt',
        descending: true,
      );

      return querySnapshot.docs.map((doc) {
        return Conversation.fromJson({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }
}
