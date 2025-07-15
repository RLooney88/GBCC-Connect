import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/app_routes.dart';
import '../../core/providers/firebase_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/models/contact.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class ContactLibraryPage extends StatefulWidget {
  const ContactLibraryPage({super.key});

  static const routeName = AppRoutes.contactLibrary;

  @override
  State<ContactLibraryPage> createState() => _ContactLibraryPageState();
}

class _ContactLibraryPageState extends State<ContactLibraryPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _filteredContacts = [];
  bool _isSearching = false;
  bool _isInitializing = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePage();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = context.read<AuthProvider>();
    authProvider.addListener(_handleAuthStateChange);
  }

  Future<void> _initializePage() async {
    final authProvider = context.read<AuthProvider>();
    final firebaseProvider = context.read<FirebaseProvider>();

    if (authProvider.currentUser == null) {
      debugPrint('ContactLibraryPage: No authenticated user found');
      return;
    }

    debugPrint(
        'ContactLibraryPage: User authenticated: ${authProvider.currentUser!.name}');

    if (!firebaseProvider.isInitialized) {
      await _initializeFirebaseProvider();
    } else {
      await _loadContacts();
    }
  }

  Future<void> _initializeFirebaseProvider() async {
    final firebaseProvider = context.read<FirebaseProvider>();

    setState(() {
      _isInitializing = true;
    });

    try {
      debugPrint('ContactLibraryPage: Initializing Firebase provider...');
      await firebaseProvider.initialize();
      debugPrint(
          'ContactLibraryPage: Firebase provider initialized successfully');
      await _loadContacts();
    } catch (e) {
      debugPrint('ContactLibraryPage: Firebase initialization failed: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to initialize: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  Future<void> _loadContacts() async {
    final firebaseProvider = context.read<FirebaseProvider>();

    try {
      debugPrint('ContactLibraryPage: Loading contacts...');
      await firebaseProvider.loadContacts();
      debugPrint('ContactLibraryPage: Contacts loaded successfully');
    } catch (e) {
      debugPrint('ContactLibraryPage: Failed to load contacts: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to load contacts: $e');
      }
    }
  }

  void _handleAuthStateChange() {
    final authProvider = context.read<AuthProvider>();
    final firebaseProvider = context.read<FirebaseProvider>();

    if (authProvider.currentUser != null) {
      if (!firebaseProvider.isInitialized) {
        _initializePage();
      }
    } else {
      setState(() {
        _filteredContacts = [];
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    try {
      final authProvider = context.read<AuthProvider>();
      authProvider.removeListener(_handleAuthStateChange);
    } catch (e) {
      // Ignore errors if context is no longer available
    }

    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    _debounceTimer?.cancel();

    setState(() {
      _isSearching = query.isNotEmpty;
    });

    if (query.isEmpty) {
      setState(() {
        _filteredContacts = [];
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final authProvider = context.read<AuthProvider>();
      final firebaseProvider = context.read<FirebaseProvider>();

      if (authProvider.currentUser == null || !firebaseProvider.isInitialized) {
        setState(() {
          _filteredContacts = [];
        });
        return;
      }

      try {
        final results = await firebaseProvider.searchContacts(query);
        if (mounted) {
          setState(() {
            _filteredContacts = results;
          });
        }
      } catch (e) {
        debugPrint('ContactLibraryPage: Search failed: $e');
        if (mounted) {
          _showErrorSnackBar('Search failed: $e');
        }
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () => _initializePage(),
        ),
      ),
    );
  }

  void _debugProviderState() {
    if (!kDebugMode) return;

    final authProvider = context.read<AuthProvider>();
    final firebaseProvider = context.read<FirebaseProvider>();

    debugPrint('=== DEBUG PROVIDER STATE ===');
    debugPrint('AuthProvider:');
    debugPrint('  - isLoading: ${authProvider.isLoading}');
    debugPrint('  - currentUser: ${authProvider.currentUser?.name ?? 'null'}');
    debugPrint('  - isAuthenticated: ${authProvider.isAuthenticated}');
    debugPrint('FirebaseProvider:');
    debugPrint('  - isLoading: ${firebaseProvider.isLoading}');
    debugPrint('  - isInitialized: ${firebaseProvider.isInitialized}');
    debugPrint('  - error: ${firebaseProvider.error}');
    debugPrint('  - contacts count: ${firebaseProvider.contacts.length}');
    debugPrint(
        '  - currentUser: ${firebaseProvider.currentUser?.name ?? 'null'}');
    debugPrint('===========================');
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
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _searchController.clear();
                  _isSearching = false;
                  _filteredContacts = [];
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _debugProviderState,
            ),
        ],
      ),
      body: Column(
        children: [
          if (_isSearching)
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search contacts...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                onChanged: _performSearch,
                autofocus: true,
              ),
            ),
          Expanded(
            child: Consumer2<AuthProvider, FirebaseProvider>(
              builder: (context, authProvider, firebaseProvider, child) {
                return _buildContactsList(authProvider, firebaseProvider);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addContact),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildContactsList(
      AuthProvider authProvider, FirebaseProvider firebaseProvider) {
    if (authProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (authProvider.currentUser == null) {
      return _buildAuthenticationRequired();
    }

    if (!firebaseProvider.isInitialized || _isInitializing) {
      return _buildInitializationState();
    }

    if (firebaseProvider.isLoading && firebaseProvider.contacts.isEmpty) {
      return _buildLoadingState();
    }

    if (firebaseProvider.error != null) {
      return _buildErrorState(firebaseProvider.error!);
    }

    if (!_isSearching) {
      return StreamBuilder<List<Contact>>(
        stream: firebaseProvider.streamContacts(),
        builder: (context, snapshot) {
          return _buildStreamBuilderContent(snapshot);
        },
      );
    }

    return _buildSearchResults();
  }

  Widget _buildAuthenticationRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Authentication Required',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Please log in to view your contacts',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  Widget _buildInitializationState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Theme.of(context).primaryColor),
          const SizedBox(height: 16),
          Text(_isInitializing ? 'Initializing...' : 'Setting up...',
              style: Theme.of(context).textTheme.bodyMedium),
          if (_isInitializing) ...[
            const SizedBox(height: 8),
            TextButton(
                onPressed: () => _initializePage(), child: const Text('Retry')),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Theme.of(context).primaryColor),
          const SizedBox(height: 16),
          Text('Loading contacts...',
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error loading contacts',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
              onPressed: () => _initializePage(), child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildStreamBuilderContent(AsyncSnapshot<List<Contact>> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return _buildErrorState(snapshot.error.toString());
    }

    final contacts = snapshot.data ?? [];

    if (contacts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return _buildContactTile(context, contact);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.people_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No contacts yet',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Add your first contact to get started',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, AppRoutes.addContact),
            child: const Text('Add Contact'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final firebaseProvider = context.read<FirebaseProvider>();

    if (firebaseProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final contacts = _filteredContacts;

    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No contacts found',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text('Try adjusting your search terms',
                style: Theme.of(context).textTheme.bodyMedium),
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
                    style: const TextStyle(fontWeight: FontWeight.bold))),
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
                      fontWeight: FontWeight.bold),
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
            if (contact.isFavorite)
              const Icon(Icons.favorite, color: Colors.red, size: 20),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'message',
                  child: Row(children: [
                    Icon(Icons.message),
                    SizedBox(width: 8),
                    Text('Message')
                  ]),
                ),
                const PopupMenuItem(
                  value: 'call',
                  child: Row(children: [
                    Icon(Icons.call),
                    SizedBox(width: 8),
                    Text('Call')
                  ]),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit')
                  ]),
                ),
                const PopupMenuItem(
                  value: 'favorite',
                  child: Row(children: [
                    Icon(Icons.favorite_border),
                    SizedBox(width: 8),
                    Text('Toggle Favorite')
                  ]),
                ),
                const PopupMenuItem(
                  value: 'chamber',
                  child: Row(children: [
                    Icon(Icons.business),
                    SizedBox(width: 8),
                    Text('Toggle Chamber Member')
                  ]),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red))
                  ]),
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
                    _showCallFeature(context);
                    break;
                  case 'edit':
                    Navigator.pushNamed(context, AppRoutes.editContact,
                        arguments: contact);
                    break;
                  case 'favorite':
                    try {
                      await firebaseProvider.toggleContactFavorite(
                          contact.id, !contact.isFavorite);
                    } catch (e) {
                      if (context.mounted) {
                        _showErrorSnackBar('Failed to update favorite: $e');
                      }
                    }
                    break;
                  case 'chamber':
                    try {
                      await firebaseProvider.updateContact(contact.copyWith(
                          chamberMember: !contact.chamberMember));
                    } catch (e) {
                      if (context.mounted) {
                        _showErrorSnackBar(
                            'Failed to update chamber status: $e');
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
          Navigator.pushNamed(context, '/contact-profile', arguments: contact);
        },
      ),
    );
  }

  void _showCallFeature(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Call feature coming soon!'),
          backgroundColor: Colors.blue),
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
                child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await firebaseProvider.deleteContact(contact.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Contact deleted successfully'),
                          backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    _showErrorSnackBar('Failed to delete contact: $e');
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
