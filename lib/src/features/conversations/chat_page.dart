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
  String _participantEmail = '';
  User? _participantUser;
  String? _contactName;
  String? _contactAvatar;
  bool _isLoading = false;
  String? _error;
  bool _isParticipantRegistered = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _initializeChat() async {
    // Use the chatId passed to the widget (this should be the contact ID)
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

      // Get contact details from owner's contacts using the participant's email
      final participantContact = await widget.serviceManager.contactService
          .getContactByEmailFromOwner(ownerUser.id, chatId);

      if (participantContact == null) {
        // Contact not found - but since they sent a message, they are registered
        // Get their user information first
        final participantUser = await serviceManager.contactService
            .getRegisteredUserByEmail(chatId);

        if (participantUser != null) {
          // User is registered, show dialog with their name
          if (mounted) {
            final displayName = participantUser.name?.isNotEmpty == true
                ? participantUser.name!
                : participantUser.displayName?.isNotEmpty == true
                    ? participantUser.displayName!
                    : chatId.split('@')[0]; // Fallback to email prefix

            final shouldAddContact =
                await _showAddContactDialog(displayName, chatId);
            if (mounted && shouldAddContact == true) {
              // Navigate to add contact page with pre-filled data
              Navigator.pushNamed(
                context,
                AppRoutes.addContact,
                arguments: {
                  'preFilledEmail': chatId, // chatId is the email
                  'preFilledName': displayName,
                  'returnToChatId': chatId, // Return to this chat after adding
                },
              );
              return; // Exit the method as we're navigating away
            } else if (mounted) {
              // User declined to add contact, go back
              // Navigator.pop(context);
              return;
            }
          }
        } else {
          // This shouldn't happen since they sent a message, but handle gracefully
          if (mounted) {
            final shouldAddContact =
                await _showAddContactDialog(chatId.split('@')[0], chatId);
            if (mounted && shouldAddContact == true) {
              // Navigate to add contact page with pre-filled data
              Navigator.pushNamed(
                context,
                AppRoutes.addContact,
                arguments: {
                  'preFilledEmail': chatId, // chatId is the email
                  'preFilledName':
                      chatId.split('@')[0], // Use email prefix as name
                  'returnToChatId': chatId, // Return to this chat after adding
                },
              );
              return; // Exit the method as we're navigating away
            } else if (mounted) {
              // User declined to add contact, go back
              // Navigator.pop(context);
              return;
            }
          }
        }
        return;
      }

      // Check if participant is registered
      final isRegistered = await serviceManager.contactService
          .isContactRegisteredUser(participantContact.email);

      User? participantUser;
      if (isRegistered) {
        participantUser = await serviceManager.contactService
            .getRegisteredUserByEmail(participantContact.email);
      }

      // Update UI with contact details immediately
      setState(() {
        _ownerId = ownerUser.id;
        _participantEmail = participantContact.email;
        _contactName = participantContact.name.isNotEmpty
            ? participantContact.name
            : participantContact.displayName.isNotEmpty
                ? participantContact.displayName
                : participantContact.email;
        _contactAvatar =
            _contactName!.isNotEmpty ? _contactName![0].toUpperCase() : 'U';
        _isParticipantRegistered = isRegistered;
        _participantUser = participantUser;
      });

      if (isRegistered) {
        // // Get or create conversation using email-based approach
        // final conversation = await serviceManager.conversationService
        //     .createOrGetConversationByEmail(
        //   ownerUser.email,
        //   _participantEmail,
        // );

        setState(() {
          _isLoading = true;
          _error = null;
        });

        // Set up real-time streaming using email-based approach
        _messageStream = serviceManager.messageService.streamMessagesByEmail(
          ownerUser.email,
          _participantEmail,
        );

        // Mark messages as read
        await serviceManager.messageService.markMessagesAsRead(
          ownerUser.email,
          _participantEmail,
        );

        setState(() {
          _isLoading = false;
        });
      } else {
        // Show unregistered user message
        setState(() {
          _isLoading = false;
        });
      }
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
      final ownerUser = widget.user;

      await serviceManager.messageService.sendMessage(
        ownerUser.email,
        _participantEmail, // This should be the participant's email
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contactName),
                  if (!_isParticipantRegistered)
                    Text(
                      'Not registered',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[400],
                      ),
                    ),
                ],
              ),
            ),
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
          if (_isParticipantRegistered) ...[
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
          ] else ...[
            IconButton(
              icon: const Icon(Icons.email),
              onPressed: () {
                _sendEmailToUnregisteredUser();
              },
            ),
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                _sendInvitationToUnregisteredUser();
              },
            ),
          ],
        ],
      ),
      body: _isParticipantRegistered
          ? Column(
              children: [
                Expanded(
                  child: _buildMessagesList(context),
                ),
                _buildMessageInput(context),
              ],
            )
          : _buildUnregisteredUserView(context),
    );
  }

  Widget _buildMessagesList(BuildContext context) {
    // Show loading state when still initializing
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

    // Show loading state when stream is not yet set up
    return const Center(
      child: CircularProgressIndicator(),
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
      reverse: true,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.from == currentUser.email;
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

  Widget _buildUnregisteredUserView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.email_outlined,
              size: 80,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Contact Not Registered',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_contactName ?? 'This contact'} is not registered on GBCC Connect App yet.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You can send them an email or invite them to join the app.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendEmailToUnregisteredUser,
                    icon: const Icon(Icons.email),
                    label: const Text('Send Email'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _sendInvitationToUnregisteredUser,
                    icon: const Icon(Icons.person_add),
                    label: const Text('Send Invitation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Contacts'),
            ),
          ],
        ),
      ),
    );
  }

  void _sendEmailToUnregisteredUser() async {
    try {
      final currentUser = widget.user;
      final fromName = currentUser.name ?? currentUser.displayName ?? 'User';

      final success =
          await widget.serviceManager.emailService.sendEmailToUnregisteredUser(
        toEmail: _participantEmail,
        fromName: fromName,
        fromEmail: currentUser.email,
        messageContent:
            'Hello ${_contactName ?? 'there'}, I would like to connect with you.',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email client opened successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open email client'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send email: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sendInvitationToUnregisteredUser() async {
    try {
      final currentUser = widget.user;
      final fromName = currentUser.name ?? currentUser.displayName ?? 'User';

      final success =
          await widget.serviceManager.emailService.sendInvitationEmail(
        toEmail: _participantEmail,
        fromName: fromName,
        fromEmail: currentUser.email,
        invitationMessage:
            'Hello ${_contactName ?? 'there'}, I would like to invite you to join GBCC Connect App so we can chat directly.',
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invitation email opened successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to open email client'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showAddContactDialog(String displayName, String email) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: MyApp.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text('Contact Not Found'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The contact:',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      displayName,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: MyApp.primaryColor,
                          ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'was not found in your contacts. Would you like to add them to your contacts?',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyApp.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Contact'),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
