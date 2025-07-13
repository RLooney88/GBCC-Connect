import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/providers/firebase_provider.dart';
import '../../core/models/contact.dart';

class ContactLibraryPage extends StatefulWidget {
  const ContactLibraryPage({super.key});

  static const routeName = AppRoutes.contactLibrary;

  @override
  State<ContactLibraryPage> createState() => _ContactLibraryPageState();
}

class _ContactLibraryPageState extends State<ContactLibraryPage> {
  @override
  void initState() {
    super.initState();
    // Load contacts when the page is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FirebaseProvider>().loadContacts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Library'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search functionality
            },
          ),
        ],
      ),
      body: Consumer<FirebaseProvider>(
        builder: (context, firebaseProvider, child) {
          // Check if user is authenticated
          if (firebaseProvider.currentUser == null) {
            return const Center(
              child: Text('Please log in to view contacts'),
            );
          }

          // Show loading state
          if (firebaseProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Show error state
          if (firebaseProvider.error != null) {
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
                    'Error loading contacts',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    firebaseProvider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => firebaseProvider.loadContacts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Show contacts list
          final contacts = firebaseProvider.contacts;

          if (contacts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No contacts yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first contact to get started',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.addContact),
                    child: const Text('Add Contact'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return _buildContactTile(context, contact);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addContact),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildContactTile(BuildContext context, Contact contact) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(contact.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (contact.chamberMember)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Chamber',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.position != null && contact.position!.isNotEmpty)
              Text(contact.position!),
            if (contact.company != null && contact.company!.isNotEmpty)
              Text(contact.company!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            if (contact.email.isNotEmpty)
              Text(contact.email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Favorite indicator
            if (contact.isFavorite)
              const Icon(
                Icons.favorite,
                color: Colors.red,
                size: 20,
              ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'message',
                  child: Row(
                    children: [
                      Icon(Icons.message),
                      SizedBox(width: 8),
                      Text('Message'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'call',
                  child: Row(
                    children: [
                      Icon(Icons.call),
                      SizedBox(width: 8),
                      Text('Call'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'favorite',
                  child: Row(
                    children: [
                      Icon(Icons.favorite_border),
                      SizedBox(width: 8),
                      Text('Toggle Favorite'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'chamber',
                  child: Row(
                    children: [
                      Icon(Icons.business),
                      SizedBox(width: 8),
                      Text('Toggle Chamber Member'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                final firebaseProvider = context.read<FirebaseProvider>();

                switch (value) {
                  case 'message':
                    Navigator.pushNamed(context, AppRoutes.chat, arguments: {
                      'contactName': contact.name,
                      'contactAvatar': contact.name.isNotEmpty
                          ? contact.name[0].toUpperCase()
                          : '?',
                    });
                    break;
                  case 'call':
                    // TODO: Implement call functionality
                    break;
                  case 'edit':
                    // TODO: Navigate to edit contact page
                    break;
                  case 'favorite':
                    try {
                      await firebaseProvider.toggleContactFavorite(
                          contact.id, !contact.isFavorite);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update favorite: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                    break;
                  case 'chamber':
                    try {
                      await firebaseProvider.updateContact(contact.copyWith(
                          chamberMember: !contact.chamberMember));
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Failed to update chamber status: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context, contact, firebaseProvider);
                    break;
                }
              },
            ),
          ],
        ),
        onTap: () {
          // TODO: Navigate to contact details page
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Contact contact,
      FirebaseProvider firebaseProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Contact'),
          content: Text('Are you sure you want to delete ${contact.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await firebaseProvider.deleteContact(contact.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contact deleted successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete contact: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
