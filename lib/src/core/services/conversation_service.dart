import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../providers/firebase_provider.dart';
import 'user_service.dart';
import 'message_service.dart';

/// ConversationService
/// Mission: Manage conversations/chats between user and contact user.
/// Responsibilities:
/// - Create a new conversation (between two or more users)
/// - Fetch list of conversations for a user
/// - Update conversation status (read/unread)
class ConversationService {
  static ConversationService? _instance;
  static ConversationService get instance =>
      _instance ??= ConversationService._internal();

  ConversationService._internal();

  FirebaseProvider? _firebaseProvider;
  UserService? _userService;
  MessageService? _messageService;
  static const String _collection = 'conversations';

  /// Initialize the service with dependencies
  Future<void> initialize(
    FirebaseProvider firebaseProvider,
    UserService userService,
    MessageService messageService,
  ) async {
    _firebaseProvider = firebaseProvider;
    _userService = userService;
    _messageService = messageService;
  }

  /// Get all conversations for a user (where user is the owner)
  Future<List<Conversation>> getConversationsForUser(String userId) async {
    try {
      // Get conversations where user is the owner
      final conversations = await _firebaseProvider!.getDocuments(
        _collection,
        filters: [MapEntry('ownerId', userId)],
        orderBy: 'updatedAt',
        descending: true,
      );

      final List<Conversation> result = [];

      // Process conversations
      for (final doc in conversations.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final conversation = await _buildConversationFromData(doc.id, data);
        if (conversation != null) {
          result.add(conversation);
        }
      }

      return result;
    } catch (e) {
      // Check if it's a missing index error
      if (e.toString().contains('failed-precondition') &&
          e.toString().contains('requires an index')) {
        throw Exception(
            'Firestore index is missing. Please create the required index for conversations collection. '
            'Check the firestore_indexes.md file for instructions.');
      }
      throw Exception('Failed to get conversations: $e');
    }
  }

