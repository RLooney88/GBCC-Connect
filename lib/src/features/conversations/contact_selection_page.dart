import 'package:flutter/material.dart';
import '../../core/models/contact.dart';
import '../../core/models/user.dart';
import '../../core/services/service_manager.dart';
import '../../core/routes/app_routes.dart';
import '../../app.dart';

class ContactSelectionPage extends StatefulWidget {
  final User user;
  final ServiceManager serviceManager;

  const ContactSelectionPage({
    super.key,
    required this.user,
    required this.serviceManager,
  });

  static const routeName = '/contact-selection';

  @override
  State<ContactSelectionPage> createState() => _ContactSelectionPageState();
}

class _ContactSelectionPageState extends State<ContactSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contacts = await widget.serviceManager.contactService
          .getContactsByOwner(widget.user.id);

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ContactSelection: Error loading contacts: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load contacts: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _contacts;
      });
      return;
    }

    final results = _contacts.where((contact) {
      final searchLower = query.toLowerCase();
      return contact.name.toLowerCase().contains(searchLower) ||
          contact.email.toLowerCase().contains(searchLower) ||
          (contact.phone?.toLowerCase().contains(searchLower) ?? false) ||
          (contact.company?.toLowerCase().contains(searchLower) ?? false) ||
          (contact.position?.toLowerCase().contains(searchLower) ?? false) ||
          (contact.website?.toLowerCase().contains(searchLower) ?? false) ||
          (contact.instagram?.toLowerCase().contains(searchLower) ?? false) ||
          (contact.facebook?.toLowerCase().contains(searchLower) ?? false) ||
          (contact.linkedin?.toLowerCase().contains(searchLower) ?? false) ||
          (contact.youtube?.toLowerCase().contains(searchLower) ?? false) ||
          (contact.pinterest?.toLowerCase().contains(searchLower) ?? false) ||
          (contact.notes?.toLowerCase().contains(searchLower) ?? false);
    }).toList();

    setState(() {
      _filteredContacts = results;
    });
  }

  void _selectContact(Contact contact) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 16),
                Text('Starting conversation with ${contact.name}...'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      String participantId = contact.id;

      if (mounted) {
        // Navigate to chat page with chatId as arguments
        Navigator.pushNamed(
          context,
          AppRoutes.chat,
          arguments: {'chatId': participantId},
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Contact'),
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _performSearch,
            ),
          ),

          // Content area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading contacts...'),
          ],
        ),
      );
    }

    if (_error != null) {
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
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.red[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _loadContacts(),
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

    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.contacts,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'No contacts found'
                  : 'No contacts yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Add contacts to start conversations',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            if (!_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.addContact).then((_) {
                    _loadContacts();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyApp.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Contact'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredContacts.length,
      itemBuilder: (context, index) {
        final contact = _filteredContacts[index];
        return _buildContactTile(contact);
      },
    );
  }

  Widget _buildContactTile(Contact contact) {
    final displayName =
        contact.displayName.isNotEmpty ? contact.displayName : contact.name;
    final avatar = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'C';
    final subtitle = contact.email;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: MyApp.primaryColor,
          child: Text(
            avatar,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          displayName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact.chamberMember)
              const Icon(Icons.business, color: Colors.green, size: 20),
            if (contact.isBlocked)
              const Icon(Icons.block, color: Colors.red, size: 20),
            const Icon(Icons.chat_bubble_outline, color: Colors.grey),
          ],
        ),
        onTap: () => _selectContact(contact),
      ),
    );
  }
}
