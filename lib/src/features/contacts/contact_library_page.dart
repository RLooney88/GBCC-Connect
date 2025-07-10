import 'package:flutter/material.dart';
import '../../core/models/contact.dart';
import '../../core/models/user.dart';

class ContactLibraryPage extends StatefulWidget {
  const ContactLibraryPage({super.key});

  static const routeName = '/contact-library';

  @override
  State<ContactLibraryPage> createState() => _ContactLibraryPageState();
}

class _ContactLibraryPageState extends State<ContactLibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadContacts() {
    // Simulated contact data
    _contacts = [
      Contact(
        id: '1',
        ownerId: 'current-user-id',
        owner: User(
          id: 'current-user-id',
          name: 'Current User',
          email: 'current@user.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        name: 'John Doe',
        email: 'john.doe@example.com',
        phone: '+1234567890',
        company: 'Tech Corp',
        position: 'Software Engineer',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      Contact(
        id: '2',
        ownerId: 'current-user-id',
        owner: User(
          id: 'current-user-id',
          name: 'Current User',
          email: 'current@user.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        name: 'Jane Smith',
        email: 'jane.smith@example.com',
        phone: '+1234567891',
        company: 'Design Studio',
        position: 'UI/UX Designer',
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
      ),
      Contact(
        id: '3',
        ownerId: 'current-user-id',
        owner: User(
          id: 'current-user-id',
          name: 'Current User',
          email: 'current@user.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        name: 'Mike Johnson',
        email: 'mike.johnson@example.com',
        phone: '+1234567892',
        company: 'Marketing Inc',
        position: 'Marketing Manager',
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      Contact(
        id: '4',
        ownerId: 'current-user-id',
        owner: User(
          id: 'current-user-id',
          name: 'Current User',
          email: 'current@user.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        name: 'Sarah Wilson',
        email: 'sarah.wilson@example.com',
        phone: '+1234567893',
        company: 'Finance Ltd',
        position: 'Financial Analyst',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      Contact(
        id: '5',
        ownerId: 'current-user-id',
        owner: User(
          id: 'current-user-id',
          name: 'Current User',
          email: 'current@user.com',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        name: 'David Brown',
        email: 'david.brown@example.com',
        phone: '+1234567894',
        company: 'Sales Pro',
        position: 'Sales Director',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
    ];
    _filteredContacts = _contacts;
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        return contact.name.toLowerCase().contains(query) ||
            contact.email.toLowerCase().contains(query) ||
            (contact.company?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Library'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => Navigator.pushNamed(context, '/add-contact'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF667eea),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),

          // Contact List
          Expanded(
            child: _filteredContacts.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No contacts found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredContacts.length,
                    itemBuilder: (context, index) {
                      final contact = _filteredContacts[index];
                      return _buildContactCard(contact);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF667eea),
          child: Text(
            contact.name.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              contact.email,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (contact.company != null) ...[
              const SizedBox(height: 2),
              Text(
                '${contact.company} • ${contact.position ?? ''}',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'view':
                Navigator.pushNamed(
                  context,
                  '/contact-profile',
                  arguments: contact,
                );
                break;
              case 'edit':
                Navigator.pushNamed(
                  context,
                  '/edit-contact',
                  arguments: contact,
                );
                break;
              case 'message':
                Navigator.pushNamed(
                  context,
                  '/chatting-room',
                  arguments: contact,
                );
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View Profile'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Edit Contact'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'message',
              child: Row(
                children: [
                  Icon(Icons.message),
                  SizedBox(width: 8),
                  Text('Send Message'),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/contact-profile',
            arguments: contact,
          );
        },
      ),
    );
  }
}
