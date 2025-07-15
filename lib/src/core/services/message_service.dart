import '../models/message.dart';
import '../models/conversation.dart';
import 'firestore_service.dart';
import 'conversation_service.dart';

class MessageService {
  static MessageService? _instance;
  static MessageService get instance =>
      _instance ??= MessageService._internal();

  MessageService._internal();

  final FirestoreService _firestoreService = FirestoreService.instance;
  final ConversationService _conversationService = ConversationService.instance;
  static const String _collection = 'messages';

  /// Send a message and update conversation
  Future<String> sendMessage(
    String senderId,
    String receiverId,
    String content, {
    String? attachmentUrl,
    String messageType = 'text',
  }) async {
    try {
      // Validate inputs
      if (senderId.isEmpty || receiverId.isEmpty) {
        throw Exception('Sender ID and receiver ID cannot be empty');
      }

      if (content.trim().isEmpty) {
        throw Exception('Message content cannot be empty');
      }

      if (senderId == receiverId) {
        throw Exception('Cannot send message to yourself');
      }

      // Create the message
      final message = Message(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        content: content.trim(),
        timestamp: DateTime.now(),
        isRead: false,
        attachmentUrl: attachmentUrl,
        messageType: messageType,
      );

      // Save the message
      final messageId = await createMessage(message);

      // Get or create conversation
      final conversation = await _conversationService.getOrCreateConversation(
          senderId, receiverId);

      // Update conversation with the new message
      final updatedMessage = message.copyWith(id: messageId);
      await _conversationService.updateConversationWithMessage(
          conversation.id, updatedMessage);

      return messageId;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

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

  /// Get messages between two users
  Future<List<Message>> getMessagesBetweenUsers(
      String user1Id, String user2Id) async {
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
        try {
          allMessages.add(Message.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          }));
        } catch (e) {
          print('Error parsing sent message ${doc.id}: $e');
        }
      }

      // Add received messages
      for (final doc in receivedMessages.docs) {
        try {
          allMessages.add(Message.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          }));
        } catch (e) {
          print('Error parsing received message ${doc.id}: $e');
        }
      }

      // Sort by timestamp
      allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      return allMessages;
    } catch (e) {
      throw Exception('Failed to get messages between users: $e');
    }
  }

  /// Get messages for a conversation
  Future<List<Message>> getMessagesForConversation(
      String conversationId) async {
    try {
      final conversation =
          await _conversationService.getConversationById(conversationId);
      if (conversation == null) {
        throw Exception('Conversation not found');
      }

      return await getMessagesBetweenUsers(
          conversation.ownerId, conversation.participantId);
    } catch (e) {
      throw Exception('Failed to get messages for conversation: $e');
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

  /// Mark messages as read between two users
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

      // Update conversation unread count
      final conversation =
          await _conversationService.getConversation(receiverId, senderId);
      if (conversation != null) {
        await _conversationService.markConversationAsRead(
            conversation.id, receiverId);
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

  /// Stream messages between two users in real-time
  Stream<List<Message>> streamMessagesBetweenUsers(
      String user1Id, String user2Id) {
    try {
      // Stream all messages where user1 is sender or receiver, then filter
      return _firestoreService.streamDocuments(
        collection: _collection,
        filters: [
          QueryFilter('senderId', user1Id),
        ],
        orders: [QueryOrder('timestamp', descending: false)],
      ).asyncMap((sentSnapshot) async {
        // Get received messages separately
        final receivedSnapshot = await _firestoreService.getDocuments(
          collection: _collection,
          filters: [
            QueryFilter('senderId', user2Id),
            QueryFilter('receiverId', user1Id),
          ],
          orders: [QueryOrder('timestamp', descending: false)],
        );

        final allMessages = <Message>[];

        // Add sent messages (only to user2)
        for (final doc in sentSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['receiverId'] == user2Id) {
            allMessages.add(Message.fromJson({
              'id': doc.id,
              ...data,
            }));
          }
        }

        // Add received messages (only from user2)
        for (final doc in receivedSnapshot.docs) {
          allMessages.add(Message.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          }));
        }

        // Sort by timestamp
        allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return allMessages;
      });
    } catch (e) {
      throw Exception('Failed to stream messages between users: $e');
    }
  }

  /// Stream messages for a conversation in real-time
  Stream<List<Message>> streamMessagesForConversation(String conversationId) {
    try {
      return _firestoreService.streamDocuments(
        collection: _collection,
        filters: [
          QueryFilter('conversationId', conversationId),
        ],
        orders: [QueryOrder('timestamp', descending: false)],
      ).map((querySnapshot) {
        final messages = <Message>[];

        for (final doc in querySnapshot.docs) {
          try {
            messages.add(Message.fromJson({
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            }));
          } catch (e) {
            print('Error parsing message ${doc.id}: $e');
          }
        }

        messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        return messages;
      }).handleError((error) {
        print('Error in streamMessagesForConversation: $error');
        return <Message>[];
      });
    } catch (e) {
      throw Exception('Failed to stream messages for conversation: $e');
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
      final conversation = await getMessagesBetweenUsers(user1Id, user2Id);

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

  /// Get messages by type (text, image, file, etc.)
  Future<List<Message>> getMessagesByType(
      String userId, String messageType) async {
    try {
      final sentMessages = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [
          QueryFilter('senderId', userId),
          QueryFilter('messageType', messageType),
        ],
      );

      final receivedMessages = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [
          QueryFilter('receiverId', userId),
          QueryFilter('messageType', messageType),
        ],
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
      allMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return allMessages;
    } catch (e) {
      throw Exception('Failed to get messages by type: $e');
    }
  }
}
