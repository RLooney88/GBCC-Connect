import 'package:flutter/material.dart';
import 'package:gbcc_connect_app/src/shared/widgets/custom_snackbar.dart';
import 'package:gbcc_connect_app/src/app.dart';
import '../../core/routes/app_routes.dart';
import '../../core/services/service_manager.dart';
import '../../core/models/contact.dart';
import '../../core/models/user.dart';

class ContactLibraryPage extends StatefulWidget {
  final User user;
  final ServiceManager serviceManager;

  const ContactLibraryPage({
    super.key,
    required this.user,
    required this.serviceManager,
  });

  static const routeName = AppRoutes.contactLibrary;

  @override
  State<ContactLibraryPage> createState() => _ContactLibraryPageState();
}

class _ContactLibraryPageState extends State<ContactLibraryPage> {
  final TextEditingController _searchController = TextEditingController();

  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  bool _isSearching = false;
  bool _isLoading = false;
  String? _error;

  // Multi-selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedContactIds = {};

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

  /// Load contacts from the service layer
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
      debugPrint('ContactLibrary: Error loading contacts: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load contacts: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Perform search on contacts
  void _performSearch(String query) {
    setState(() {
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredContacts = _contacts;
      });
      return;
    }

    // Local search for better performance
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

  /// Toggle selection mode
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedContactIds.clear();
      }
    });
  }

  /// Toggle contact selection
  void _toggleContactSelection(String contactId) {
    setState(() {
      if (_selectedContactIds.contains(contactId)) {
        _selectedContactIds.remove(contactId);
      } else {
        _selectedContactIds.add(contactId);
      }
    });
  }

  /// Select all visible contacts
  void _selectAllContacts() {
    setState(() {
      _selectedContactIds.addAll(_filteredContacts.map((c) => c.id));
    });
  }

  /// Deselect all contacts
  void _deselectAllContacts() {
    setState(() {
      _selectedContactIds.clear();
    });
  }

  /// Get selected contacts
  List<Contact> get _selectedContacts {
    return _contacts.where((c) => _selectedContactIds.contains(c.id)).toList();
  }

  /// Bulk delete selected contacts
  Future<void> _bulkDeleteContacts() async {
    if (_selectedContacts.isEmpty) return;

    final contactNames = _selectedContacts.map((c) => c.name).join(', ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contacts'),
        content: Text(
          'Are you sure you want to delete ${_selectedContacts.length} contact${_selectedContacts.length > 1 ? 's' : ''}?\n\n$contactNames',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Show loading indicator
        if (mounted) {
          context.showWarningSnackBar(
              'Deleting ${_selectedContacts.length} contact${_selectedContacts.length > 1 ? 's' : ''}...');
        }

        // Delete all selected contacts
        for (final contact in _selectedContacts) {
          await widget.serviceManager.contactService.deleteContact(contact.id);
        }

        // Update local state
        setState(() {
          _contacts.removeWhere((c) => _selectedContactIds.contains(c.id));
          _selectedContactIds.clear();
          _isSelectionMode = false;
          _performSearch(_searchController.text);
        });

        if (mounted) {
          context.showSuccessSnackBar(
              '${_selectedContacts.length} contact${_selectedContacts.length > 1 ? 's' : ''} deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Failed to delete contacts: $e');
        }
      }
    }
  }

  /// Navigate to add contact page
  void _navigateToAddContact() {
    Navigator.pushNamed(context, AppRoutes.addContact).then((_) {
      // Refresh contacts when returning from add contact
      _loadContacts();
    });
  }

  /// Navigate to contact profile page
  void _navigateToContactProfile(Contact contact) {
    if (_isSelectionMode) {
      _toggleContactSelection(contact.id);
    } else {
      Navigator.pushNamed(
        context,
        AppRoutes.contactProfile,
        arguments: {'contactId': contact.id},
      ).then((_) {
        // Refresh contacts when returning from contact profile
        _loadContacts();
      });
    }
  }

  /// Toggle contact favorite status
  Future<void> _toggleFavorite(Contact contact) async {
    try {
      await widget.serviceManager.contactService
          .toggleFavorite(contact.id, !contact.isFavorite);

      // Update local state
      setState(() {
        final index = _contacts.indexWhere((c) => c.id == contact.id);
        if (index != -1) {
          _contacts[index] =
              _contacts[index].copyWith(isFavorite: !contact.isFavorite);
          _performSearch(_searchController.text);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update favorite: $e')),
        );
      }
    }
  }

  /// Delete contact
  Future<void> _deleteContact(Contact contact) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await widget.serviceManager.contactService.deleteContact(contact.id);

        // Update local state
        setState(() {
          _contacts.removeWhere((c) => c.id == contact.id);
          _performSearch(_searchController.text);
        });

        if (mounted) {
          context.showSuccessSnackBar('${contact.name} deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          context.showErrorSnackBar('Failed to delete contact: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text('${_selectedContactIds.length} selected')
            : const Text('Contacts'),
        actions: [
          if (_isSelectionMode) ...[
            // Delete selected button
            if (_selectedContactIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _bulkDeleteContacts,
                tooltip: 'Delete selected',
              ),
          ] else ...[
            // Selection mode toggle
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _toggleSelectionMode,
              tooltip: 'Select contacts',
            ),
          ],
        ],
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
                suffixIcon: _isSearching
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
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: _navigateToAddContact,
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: _isSelectionMode ? _buildSelectionBottomBar() : null,
    );
  }

  /// Build bottom bar for selection mode
  Widget _buildSelectionBottomBar() {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            TextButton.icon(
              onPressed: _selectedContactIds.length == _filteredContacts.length
                  ? _deselectAllContacts
                  : _selectAllContacts,
              icon: Icon(
                _selectedContactIds.length == _filteredContacts.length
                    ? Icons.deselect
                    : Icons.select_all,
              ),
              label: Text(
                _selectedContactIds.length == _filteredContacts.length
                    ? 'Deselect All'
                    : 'Select All',
              ),
              style: TextButton.styleFrom(
                foregroundColor: MyApp.primaryColor,
              ),
            ),
            const Spacer(),
            if (_selectedContactIds.isNotEmpty)
              ElevatedButton.icon(
                onPressed: _bulkDeleteContacts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.delete),
                label: Text('Delete (${_selectedContactIds.length})'),
              ),
          ],
        ),
      ),
    );
  }

  /// Build the main content area
  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Error loading contacts',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContacts,
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
            Icon(Icons.contacts, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _isSearching ? 'No contacts found' : 'No contacts yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _isSearching
                  ? 'Try adjusting your search terms'
                  : 'Add your first contact to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
              textAlign: TextAlign.center,
            ),
            if (!_isSearching) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToAddContact,
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

  /// Build individual contact tile
  Widget _buildContactTile(Contact contact) {
    final isSelected = _selectedContactIds.contains(contact.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected ? Colors.grey.shade200 : null,
      child: ListTile(
        leading: _isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (value) => _toggleContactSelection(contact.id),
              )
            : CircleAvatar(
                backgroundColor:
                    contact.isFavorite ? Colors.amber : MyApp.primaryColor,
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontWeight:
                contact.isFavorite ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.email.isNotEmpty)
              Text(
                contact.email,
                style: TextStyle(
                  color: Colors.grey[600],
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        trailing: _isSelectionMode
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (contact.chamberMember)
                    const Icon(Icons.business, color: Colors.green, size: 20),
                  if (contact.isBlocked)
                    const Icon(Icons.block, color: Colors.red, size: 20),
                  IconButton(
                    icon: Icon(
                      contact.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: contact.isFavorite ? Colors.amber : null,
                    ),
                    onPressed: () => _toggleFavorite(contact),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          Navigator.pushNamed(
                            context,
                            AppRoutes.editContact,
                            arguments: contact,
                          ).then((_) => _loadContacts());
                          break;
                        case 'delete':
                          _deleteContact(contact);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
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
                  ),
                ],
              ),
        onTap: () => _navigateToContactProfile(contact),
      ),
    );
  }
}

class AppColors {}
