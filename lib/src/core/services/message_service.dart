import '../models/message.dart';
import 'firestore_service.dart';

class MessageService {
  static MessageService? _instance;
  static MessageService get instance =>
      _instance ??= MessageService._internal();

  MessageService._internal();

  final FirestoreService _firestoreService = FirestoreService.instance;
  static const String _collection = 'messages';

  /// Create a new message
  Future<String> createMessage(Message message) async {
    try {
      final docRef = await _firestoreService.createDocument(
        collection: _collection,
        data: message.toJson(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create message: $e');
    }
  }

  /// Get message by ID
  Future<Message?> getMessageById(String messageId) async {
    try {
      final doc = await _firestoreService.getDocument(
        collection: _collection,
        documentId: messageId,
      );

      if (doc != null && doc.exists) {
        return Message.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get message: $e');
    }
  }

  /// Update message
  Future<void> updateMessage(String messageId, Message message) async {
    try {
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: messageId,
        data: message.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  /// Delete message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestoreService.deleteDocument(
        collection: _collection,
        documentId: messageId,
      );
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Get conversation between two users
  Future<List<Message>> getConversation(String user1Id, String user2Id) async {
    try {
      // Get messages where user1 is sender and user2 is receiver
      final sentMessages = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [
          QueryFilter('senderId', user1Id),
          QueryFilter('receiverId', user2Id),
        ],
        orders: [QueryOrder('timestamp', descending: false)],
      );

      // Get messages where user2 is sender and user1 is receiver
      final receivedMessages = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [
          QueryFilter('senderId', user2Id),
          QueryFilter('receiverId', user1Id),
        ],
        orders: [QueryOrder('timestamp', descending: false)],
      );

      final allMessages = <Message>[];

      // Add sent messages
      for (final doc in sentMessages.docs) {
        allMessages.add(Message.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }));
      }

      // Add received messages
      for (final doc in receivedMessages.docs) {
        allMessages.add(Message.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }));
      }

      // Sort by timestamp
      allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return allMessages;
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  /// Get recent conversations for a user
  Future<List<Map<String, dynamic>>> getRecentConversations(
      String userId) async {
    try {
      // Get all messages where user is sender or receiver
      final sentMessages = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [QueryFilter('senderId', userId)],
        orders: [QueryOrder('timestamp', descending: true)],
      );

      final receivedMessages = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [QueryFilter('receiverId', userId)],
        orders: [QueryOrder('timestamp', descending: true)],
      );

      final conversationMap = <String, Map<String, dynamic>>{};

      // Process sent messages
      for (final doc in sentMessages.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final receiverId = data['receiverId'] as String;

        if (!conversationMap.containsKey(receiverId)) {
          conversationMap[receiverId] = {
            'userId': receiverId,
            'lastMessage': Message.fromJson({
              'id': doc.id,
              ...data,
            }),
            'unreadCount': 0,
          };
        }
      }

      // Process received messages
      for (final doc in receivedMessages.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final senderId = data['senderId'] as String;
        final isRead = data['isRead'] as bool? ?? false;

        if (!conversationMap.containsKey(senderId)) {
          conversationMap[senderId] = {
            'userId': senderId,
            'lastMessage': Message.fromJson({
              'id': doc.id,
              ...data,
            }),
            'unreadCount': isRead ? 0 : 1,
          };
        } else {
          final conversation = conversationMap[senderId]!;
          final lastMessage = conversation['lastMessage'] as Message;
          final message = Message.fromJson({
            'id': doc.id,
            ...data,
          });

          // Update if this message is more recent
          if (message.timestamp.isAfter(lastMessage.timestamp)) {
            conversation['lastMessage'] = message;
          }

          // Update unread count
          if (!isRead) {
            conversation['unreadCount'] =
                (conversation['unreadCount'] as int) + 1;
          }
        }
      }

      // Convert to list and sort by last message timestamp
      final conversations = conversationMap.values.toList();
      conversations.sort((a, b) {
        final aMessage = a['lastMessage'] as Message;
        final bMessage = b['lastMessage'] as Message;
        return bMessage.timestamp.compareTo(aMessage.timestamp);
      });

