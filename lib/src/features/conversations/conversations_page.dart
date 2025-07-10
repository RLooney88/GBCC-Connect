import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  static const routeName = AppRoutes.conversations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildConversationsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to new conversation page
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildConversationsList() {
    final conversations = [
      {
        'name': 'John Doe',
        'lastMessage': 'Hey, how are you?',
        'time': '2:30 PM',
        'unread': 2,
        'avatar': 'J'
      },
      {
        'name': 'Jane Smith',
        'lastMessage': 'Thanks for the info!',
        'time': '1:45 PM',
        'unread': 0,
        'avatar': 'J'
      },
      {
        'name': 'Mike Johnson',
        'lastMessage': 'Can we meet tomorrow?',
        'time': '12:20 PM',
        'unread': 1,
        'avatar': 'M'
      },
    ];

    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return _buildConversationTile(context, conversation);
      },
    );
  }

  Widget _buildConversationTile(
      BuildContext context, Map<String, dynamic> conversation) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            conversation['avatar'],
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(conversation['name'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          conversation['lastMessage'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(conversation['time'],
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (conversation['unread'] > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  conversation['unread'].toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.chat, arguments: {
            'contactName': conversation['name'],
            'contactAvatar': conversation['avatar'],
          });
        },
      ),
    );
  }
}
