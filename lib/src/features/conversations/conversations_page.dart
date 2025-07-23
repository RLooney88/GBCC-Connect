import 'package:flutter/material.dart';
import '../../core/models/user.dart';
import '../../core/services/service_manager.dart';
import '../../core/models/conversation.dart';
import '../../core/routes/app_routes.dart';
import '../../app.dart';

class ConversationsPage extends StatefulWidget {
  final User user;
  final ServiceManager serviceManager;

  const ConversationsPage({
    super.key,
    required this.user,
    required this.serviceManager,
  });

  static const routeName = AppRoutes.conversations;

  @override
  State<ConversationsPage> createState() => _ConversationsPageState();
}

class _ConversationsPageState extends State<ConversationsPage> {
  Stream<List<Conversation>>? _conversationsStream;
  bool _isLoading = false;
  String? _error;
  final Set<String> _deletingConversations = {};
  bool _isSelectionMode = false;
  final Set<String> _selectedConversations = {};
  List<Conversation> _currentConversations =
      []; // Add this field to track current conversations

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  void _loadConversations() async {
    // Use the user passed to the widget instead of AuthProvider
    final currentUser = widget.user;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use the ServiceManager provided by AuthenticatedPageWrapper
      final serviceManager = widget.serviceManager;

      // Set up real-time streaming for conversations using email
      // This will show conversations where the user is either owner or participant
      _conversationsStream =
          serviceManager.conversationService.streamConversationsForUser(
        currentUser.email, // Use email for conversation lookup
      );

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

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedConversations.clear();
      }
    });
  }

  /// Select all conversations
  void _selectAllConversations() {
    setState(() {
      _selectedConversations.clear();
      for (final conversation in _currentConversations) {
        _selectedConversations.add(conversation.id);
      }
    });
  }

  /// Deselect all conversations
  void _deselectAllConversations() {
    setState(() {
      _selectedConversations.clear();
    });
  }

  /// Toggle between select all and deselect all
  void _toggleSelectAll() {
    if (_selectedConversations.length == _currentConversations.length) {
      _deselectAllConversations();
    } else {
      _selectAllConversations();
    }
  }

  /// Toggle conversation selection
  void _toggleConversationSelection(String conversationId) {
    setState(() {
      if (_selectedConversations.contains(conversationId)) {
        _selectedConversations.remove(conversationId);
      } else {
        _selectedConversations.add(conversationId);
      }
    });
  }

  /// Delete selected conversations
  Future<void> _deleteSelectedConversations() async {
    if (_selectedConversations.isEmpty) return;

    final confirmed = await _showBulkDeleteConfirmationDialog();
    if (!confirmed) return;

    setState(() {
      _deletingConversations.addAll(_selectedConversations);
    });

    try {
      await widget.serviceManager.conversationService
          .deleteMultipleConversations(
        _selectedConversations.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${_selectedConversations.length} conversation(s) deleted'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete conversations: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingConversations.removeAll(_selectedConversations);
          _selectedConversations.clear();
          _isSelectionMode = false;
        });
      }
    }
  }

  /// Show bulk delete confirmation dialog
  Future<bool> _showBulkDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Conversations'),
              content: Text(
                'Are you sure you want to delete ${_selectedConversations.length} conversation(s)? '
                'This action cannot be undone and will delete all messages.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Delete conversation with confirmation
  Future<void> _deleteConversation(Conversation conversation) async {
    final confirmed = await _showDeleteConfirmationDialog(conversation);
    if (!confirmed) return;

    setState(() {
      _deletingConversations.add(conversation.id);
    });

    try {
      await widget.serviceManager.conversationService
          .deleteConversation(conversation.id);

      // Show success message
      if (mounted) {
        final otherUserName = conversation.getDisplayName(widget.user.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversation with $otherUserName deleted'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete conversation: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _deletingConversations.remove(conversation.id);
        });
      }
    }
  }

  /// Show delete confirmation dialog
  Future<bool> _showDeleteConfirmationDialog(Conversation conversation) async {
    final otherUserName = conversation.getDisplayName(widget.user.id);

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Delete Conversation'),
              content: Text(
                'Are you sure you want to delete your conversation with $otherUserName? '
                'This action cannot be undone and will delete all messages.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Archive conversation instead of deleting
  Future<void> _archiveConversation(Conversation conversation) async {
    try {
      await widget.serviceManager.conversationService.toggleConversationArchive(
        conversation.id,
        false, // Set to inactive (archived)
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Conversation archived'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to archive conversation: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Show conversation options menu
  void _showConversationOptions(Conversation conversation) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text('Archive Conversation'),
                onTap: () {
                  Navigator.pop(context);
                  _archiveConversation(conversation);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Conversation',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteConversation(conversation);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAllSelected = _currentConversations.isNotEmpty &&
        _selectedConversations.length == _currentConversations.length;

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text(isAllSelected
                ? 'All conversations selected'
                : '${_selectedConversations.length} selected')
            : const Text('Conversations'),
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
        actions: [
          if (_isSelectionMode) ...[
            if (_selectedConversations.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _deleteSelectedConversations,
                tooltip: 'Delete Selected',
              ),
            ],
          ] else ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: 'Select Conversations',
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? _buildLoadingView()
            : _error != null
                ? _buildErrorView(context, _error!)
                : _buildConversationsList(context, widget.user),
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.contactSelection);
              },
              backgroundColor: MyApp.primaryColor,
              child: const Icon(Icons.chat, color: Colors.white),
            ),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar() : null,
    );
  }

  /// Build bottom bar for selection mode
  Widget _buildSelectionBottomBar() {
    final isAllSelected = _currentConversations.isNotEmpty &&
        _selectedConversations.length == _currentConversations.length;

    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            TextButton.icon(
              onPressed:
                  _currentConversations.isNotEmpty ? _toggleSelectAll : null,
              icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all),
              label: Text(isAllSelected ? 'Deselect All' : 'Select All'),
              style: TextButton.styleFrom(
                foregroundColor: MyApp.primaryColor,
              ),
            ),
            const Spacer(),
            if (_selectedConversations.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _deleteSelectedConversations,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete),
                label: Text('Delete (${_selectedConversations.length})'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading conversations...'),
        ],
      ),
    );
  }

  Widget _buildErrorView(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.red[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.red[500],
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _loadConversations(),
            style: ElevatedButton.styleFrom(
              backgroundColor: MyApp.primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(BuildContext context, dynamic user) {
    // Use stream for real-time updates if available
    if (_conversationsStream != null) {
      return StreamBuilder<List<Conversation>>(
        stream: _conversationsStream,
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
                    'Error loading conversations',
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

          _currentConversations = snapshot.data!; // Update the field
          return _buildConversationsListView(context, snapshot.data!, user);
        },
      );
    }

    // Fallback to empty state
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No Conversations Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with your contacts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsListView(
      BuildContext context, List<Conversation> conversations, dynamic user) {
    // Update the current conversations list
    _currentConversations = conversations;

    if (conversations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No Conversations Yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start a conversation with your contacts',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.contactSelection);
              },
              icon: const Icon(Icons.add),
              label: const Text('Start New Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: MyApp.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        _loadConversations();
      },
      child: ListView.builder(
        itemCount: conversations.length,
        itemBuilder: (context, index) {
          final conversation = conversations[index];
          return _buildConversationTile(context, conversation, user);
        },
      ),
    );
  }

  Widget _buildConversationTile(
      BuildContext context, Conversation conversation, dynamic user) {
    // Use the conversation's getOtherUser method to get the other person from current user's perspective
    final otherUser = conversation.getOtherUser(widget.user.id);

    // Use the conversation's getDisplayName method to get the proper display name
    final displayName = conversation.getDisplayName(widget.user.id);

    final avatar = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final lastMessage = conversation.lastMessage?.content ?? 'No messages yet';
    final time = _formatTime(conversation.updatedAt);
    final unreadCount = 0;
    final isDeleting = _deletingConversations.contains(conversation.id);
    final isSelected = _selectedConversations.contains(conversation.id);

    // Check if the other user is registered (if we have other user data)
    final isOtherUserRegistered = otherUser != null && otherUser.id.isNotEmpty;

    Widget tileContent = Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: Stack(
        children: [
          ListTile(
            leading: _isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      _toggleConversationSelection(conversation.id);
                    },
                    activeColor: MyApp.primaryColor,
                  )
                : CircleAvatar(
                    backgroundColor: MyApp.primaryColor,
                    child: Text(
                      avatar,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
            title: Row(
              children: [
                Expanded(
                  child: Text(displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                if (!isOtherUserRegistered)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Email',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isOtherUserRegistered)
                  Text(
                    'Contact not registered - messages sent via email',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(time,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                if (unreadCount > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            onTap: _isSelectionMode
                ? () => _toggleConversationSelection(conversation.id)
                : () async {
                    // Get the other user's email for navigation
                    final otherUser = conversation.getOtherUser(widget.user.id);
                    final chatId = otherUser?.email ??
                        conversation.getOtherUserId(widget.user.id);

                    // Use a post-frame callback to ensure the context is valid
                    if (mounted) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.chat,
                            arguments: {'chatId': chatId},
                          );
                        }
                      });
                    }
                  },
            onLongPress: _isSelectionMode
                ? null
                : () {
                    _showConversationOptions(conversation);
                  },
          ),
          if (isDeleting)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // Only wrap with Dismissible if not in selection mode
    if (!_isSelectionMode) {
      return Dismissible(
        key: Key(conversation.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await _showDeleteConfirmationDialog(conversation);
        },
        onDismissed: (direction) {
          _deleteConversation(conversation);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          color: Colors.red,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete,
                color: Colors.white,
              ),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        child: tileContent,
      );
    }

    return tileContent;
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
}