      return conversations;
    } catch (e) {
      throw Exception('Failed to get recent conversations: $e');
    }
  }

  /// Get unread messages count for a user
  Future<int> getUnreadMessagesCount(String userId) async {
    try {
      final querySnapshot = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [
          QueryFilter('receiverId', userId),
          QueryFilter('isRead', false),
        ],
      );

      return querySnapshot.docs.length;
    } catch (e) {
      throw Exception('Failed to get unread messages count: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String receiverId, String senderId) async {
    try {
      final querySnapshot = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [
          QueryFilter('receiverId', receiverId),
          QueryFilter('senderId', senderId),
          QueryFilter('isRead', false),
        ],
      );

      final batch = <BatchOperation>[];
      for (final doc in querySnapshot.docs) {
        batch.add(BatchOperation.update(
          collection: _collection,
          documentId: doc.id,
          data: {'isRead': true},
        ));
      }

      if (batch.isNotEmpty) {
        await _firestoreService.batchWrite(batch);
      }
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Mark a single message as read
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: messageId,
        data: {
          'isRead': true,
        },
      );
    } catch (e) {
      throw Exception('Failed to mark message as read: $e');
    }
  }

  /// Stream conversation in real-time
  Stream<List<Message>> streamConversation(String user1Id, String user2Id) {
    try {
      // Create a composite key for the conversation
      final conversationId = [user1Id, user2Id]..sort();
      final conversationKey = conversationId.join('_');

      return _firestoreService.streamDocuments(
        collection: _collection,
        filters: [
          QueryFilter('conversationKey', conversationKey),
        ],
        orders: [QueryOrder('timestamp', descending: false)],
      ).map((querySnapshot) {
        final messages = querySnapshot.docs.map((doc) {
          return Message.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
        }).toList();

        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return messages;
      });
    } catch (e) {
      throw Exception('Failed to stream conversation: $e');
    }
  }

  /// Stream recent conversations in real-time
  Stream<List<Map<String, dynamic>>> streamRecentConversations(String userId) {
    try {
      return _firestoreService.streamDocuments(
        collection: _collection,
        filters: [
          QueryFilter('participants', userId),
        ],
        orders: [QueryOrder('timestamp', descending: true)],
      ).asyncMap((querySnapshot) async {
        return await getRecentConversations(userId);
      });
    } catch (e) {
      throw Exception('Failed to stream recent conversations: $e');
    }
  }

  /// Search messages by content
  Future<List<Message>> searchMessages(String userId, String searchTerm) async {
    try {
      // Get all messages where user is sender or receiver
      final sentMessages = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [QueryFilter('senderId', userId)],
      );

      final receivedMessages = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [QueryFilter('receiverId', userId)],
      );

      final allMessages = <Message>[];

      // Add sent messages
      for (final doc in sentMessages.docs) {
        allMessages.add(Message.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }));
      }

      // Add received messages
      for (final doc in receivedMessages.docs) {
        allMessages.add(Message.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        }));
      }

      // Filter by search term
      return allMessages.where((message) {
        return message.content.toLowerCase().contains(searchTerm.toLowerCase());
      }).toList();
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  /// Delete conversation between two users
  Future<void> deleteConversation(String user1Id, String user2Id) async {
    try {
      // Get all messages in the conversation
      final conversation = await getConversation(user1Id, user2Id);

      final batch = <BatchOperation>[];
      for (final message in conversation) {
        batch.add(BatchOperation.delete(
          collection: _collection,
          documentId: message.id,
        ));
      }

      if (batch.isNotEmpty) {
        await _firestoreService.batchWrite(batch);
      }
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  /// Get message statistics for a user
  Future<Map<String, int>> getMessageStats(String userId) async {
    try {
      final sentMessages = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [QueryFilter('senderId', userId)],
      );

      final receivedMessages = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [QueryFilter('receiverId', userId)],
      );

      final unreadMessages = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [
          QueryFilter('receiverId', userId),
          QueryFilter('isRead', false),
        ],
      );

      return {
        'sent': sentMessages.docs.length,
        'received': receivedMessages.docs.length,
        'unread': unreadMessages.docs.length,
        'total': sentMessages.docs.length + receivedMessages.docs.length,
      };
    } catch (e) {
      throw Exception('Failed to get message stats: $e');
    }
  }
}
