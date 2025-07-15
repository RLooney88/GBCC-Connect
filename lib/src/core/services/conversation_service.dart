import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import 'firestore_service.dart';
import 'user_service.dart';
import 'message_service.dart';

class ConversationService {
  static ConversationService? _instance;
  static ConversationService get instance =>
      _instance ??= ConversationService._internal();

  ConversationService._internal();

  final FirestoreService _firestoreService = FirestoreService.instance;
  final UserService _userService = UserService.instance;
  final MessageService _messageService = MessageService.instance;
  static const String _collection = 'conversations';

  /// Get all conversations for a user (where user is the owner)
  Future<List<Conversation>> getConversationsForUser(String userId) async {
    try {
      // Get conversations where user is the owner
      final conversations = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [QueryFilter('ownerId', userId)],
        orders: [QueryOrder('updatedAt', descending: true)],
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
      throw Exception('Failed to get conversations: $e');
    }
  }

  /// Get conversation between two users (from owner's perspective)
  Future<Conversation?> getConversation(
      String ownerId, String participantId) async {
    try {
      // Find conversation where ownerId and participantId match
      final conversations = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [
          QueryFilter('ownerId', ownerId),
          QueryFilter('participantId', participantId),
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

  /// Get or create conversation between two users
  Future<Conversation> getOrCreateConversation(
      String user1Id, String user2Id) async {
    try {
      if (user1Id.isEmpty || user2Id.isEmpty) {
        throw Exception('User IDs cannot be empty');
      }

      if (user1Id == user2Id) {
        throw Exception('Cannot create conversation with yourself');
      }

      // Try to find conversation where user1 is owner and user2 is participant
      Conversation? conversation = await getConversation(user1Id, user2Id);

      if (conversation != null) {
        return conversation;
      }

      // Try to find conversation where user2 is owner and user1 is participant
      conversation = await getConversation(user2Id, user1Id);

      if (conversation != null) {
        return conversation;
      }

      // Create new conversation with user1 as owner and user2 as participant
      return await createConversation(user1Id, user2Id);
    } catch (e) {
      throw Exception('Failed to get or create conversation: $e');
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
        await _firestoreService.updateDocument(
          collection: _collection,
          documentId: existingConversation.id,
          data: conversation.toJson(),
        );
        return existingConversation.id;
      } else {
        // Create new conversation
        final docRef = await _firestoreService.createDocument(
          collection: _collection,
          data: conversation.toJson(),
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
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: conversationId,
        data: {
          'lastMessageId': message.id,
          'lastMessage': message.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw Exception('Failed to update conversation with message: $e');
    }
  }

  /// Get unread message count for a user
  Future<int> getUnreadMessageCount(String userId) async {
    try {
      final unreadMessages = await _firestoreService.getDocuments(
        collection: 'messages',
        filters: [
          QueryFilter('receiverId', userId),
          QueryFilter('isRead', false),
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

      final unreadMessages = await _firestoreService.getDocuments(
        collection: 'messages',
        filters: [
          QueryFilter('senderId', otherUserId),
          QueryFilter('receiverId', userId),
          QueryFilter('isRead', false),
        ],
      );

      // Mark all messages as read
      for (final doc in unreadMessages.docs) {
        await _messageService.updateMessage(
            doc.id,
            Message.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
              'isRead': true,
            }));
      }

      // Update conversation unread count
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: conversationId,
        data: {
          'unreadCount': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw Exception('Failed to mark conversation as read: $e');
    }
  }

  /// Get conversation by ID
  Future<Conversation?> getConversationById(String conversationId) async {
    try {
      final doc = await _firestoreService.getDocument(
        collection: _collection,
        documentId: conversationId,
      );

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
        print(
            'Warning: Missing ownerId or participantId in conversation $docId');
        return null;
      }

      User? owner;
      User? participant;

      // Get owner details
      if (data['owner'] != null && data['owner'] is Map<String, dynamic>) {
        try {
          owner = User.fromJson(data['owner'] as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing owner data for conversation $docId: $e');
          // Fallback to fetching from service
          owner = await _userService.getUserById(ownerId);
        }
      } else {
        owner = await _userService.getUserById(ownerId);
      }

      // Get participant details
      if (data['participant'] != null &&
          data['participant'] is Map<String, dynamic>) {
        try {
          participant =
              User.fromJson(data['participant'] as Map<String, dynamic>);
        } catch (e) {
          print('Error parsing participant data for conversation $docId: $e');
          // Fallback to fetching from service
          participant = await _userService.getUserById(participantId);
        }
      } else {
        participant = await _userService.getUserById(participantId);
      }

      // Skip conversation if we can't get user data
      if (owner == null || participant == null) {
        print('Warning: Could not fetch user data for conversation $docId');
        return null;
      }

      // Get last message
      Message? lastMessage;
      if (data['lastMessageId'] != null) {
        try {
          lastMessage =
              await _messageService.getMessageById(data['lastMessageId']);
        } catch (e) {
          print('Error fetching last message for conversation $docId: $e');
          // Continue without last message
        }
      }

      return Conversation.fromJson({
        'id': docId,
        'ownerId': ownerId,
        'participantId': participantId,
        'owner': owner.toJson(),
        'participant': participant.toJson(),
        'lastMessage': lastMessage?.toJson(),
        'unreadCount': data['unreadCount'] ?? 0,
        'createdAt': data['createdAt'],
        'updatedAt': data['updatedAt'],
        'isActive': data['isActive'] ?? true,
      });
    } catch (e) {
      print('Error building conversation from data for $docId: $e');
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
      final owner = await _userService.getUserById(ownerId);
      final participant = await _userService.getUserById(participantId);

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

      final docRef = await _firestoreService.createDocument(
        collection: _collection,
        data: conversation.toJson(),
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
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: conversationId,
        data: {
          'isActive': isActive,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw Exception('Failed to toggle conversation archive: $e');
    }
  }

  /// Delete conversation
  Future<void> deleteConversation(String conversationId) async {
    try {
      // Delete all messages in the conversation first
      final conversation = await getConversationById(conversationId);
      if (conversation != null) {
        // Delete messages between the two users
        await _deleteMessagesBetweenUsers(
          conversation.ownerId,
          conversation.participantId,
        );
      }

      // Delete the conversation
      await _firestoreService.deleteDocument(
        collection: _collection,
        documentId: conversationId,
      );
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  /// Delete all messages between two users
  Future<void> _deleteMessagesBetweenUsers(
      String user1Id, String user2Id) async {
    try {
      // Get all messages between the two users
      final messages = await _firestoreService.getDocuments(
        collection: 'messages',
        filters: [
          QueryFilter('senderId', user1Id),
          QueryFilter('receiverId', user2Id),
        ],
      );

      // Also get messages in reverse direction
      final reverseMessages = await _firestoreService.getDocuments(
        collection: 'messages',
        filters: [
          QueryFilter('senderId', user2Id),
          QueryFilter('receiverId', user1Id),
        ],
      );

      // Delete all messages
      final allMessages = [...messages.docs, ...reverseMessages.docs];
      for (final doc in allMessages) {
        await _firestoreService.deleteDocument(
          collection: 'messages',
          documentId: doc.id,
        );
      }
    } catch (e) {
      throw Exception('Failed to delete messages between users: $e');
    }
  }

  /// Stream conversations for real-time updates
  Stream<List<Conversation>> streamConversationsForUser(String userId) {
    try {
      return _firestoreService.streamDocuments(
        collection: _collection,
        filters: [QueryFilter('ownerId', userId)],
        orders: [QueryOrder('updatedAt', descending: true)],
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
            print('Error processing conversation ${doc.id}: $e');
          }
        }

        return conversations;
      }).handleError((error) {
        print('Error in streamConversationsForUser: $error');
        return <Conversation>[];
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