  /// Get conversation between two users (from owner's perspective)
  Future<Conversation?> getConversation(
      String ownerId, String participantId) async {
    try {
      // Find conversation where ownerId and participantId match
      final conversations = await _firebaseProvider!.getDocuments(
        _collection,
        filters: [
          MapEntry('ownerId', ownerId),
          MapEntry('participantId', participantId),
        ],
      );

      if (conversations.docs.isNotEmpty) {
        final doc = conversations.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        return await _buildConversationFromData(doc.id, data);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  /// Get conversation between two users (alias for getConversation)
  Future<Conversation?> getConversationBetweenUsers(
      String ownerId, String participantId) async {
    return await getConversation(ownerId, participantId);
  }

  /// Get or create conversation between two users (supports email-based participants)
  Future<Conversation> getOrCreateConversation(
      String senderId, String receiverId) async {
    try {
      if (senderId.isEmpty || receiverId.isEmpty) {
        throw Exception('User IDs cannot be empty');
      }

      if (senderId == receiverId) {
        throw Exception('Cannot create conversation with yourself');
      }

      String participantId;
      User? participant;

      // Try to find conversation where user1 is owner and user2 is participant
      Conversation? conversation = await getConversation(senderId, receiverId);

      if (conversation != null) {
        return conversation;
      }

      // Create new conversation with user1 as owner and user2 as participant
      return await createConversationWithParticipant(
          senderId, receiverId, null);
    } catch (e) {
      throw Exception('Failed to get or create conversation: $e');
    }
  }

  /// Create a new conversation with a participant (supports email-based participants)
  Future<Conversation> createConversationWithParticipant(
      String ownerId, String participantId, User? participant) async {
    try {
      // Validate inputs
      if (ownerId.isEmpty || participantId.isEmpty) {
        throw Exception('Owner ID and participant ID cannot be empty');
      }

      if (ownerId == participantId) {
        throw Exception('Owner and participant cannot be the same user');
      }

      // Check if conversation already exists
      final existingConversation =
          await getConversation(ownerId, participantId);
      if (existingConversation != null) {
        return existingConversation;
      }

      // Get owner details
      final owner = await _userService!.getUserById(ownerId);
      if (owner == null) {
        throw Exception('Owner not found');
      }

      // If participant is null, create a minimal user object for the email
      User participantUser;
      if (participant != null) {
        participantUser = participant;
      } else {
        // Create a minimal user object for email-based participant
        participantUser = User(
          id: participantId, // Use email as ID
          name: participantId.split('@')[0], // Use email prefix as name
          email: participantId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      final conversation = Conversation(
        id: '',
        ownerId: ownerId,
        participantId: participantId,
        owner: owner,
        participant: participantUser,
        lastMessage: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      final docRef = await _firebaseProvider!.createDocument(
        _collection,
        conversation.toJson(),
      );

      return conversation.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Create or update conversation
  Future<String> createOrUpdateConversation(Conversation conversation) async {
    try {
      // Check if conversation already exists
      final existingConversation = await getConversation(
        conversation.ownerId,
        conversation.participantId,
      );

      if (existingConversation != null) {
        // Update existing conversation
        await _firebaseProvider!.updateDocument(
          _collection,
          existingConversation.id,
          conversation.toJson(),
        );
        return existingConversation.id;
      } else {
        // Create new conversation
        final docRef = await _firebaseProvider!.createDocument(
          _collection,
          conversation.toJson(),
        );
        return docRef.id;
      }
    } catch (e) {
      throw Exception('Failed to create or update conversation: $e');
    }
  }

  /// Update conversation with new message
  Future<void> updateConversationWithMessage(
      String conversationId, Message message) async {
    try {
      await _firebaseProvider!.updateDocument(
        _collection,
        conversationId,
        {
          'lastMessageId': message.id,
          'lastMessage': message.toJson(),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to update conversation with message: $e');
    }
  }

  /// Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final unreadMessages = await _firebaseProvider!.getDocuments(
        'messages',
        filters: [
          MapEntry('receiverId', userId),
          MapEntry('isRead', false),
        ],
      );

      return unreadMessages.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread message count: $e');
    }
  }

  /// Mark messages as read in a conversation
  Future<void> markConversationAsRead(
      String conversationId, String userId) async {
    try {
      // Get all unread messages in this conversation for the user
      final conversation = await getConversationById(conversationId);
      if (conversation == null) return;

      final otherUserId = conversation.getOtherUserId(userId);

      final unreadMessages = await _firebaseProvider!.getDocuments(
        'messages',
        filters: [
          MapEntry('senderId', otherUserId),
          MapEntry('receiverId', userId),
          MapEntry('isRead', false),
        ],
      );

      // Mark all messages as read
      for (final doc in unreadMessages.docs) {
        await _messageService!.updateMessage(
            doc.id,
            Message.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
              'isRead': true,
            }));
      }

      // Update conversation unread count
      await _firebaseProvider!.updateDocument(
        _collection,
        conversationId,
        {
          'unreadCount': 0,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  /// Get conversation by ID
  Future<Conversation?> getConversationById(String conversationId) async {
    try {
      final doc =
          await _firebaseProvider!.getDocument(_collection, conversationId);

      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return await _buildConversationFromData(doc.id, data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get conversation by ID: $e');
    }
  }

  /// Get conversation statistics for a user
  Future<Map<String, int>> getConversationStats(String userId) async {
    try {
      final conversations = await getConversationsForUser(userId);
      final unreadCount = await getUnreadMessageCount(userId);

      return {
        'total': conversations.length,
        'unread': unreadCount,
        'active': conversations.where((c) => c.lastMessage != null).length,
      };
    } catch (e) {
      throw Exception('Failed to get conversation stats: $e');
    }
  }

  /// Helper method to build conversation from Firestore data
  Future<Conversation?> _buildConversationFromData(
      String docId, Map<String, dynamic> data) async {
    try {
      // Get owner and participant details
      final ownerId = data['ownerId'] as String?;
      final participantId = data['participantId'] as String?;

      if (ownerId == null || participantId == null) {
        return null;
      }

      User? owner;
      User? participant;

      // Get owner details
      if (data['owner'] != null && data['owner'] is Map<String, dynamic>) {
        try {
          owner = User.fromJson(data['owner'] as Map<String, dynamic>);
        } catch (e) {
          // Fallback to fetching from service
          owner = await _userService!.getUserById(ownerId);
        }
      } else {
        owner = await _userService!.getUserById(ownerId);
      }

      // Get participant details
      if (data['participant'] != null &&
          data['participant'] is Map<String, dynamic>) {
        try {
          participant =
              User.fromJson(data['participant'] as Map<String, dynamic>);
        } catch (e) {
          // Fallback to fetching from service
          // Check if participantId is an email
          if (participantId.contains('@')) {
            participant = await _userService!.getUserByEmail(participantId);
            participant ??= User(
              id: participantId,
              name: participantId.split('@')[0],
              email: participantId,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          } else {
            participant = await _userService!.getUserById(participantId);
          }
        }
      } else {
        // Check if participantId is an email
        if (participantId.contains('@')) {
          participant = await _userService!.getUserByEmail(participantId);
          participant ??= User(
            id: participantId,
            name: participantId.split('@')[0],
            email: participantId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        } else {
          participant = await _userService!.getUserById(participantId);
        }
      }

      // Skip conversation if we can't get owner data
      if (owner == null) {
        return null;
      }

      // Get last message
      Message? lastMessage;
      if (data['lastMessageId'] != null) {
        try {
          lastMessage =
              await _messageService!.getMessageById(data['lastMessageId']);
        } catch (e) {
          // Continue without last message
        }
      }

      return Conversation.fromJson({
        'id': docId,
        'ownerId': ownerId,
        'participantId': participantId,
        'owner': owner.toJson(),
        'participant': participant?.toJson(),
        'lastMessage': lastMessage?.toJson(),
        'unreadCount': data['unreadCount'] ?? 0,
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
        'isActive': data['isActive'] ?? true,
      });
    } catch (e) {
      return null;
    }
  }

  /// Create a new conversation between users
  Future<Conversation> createConversation(
      String ownerId, String participantId) async {
    try {
      // Validate inputs
      if (ownerId.isEmpty || participantId.isEmpty) {
        throw Exception('Owner ID and participant ID cannot be empty');
      }

      if (ownerId == participantId) {
        throw Exception('Owner and participant cannot be the same user');
      }

      // Check if conversation already exists
      final existingConversation =
          await getConversation(ownerId, participantId);
      if (existingConversation != null) {
        return existingConversation;
      }

      // Get participant details
      final owner = await _userService!.getUserById(ownerId);
      final participant = await _userService!.getUserById(participantId);

      if (owner == null || participant == null) {
        throw Exception('Owner or participant not found');
      }

      final conversation = Conversation(
        id: '',
        ownerId: ownerId,
        participantId: participantId,
        owner: owner,
        participant: participant,
        lastMessage: null,
        unreadCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      final docRef = await _firebaseProvider!.createDocument(
        _collection,
        conversation.toJson(),
      );

      return conversation.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  /// Archive/unarchive conversation
  Future<void> toggleConversationArchive(
      String conversationId, bool isActive) async {
    try {
      await _firebaseProvider!.updateDocument(
        _collection,
        conversationId,
        {
          'isActive': isActive,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to toggle conversation archive: $e');
    }
  }

  /// Delete conversation
  ///
  /// This method will:
  /// 1. Find the conversation by ID
  /// 2. Delete all messages between the participants
  /// 3. Delete the conversation document itself
  ///
  /// Note: This action is irreversible and will permanently delete all data
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Get conversation details first
      final conversation = await getConversationById(conversationId);
      if (conversation == null) {
        throw Exception('Conversation not found');
      }

      // Delete all messages in the conversation first
      await _deleteMessagesBetweenUsers(
        conversation.ownerId,
        conversation.participantId,
      );

      // Delete the conversation
      await _firebaseProvider!.deleteDocument(_collection, conversationId);
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  /// Delete multiple conversations
  ///
  /// This method will delete multiple conversations in sequence.
  /// If any deletion fails, the error will be thrown and subsequent
  /// deletions will not be attempted.
  ///
  /// Note: This action is irreversible and will permanently delete all data
  Future<void> deleteMultipleConversations(List<String> conversationIds) async {
    try {
      for (final conversationId in conversationIds) {
        await deleteConversation(conversationId);
      }
    } catch (e) {
      throw Exception('Failed to delete conversations: $e');
    }
  }

  /// Delete conversation with participant (by user ID or email)
  ///
  /// This method will find and delete a conversation between the owner
  /// and the specified participant (can be user ID or email).
  ///
  /// Note: This action is irreversible and will permanently delete all data
  Future<void> deleteConversationWithParticipant(
      String ownerId, String participantIdOrEmail) async {
    try {
      // Find the conversation
      final conversation = await getConversation(ownerId, participantIdOrEmail);
      if (conversation == null) {
        throw Exception('Conversation not found');
      }

      // Delete the conversation
      await deleteConversation(conversation.id);
    } catch (e) {
      throw Exception('Failed to delete conversation with participant: $e');
    }
  }

  /// Delete all messages between two users
  Future<void> _deleteMessagesBetweenUsers(
      String user1Id, String user2Id) async {
    try {
      // Get all messages between the two users
      final messages = await _firebaseProvider!.getDocuments(
        'messages',
        filters: [
          MapEntry('senderId', user1Id),
          MapEntry('receiverId', user2Id),
        ],
      );

      // Also get messages in reverse direction
      final reverseMessages = await _firebaseProvider!.getDocuments(
        'messages',
        filters: [
          MapEntry('senderId', user2Id),
          MapEntry('receiverId', user1Id),
        ],
      );

      // Delete all messages
      final allMessages = [...messages.docs, ...reverseMessages.docs];
      for (final doc in allMessages) {
        await _firebaseProvider!.deleteDocument('messages', doc.id);
      }
    } catch (e) {
      throw Exception('Failed to delete messages between users: $e');
    }
  }

  /// Stream conversations for real-time updates (without indexing)
  Stream<List<Conversation>> streamConversationsForUser(String userId) {
    try {
      return _firebaseProvider!.listenToCollection(
        _collection,
        filters: [MapEntry('ownerId', userId)],
        // Removed orderBy to avoid indexing requirement
      ).asyncMap((querySnapshot) async {
        final conversations = <Conversation>[];

        for (final doc in querySnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final conversation = await _buildConversationFromData(doc.id, data);
            if (conversation != null) {
              conversations.add(conversation);
            }
          } catch (e) {
            // Skip problematic conversations
          }
        }

        // Sort conversations by updatedAt in descending order (latest first)
        conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return conversations;
      });
    } catch (e) {
      throw Exception('Failed to stream conversations: $e');
    }
  }

  /// Get active conversations only
  Future<List<Conversation>> getActiveConversations(String userId) async {
    try {
      final allConversations = await getConversationsForUser(userId);
      return allConversations.where((c) => c.isActive).toList();
    } catch (e) {
      throw Exception('Failed to get active conversations: $e');
    }
  }

  /// Get conversations without ordering (no indexing required)
  Future<List<Conversation>> getConversationsWithoutOrdering(
      String userId) async {
    try {
      final conversations = await _firebaseProvider!.getDocuments(
        _collection,
        filters: [MapEntry('ownerId', userId)],
        // No orderBy to avoid indexing
      );

      final List<Conversation> result = [];

      for (final doc in conversations.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final conversation = await _buildConversationFromData(doc.id, data);
        if (conversation != null) {
          result.add(conversation);
        }
      }

      // Sort in memory by updatedAt (latest first)
      result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return result;
    } catch (e) {
      throw Exception('Failed to get conversations without ordering: $e');
    }
  }

  /// Get recent conversations with limit (no indexing required)
  Future<List<Conversation>> getRecentConversations(String userId,
      {int limit = 10}) async {
    try {
      final conversations = await _firebaseProvider!.getDocuments(
        _collection,
        filters: [MapEntry('ownerId', userId)],
        limit: limit,
        // No orderBy to avoid indexing
      );

      final List<Conversation> result = [];

      for (final doc in conversations.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final conversation = await _buildConversationFromData(doc.id, data);
        if (conversation != null) {
          result.add(conversation);
        }
      }

      // Sort in memory and limit results
      result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return result.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to get recent conversations: $e');
    }
  }

  /// Stream conversations without ordering (no indexing required)
  Stream<List<Conversation>> streamConversationsWithoutOrdering(String userId) {
    try {
      return _firebaseProvider!.listenToCollection(
        _collection,
        filters: [MapEntry('ownerId', userId)],
        // No orderBy to avoid indexing
      ).asyncMap((querySnapshot) async {
        final conversations = <Conversation>[];

        for (final doc in querySnapshot.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>;
            final conversation = await _buildConversationFromData(doc.id, data);
            if (conversation != null) {
              conversations.add(conversation);
            }
          } catch (e) {
            // Skip problematic conversations
          }
        }

        // Sort in memory by updatedAt (latest first)
        conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return conversations;
      });
    } catch (e) {
      throw Exception('Failed to stream conversations without ordering: $e');
    }
  }

  /// Get archived conversations
  Future<List<Conversation>> getArchivedConversations(String userId) async {
    try {
      final allConversations = await getConversationsForUser(userId);
      return allConversations.where((c) => !c.isActive).toList();
    } catch (e) {
      throw Exception('Failed to get archived conversations: $e');
    }
  }
}
