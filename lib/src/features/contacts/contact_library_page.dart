import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';

class ContactLibraryPage extends StatelessWidget {
  const ContactLibraryPage({super.key});

  static const routeName = AppRoutes.contactLibrary;

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
      body: _buildContactsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addContact),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildContactsList() {
    // Mock contacts data
    final contacts = [
      {
        'name': 'John Doe',
        'position': 'Software Engineer',
        'company': 'Tech Corp',
        'avatar': 'J'
      },
      {
        'name': 'Jane Smith',
        'position': 'Product Manager',
        'company': 'Innovation Inc',
        'avatar': 'J'
      },
      {
        'name': 'Mike Johnson',
        'position': 'Designer',
        'company': 'Creative Studio',
        'avatar': 'M'
      },
      {
        'name': 'Sarah Wilson',
        'position': 'Marketing Director',
        'company': 'Growth Co',
        'avatar': 'S'
      },
      {
        'name': 'David Brown',
        'position': 'CEO',
        'company': 'Startup XYZ',
        'avatar': 'D'
      },
    ];

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _buildContactTile(context, contact);
      },
    );
  }

  Widget _buildContactTile(BuildContext context, Map<String, dynamic> contact) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            contact['avatar'],
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(contact['name'],
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact['position']),
            Text(contact['company'],
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
        trailing: PopupMenuButton(
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
          ],
          onSelected: (value) {
            switch (value) {
              case 'message':
                Navigator.pushNamed(context, AppRoutes.chat, arguments: {
                  'contactName': contact['name'],
                  'contactAvatar': contact['avatar'],
                });
                break;
              case 'call':
                // TODO: Implement call functionality
                break;
              case 'edit':
                // TODO: Navigate to edit contact page
                break;
            }
          },
        ),
        onTap: () {
          // TODO: Navigate to contact details page
        },
      ),
    );
  }
}
