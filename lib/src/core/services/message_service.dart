import 'package:flutter/foundation.dart'; // Added for debugPrint
import '../models/message.dart';
import '../models/user.dart';
import '../providers/firebase_provider.dart';
import 'conversation_service.dart';

/// Domain/Business Logic Layer: MessageService
/// Mission: Implement message-specific logic and transform data for the UI
/// - Business logic for messages (sending, fetching, updating, deleting, etc.)
/// - Pure Dart code (no Flutter imports)
/// - Abstracts over FirebaseProvider or any data source
/// - Handles data mapping/DTOs if necessary
class MessageService {
  static MessageService? _instance;
  static MessageService get instance =>
      _instance ??= MessageService._internal();

  MessageService._internal();

  FirebaseProvider? _firebaseProvider;
  ConversationService? _conversationService;
  static const String _collection = 'messages';

  /// Initialize the service with FirebaseProvider
  Future<void> initialize(FirebaseProvider firebaseProvider) async {
    _firebaseProvider = firebaseProvider;
    _conversationService = ConversationService.instance;
  }

  /// Send a message between two users by email
  /// This works for both registered and unregistered users
  Future<Message> sendMessage(
    String fromEmail,
    String toEmail,
    String content, {
    String? attachmentUrl,
    String messageType = 'text',
  }) async {
    try {
      // Create or get conversation using ConversationService
      final conversation =
          await _conversationService!.createOrGetConversationByEmail(
        fromEmail,
        toEmail,
      );

      // // Get user details
      // final fromUser = await _getUserByEmail(fromEmail);
      // final toUser = await _getUserByEmail(toEmail);

      // Create message
      final message = Message(
        id: '', // Will be set by Firestore
        conversationId: conversation.id,
        from: fromEmail,
        to: toEmail,
        content: content,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
        attachmentUrl: attachmentUrl,
        messageType: messageType,
      );

      // Save message to Firestore
      final messageRef = await _firebaseProvider!.createDocument(
        _collection,
        message.toJson(),
      );

      // Update message with generated ID
      final messageWithId = message.copyWith(id: messageRef.id);

      // Update conversation with last message using ConversationService
      await _conversationService!.updateConversationWithMessage(
        conversation.id,
        messageWithId,
      );

      // Update unread count for recipient
      await _updateUnreadCountForRecipient(conversation.id, toEmail);

      return messageWithId;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send a message between two users by user IDs (for registered users)
  Future<Message> sendMessageBetweenUsers(
    String fromUserId,
    String toUserId,
    String content, {
    String? attachmentUrl,
    String messageType = 'text',
  }) async {
    try {
      // Get user emails
      final fromUser = await _getUserById(fromUserId);
      final toUser = await _getUserById(toUserId);

      if (fromUser == null || toUser == null) {
        throw Exception('User not found');
      }

      return await sendMessage(
        fromUser.email,
        toUser.email,
        content,
        attachmentUrl: attachmentUrl,
        messageType: messageType,
      );
    } catch (e) {
      throw Exception('Failed to send message between users: $e');
    }
  }

  /// Get messages between two users by email
  Future<List<Message>> getMessagesByEmail(
    String user1Email,
    String user2Email,
  ) async {
    try {
      final conversation = await _conversationService!.getConversationByEmail(
        user1Email,
        user2Email,
      );

      if (conversation == null) return [];

      final filters = [MapEntry('conversationId', conversation.id)];
      final querySnapshot = await _firebaseProvider!.getDocuments(
        _collection,
        filters: filters,
        orderBy: 'timestamp',
        descending: true,
        limit: 50, // Limit to last 50 messages
      );

      return querySnapshot.docs.map((doc) {
        return Message.fromJson({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Get messages between two users by user IDs
  Future<List<Message>> getMessagesBetweenUsers(
    String user1Id,
    String user2Id,
  ) async {
    try {
      final user1 = await _getUserById(user1Id);
      final user2 = await _getUserById(user2Id);

      if (user1 == null || user2 == null) {
        throw Exception('User not found');
      }

      return await getMessagesByEmail(user1.email, user2.email);
    } catch (e) {
      throw Exception('Failed to get messages between users: $e');
    }
  }

  /// Stream messages between two users by email
  Stream<List<Message>> streamMessagesByEmail(
    String user1Email,
    String user2Email,
  ) {
    try {
      final conversationId = _getConversationId(user1Email, user2Email);
      final filters = [MapEntry('conversationId', conversationId)];

      return _firebaseProvider!
          .listenToCollection(
        _collection,
        filters: filters,
        orderBy: 'timestamp',
        descending: true,
      )
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return Message.fromJson({
            'id': doc.id,
            ...(doc.data() as Map<String, dynamic>),
          });
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to stream messages: $e');
    }
  }

  /// Stream messages between two users by user IDs
  Stream<List<Message>> streamMessagesBetweenUsers(
    String user1Id,
    String user2Id,
  ) async* {
    try {
      final user1 = await _getUserById(user1Id);
      final user2 = await _getUserById(user2Id);

      if (user1 == null || user2 == null) {
        throw Exception('User not found');
      }

      yield* streamMessagesByEmail(user1.email, user2.email);
    } catch (e) {
      throw Exception('Failed to stream messages between users: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(
    String user1Email,
    String user2Email,
  ) async {
    try {
      final conversation = await _conversationService!.getConversationByEmail(
        user1Email,
        user2Email,
      );

      if (conversation == null) return;

      // Mark conversation as read using ConversationService
      await _conversationService!.markConversationAsRead(conversation.id);

      // Update message status to read
      final filters = [
        MapEntry('conversationId', conversation.id),
        MapEntry('to', user1Email),
        MapEntry('status', MessageStatus.delivered.name),
      ];

      final messagesQuery = await _firebaseProvider!.getDocuments(
        _collection,
        filters: filters,
      );

      for (final doc in messagesQuery.docs) {
        await _firebaseProvider!.updateDocument(
          _collection,
          doc.id,
          {'status': MessageStatus.read.name},
        );
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Mark messages as read by user IDs
  Future<void> markMessagesAsReadBetweenUsers(
    String user1Id,
    String user2Id,
  ) async {
    try {
      final user1 = await _getUserById(user1Id);
      final user2 = await _getUserById(user2Id);

      if (user1 == null || user2 == null) {
        throw Exception('User not found');
      }

      await markMessagesAsRead(user1.email, user2.email);
    } catch (e) {
      throw Exception('Failed to mark messages as read between users: $e');
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firebaseProvider!.deleteDocument(_collection, messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Delete all messages in a conversation
  Future<void> deleteMessagesInConversation(String conversationId) async {
    try {
      final filters = [MapEntry('conversationId', conversationId)];
      final messagesQuery = await _firebaseProvider!.getDocuments(
        _collection,
        filters: filters,
      );

      for (final doc in messagesQuery.docs) {
        await _firebaseProvider!.deleteDocument(_collection, doc.id);
      }
    } catch (e) {
      throw Exception('Failed to delete messages in conversation: $e');
    }
  }

  /// Update message status
  Future<void> updateMessageStatus(
    String messageId,
    MessageStatus status,
  ) async {
    try {
      await _firebaseProvider!.updateDocument(
        _collection,
        messageId,
        {'status': status.name},
      );
    } catch (e) {
      throw Exception('Failed to update message status: $e');
    }
  }

  /// Get conversation ID from two emails
  String _getConversationId(String email1, String email2) {
    final emails = [email1, email2]..sort();
    return '${emails[0]}_${emails[1]}';
  }

  /// Update unread count for recipient
  Future<void> _updateUnreadCountForRecipient(
    String conversationId,
    String recipientEmail,
  ) async {
    try {
      final conversationDoc = await _firebaseProvider!.getDocument(
        'conversations',
        conversationId,
      );

      if (conversationDoc == null || !conversationDoc.exists) return;

      final data = conversationDoc.data() as Map<String, dynamic>;
      int currentUnreadCount = data['unreadCount'] ?? 0;

      // Only increment if the recipient is the owner of this conversation view
      if (data['ownerId'] == recipientEmail) {
        currentUnreadCount++;
        await _conversationService!
            .updateUnreadCount(conversationId, currentUnreadCount);
      }
    } catch (e) {
      // Log error but don't throw to avoid breaking message sending
      debugPrint('Failed to update unread count: $e');
    }
  }

  /// Get user by ID
  Future<User?> _getUserById(String userId) async {
    try {
      final doc = await _firebaseProvider!.getDocument('users', userId);

      if (doc != null && doc.exists) {
        return User.fromJson({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Migrate messages when a contact registers
  /// This updates messages to use user IDs instead of emails
  Future<void> migrateMessagesToUserIds(
    String userEmail,
    String userId,
  ) async {
    try {
      // Update messages where user is sender
      final senderFilters = [MapEntry('from', userEmail)];
      final senderQuery = await _firebaseProvider!.getDocuments(
        _collection,
        filters: senderFilters,
      );

      for (final doc in senderQuery.docs) {
        await _firebaseProvider!.updateDocument(
          _collection,
          doc.id,
          {'from': userId},
        );
      }

      // Update messages where user is recipient
      final recipientFilters = [MapEntry('to', userEmail)];
      final recipientQuery = await _firebaseProvider!.getDocuments(
        _collection,
        filters: recipientFilters,
      );

      for (final doc in recipientQuery.docs) {
        await _firebaseProvider!.updateDocument(
          _collection,
          doc.id,
          {'to': userId},
        );
      }
    } catch (e) {
      throw Exception('Failed to migrate messages: $e');
    }
  }

  /// Validate message data
  bool validateMessage(Message message) {
    if (message.content.trim().isEmpty) return false;
    if (message.from.isEmpty) return false;
    if (message.to.isEmpty) return false;
    if (message.conversationId.isEmpty) return false;
    return true;
  }

  /// Get message statistics
  Future<Map<String, int>> getMessageStats(String userEmail) async {
    try {
      final sentFilters = [MapEntry('from', userEmail)];
      final receivedFilters = [MapEntry('to', userEmail)];

      final sentQuery = await _firebaseProvider!.getDocuments(
        _collection,
        filters: sentFilters,
      );

      final receivedQuery = await _firebaseProvider!.getDocuments(
        _collection,
        filters: receivedFilters,
      );

      return {
        'sent': sentQuery.docs.length,
        'received': receivedQuery.docs.length,
        'total': sentQuery.docs.length + receivedQuery.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get message stats: $e');
    }
  }

  /// Get unread messages count
  /// If fromEmail is provided, counts messages from that specific sender
  /// If fromEmail is not provided, counts all unread messages for the recipient
  Future<int> unreadMessages(String toEmail, {String? fromEmail}) async {
    try {
      int totalCount = 0;

      // Query for messages with status 'sent'
      List<MapEntry<String, dynamic>> sentFilters = [
        MapEntry('to', toEmail),
        MapEntry('status', MessageStatus.sent.name),
      ];

      if (fromEmail != null) {
        sentFilters.add(MapEntry('from', fromEmail));
      }

      final sentQuery = await _firebaseProvider!.getDocuments(
        _collection,
        filters: sentFilters,
      );

      totalCount += sentQuery.docs.length;

      return totalCount;
    } catch (e) {
      throw Exception('Failed to get unread messages count: $e');
    }
  }
}
