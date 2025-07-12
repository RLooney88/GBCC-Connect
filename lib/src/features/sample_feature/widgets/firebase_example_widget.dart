import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/firebase_provider.dart';
import '../../../core/models/user.dart';
import '../../../core/models/contact.dart';
import '../../../core/models/message.dart';

/// Example widget demonstrating Firebase service usage
class FirebaseExampleWidget extends StatefulWidget {
  const FirebaseExampleWidget({super.key});

  @override
  State<FirebaseExampleWidget> createState() => _FirebaseExampleWidgetState();
}

class _FirebaseExampleWidgetState extends State<FirebaseExampleWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize Firebase services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebaseProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Example'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<FirebaseProvider>().loadUsers();
              context.read<FirebaseProvider>().loadContacts();
            },
          ),
        ],
      ),
      body: Consumer<FirebaseProvider>(
        builder: (context, firebaseProvider, child) {
          if (firebaseProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (firebaseProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${firebaseProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      firebaseProvider.initialize();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current User Section
                _buildSection(
                  title: 'Current User',
                  child: firebaseProvider.currentUser != null
                      ? _buildUserCard(firebaseProvider.currentUser!)
                      : const Text('No user logged in'),
                ),

                const SizedBox(height: 24),

                // Create User Section
                _buildSection(
                  title: 'Create User',
                  child: _buildCreateUserForm(firebaseProvider),
                ),

                const SizedBox(height: 24),

                // Users Section
                _buildSection(
                  title: 'Users (${firebaseProvider.users.length})',
                  child: _buildUsersList(firebaseProvider.users),
                ),

                const SizedBox(height: 24),

                // Contacts Section
                _buildSection(
                  title: 'Contacts (${firebaseProvider.contacts.length})',
                  child: _buildContactsList(
                      firebaseProvider.contacts, firebaseProvider),
                ),

                const SizedBox(height: 24),

                // Messages Section
                _buildSection(
                  title: 'Messages (${firebaseProvider.messages.length})',
                  child: _buildMessagesList(firebaseProvider.messages),
                ),

                const SizedBox(height: 24),

                // Send Message Section
                _buildSection(
                  title: 'Send Message',
                  child: _buildSendMessageForm(firebaseProvider),
                ),

                const SizedBox(height: 24),

                // Statistics Section
                _buildSection(
                  title: 'Statistics',
                  child: _buildStatisticsSection(firebaseProvider),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      child: ListTile(
        title: Text(user.name),
        subtitle: Text(user.email),
        trailing: user.chamberMember
            ? const Icon(Icons.verified, color: Colors.blue)
            : null,
      ),
    );
  }

  Widget _buildCreateUserForm(FirebaseProvider provider) {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            if (_nameController.text.isNotEmpty &&
                _emailController.text.isNotEmpty) {
              final user = User(
                id: '',
                name: _nameController.text,
                email: _emailController.text,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await provider.createUser(user);
              _nameController.clear();
              _emailController.clear();
            }
          },
          child: const Text('Create User'),
        ),
      ],
    );
  }

  Widget _buildUsersList(List<User> users) {
    if (users.isEmpty) {
      return const Text('No users found');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return ListTile(
          title: Text(user.name),
          subtitle: Text(user.email),
          trailing: user.chamberMember
              ? const Icon(Icons.verified, color: Colors.blue)
              : null,
        );
      },
    );
  }

  Widget _buildContactsList(List<Contact> contacts, FirebaseProvider provider) {
    if (contacts.isEmpty) {
      return const Text('No contacts found');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return ListTile(
          title: Text(contact.name),
          subtitle: Text(contact.email),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (contact.isFavorite)
                const Icon(Icons.favorite, color: Colors.red),
              IconButton(
                icon: Icon(
                  contact.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: contact.isFavorite ? Colors.red : null,
                ),
                onPressed: () {
                  provider.toggleContactFavorite(
                      contact.id, !contact.isFavorite);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessagesList(List<Message> messages) {
    if (messages.isEmpty) {
      return const Text('No messages found');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return ListTile(
          title: Text(message.content),
          subtitle: Text(
              'From: ${message.senderId} • ${message.timestamp.toString()}'),
          trailing: message.isRead
              ? const Icon(Icons.done_all, color: Colors.blue)
              : const Icon(Icons.done, color: Colors.grey),
        );
      },
    );
  }

  Widget _buildSendMessageForm(FirebaseProvider provider) {
    return Column(
      children: [
        TextField(
          controller: _messageController,
          decoration: const InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            if (_messageController.text.isNotEmpty &&
                provider.currentUser != null) {
              final message = Message(
                id: '',
                senderId: provider.currentUser!.id,
                receiverId: 'example-receiver-id', // You would get this from UI
                content: _messageController.text,
                timestamp: DateTime.now(),
              );
              await provider.sendMessage(message);
              _messageController.clear();
            }
          },
          child: const Text('Send Message'),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection(FirebaseProvider provider) {
    return FutureBuilder<Map<String, dynamic>>(
      future: Future.wait([
        provider.getContactStats(),
        provider.getMessageStats(),
      ]).then((results) => {
            'contacts': results[0],
            'messages': results[1],
          }),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final stats = snapshot.data ?? {};
        final contactStats = stats['contacts'] as Map<String, int>? ?? {};
        final messageStats = stats['messages'] as Map<String, int>? ?? {};

        return Column(
          children: [
            _buildStatCard('Contacts', contactStats),
            const SizedBox(height: 8),
            _buildStatCard('Messages', messageStats),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, Map<String, int> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...stats.entries.map((entry) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key),
                      Text(entry.value.toString()),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
