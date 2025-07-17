import 'package:flutter/material.dart';
import '../../core/models/user.dart';
import '../../core/services/service_manager.dart';
import '../../core/models/message.dart';
import '../../core/routes/app_routes.dart';
import '../../app.dart';

class ChatPage extends StatefulWidget {
  final User user;
  final ServiceManager serviceManager;
  final String chatId;

  const ChatPage({
    super.key,
    required this.user,
    required this.serviceManager,
    required this.chatId,
  });

  static const routeName = AppRoutes.chat;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Stream<List<Message>>? _messageStream;
  String _ownerId = '';
  String _participantId = '';
  String? _contactName;
  String? _contactAvatar;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _initializeChat() async {
    // Use the chatId passed to the widget
    final chatId = widget.chatId;

    // Validate required parameter
    if (chatId.isEmpty) {
      setState(() {
        _error = 'Missing required chat parameter: chatId';
        _isLoading = false;
      });
      return;
    }

    try {
      // Use the ServiceManager provided by AuthenticatedPageWrapper
      final serviceManager = widget.serviceManager;

      // Use the user passed to the widget instead of AuthProvider
      final ownerUser = widget.user;
      final participantUser =
          await widget.serviceManager.contactService.getContactById(chatId);

      // Update UI with contact details immediately
      setState(() {
        _ownerId = ownerUser.id;
        _participantId =
            chatId; // We already validated chatId is not empty above
        _contactName = participantUser?.name ??
            participantUser?.displayName ??
            participantUser?.email;
        _contactAvatar = participantUser?.name.isNotEmpty == true
            ? participantUser!.name[0].toUpperCase()
            : 'U';
      });

      // get a conversation between owenerUser and participantUser
      final conversation =
          await serviceManager.conversationService.getConversationBetweenUsers(
        ownerUser.id,
        participantUser!.id,
      );

      // if no conversation, didn't get any message
      if (conversation == null) {
        return;
      }

      setState(() {
        _isLoading = true;
        _error = null;
      });

      // // Load initial messages
      // await serviceManager.messageService.getMessagesBetweenUsers(
      //   ownerUser.id,
      //   participantUser.id,
      // );

      // // Set up real-time streaming
      // _messageStream = serviceManager.messageService.streamMessagesBetweenUsers(
      //   ownerUser.id,
      //   participantUser.id,
      // );

      // // Mark messages as read
      // await serviceManager.messageService.markMessagesAsRead(
      //   ownerUser.id,
      //   participantUser.id,
      // );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final serviceManager = widget.serviceManager;

      await serviceManager.messageService.sendMessage(
        _ownerId,
        _participantId,
        _messageController.text.trim(),
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to send message: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactName = _contactName ?? "N/A";
    final contactAvatar = _contactAvatar ?? "";

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                contactAvatar,
                style: TextStyle(
                  color: MyApp.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(contactName),
          ],
        ),
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              _showCallFeature(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              _showVideoCallFeature(context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMessagesList(context),
          ),
          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    // Show loading state
    if (_isLoading && _messageStream == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Show error state
    if (_error != null && _messageStream == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading messages',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initializeChat(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Use stream for real-time updates if available
    if (_messageStream != null) {
      return StreamBuilder<List<Message>>(
        stream: _messageStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading messages',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final messages = snapshot.data!;
          return _buildMessagesListView(context, messages);
        },
      );
    }

    // Fallback to empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation by sending a message',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesListView(BuildContext context, List<Message> messages) {
    // Use the user passed to the widget instead of AuthProvider
    final currentUser = widget.user;

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation by sending a message',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUser.id;
        return _buildMessageBubble(context, message, isMe);
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, Message message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? MyApp.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 12,
                color: isMe ? Colors.white70 : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (messageDate == today) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25)),
                ),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
              onTap: () {
                // Scroll to bottom when user taps on input
                Future.delayed(const Duration(milliseconds: 300), () {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            onPressed: _isLoading ? null : _sendMessage,
            backgroundColor: MyApp.primaryColor,
            mini: true,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showCallFeature(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Call feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showVideoCallFeature(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Video call feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
