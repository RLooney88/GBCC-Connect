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
  Map<String, bool> _contactRegistrationStatus = {};

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

      // Check registration status for all contacts
      final registrationStatus = <String, bool>{};
      for (final contact in contacts) {
        final isRegistered = await widget.serviceManager.contactService
            .isContactRegisteredUser(contact.email);
        registrationStatus[contact.id] = isRegistered;
      }

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _filteredContacts = contacts;
          _contactRegistrationStatus = registrationStatus;
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
                Text('Checking contact status...'),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Check if the contact is a registered user
      final isRegistered = await widget.serviceManager.contactService
          .isContactRegisteredUser(contact.email);

      if (mounted) {
        if (isRegistered) {
          // Contact is registered - start chat directly
          _startChatWithRegisteredUser(contact);
        } else {
          // Contact is not registered - show email options
          _startChatWithRegisteredUser(contact);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check contact status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startChatWithRegisteredUser(Contact contact) {
    // Use the contact ID for navigation
    final contactId = contact.email;

    Navigator.pushNamed(
      context,
      AppRoutes.chat,
      arguments: {'chatId': contactId},
    );
  }

  // void _showEmailOptionsForUnregisteredUser(Contact contact) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     builder: (BuildContext context) {
  //       return Container(
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             // Header
  //             Row(
  //               children: [
  //                 CircleAvatar(
  //                   backgroundColor: MyApp.primaryColor,
  //                   child: Text(
  //                     contact.name.isNotEmpty
  //                         ? contact.name[0].toUpperCase()
  //                         : 'C',
  //                     style: const TextStyle(
  //                       color: Colors.white,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ),
  //                 const SizedBox(width: 12),
  //                 Expanded(
  //                   child: Column(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Text(
  //                         contact.name,
  //                         style: const TextStyle(
  //                           fontSize: 18,
  //                           fontWeight: FontWeight.bold,
  //                         ),
  //                       ),
  //                       Text(
  //                         contact.email,
  //                         style: TextStyle(
  //                           color: Colors.grey[600],
  //                           fontSize: 14,
  //                         ),
  //                       ),
  //                       Container(
  //                         padding: const EdgeInsets.symmetric(
  //                           horizontal: 8,
  //                           vertical: 4,
  //                         ),
  //                         decoration: BoxDecoration(
  //                           color: Colors.orange[100],
  //                           borderRadius: BorderRadius.circular(12),
  //                         ),
  //                         child: Text(
  //                           'Not registered',
  //                           style: TextStyle(
  //                             color: Colors.orange[800],
  //                             fontSize: 12,
  //                             fontWeight: FontWeight.w500,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 24),

  //             // Email options
  //             ListTile(
  //               leading: const Icon(Icons.email, color: Colors.blue),
  //               title: const Text('Send Email'),
  //               subtitle: const Text('Send a message via email'),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 _sendEmailToUnregisteredUser(contact);
  //               },
  //             ),
  //             ListTile(
  //               leading: const Icon(Icons.person_add, color: Colors.green),
  //               title: const Text('Send Invitation'),
  //               subtitle: const Text('Invite them to join the app'),
  //               onTap: () {
  //                 Navigator.pop(context);
  //                 _sendInvitationToUnregisteredUser(contact);
  //               },
  //             ),
  //             const SizedBox(height: 16),

  //             // Cancel button
  //             SizedBox(
  //               width: double.infinity,
  //               child: TextButton(
  //                 onPressed: () => Navigator.pop(context),
  //                 child: const Text('Cancel'),
  //               ),
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  // void _sendEmailToUnregisteredUser(Contact contact) async {
  //   try {
  //     final currentUser = widget.user;
  //     final fromName = currentUser.name ?? currentUser.displayName ?? 'User';

  //     final success =
  //         await widget.serviceManager.emailService.sendEmailToUnregisteredUser(
  //       toEmail: contact.email,
  //       fromName: fromName,
  //       fromEmail: currentUser.email,
  //       messageContent:
  //           'Hello ${contact.name}, I would like to connect with you.',
  //     );

  //     if (mounted) {
  //       if (success) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Email client opened successfully'),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Failed to open email client'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to send email: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  // void _sendInvitationToUnregisteredUser(Contact contact) async {
  //   try {
  //     final currentUser = widget.user;
  //     final fromName = currentUser.name ?? currentUser.displayName ?? 'User';

  //     final success =
  //         await widget.serviceManager.emailService.sendInvitationEmail(
  //       toEmail: contact.email,
  //       fromName: fromName,
  //       fromEmail: currentUser.email,
  //       invitationMessage:
  //           'Hello ${contact.name}, I would like to invite you to join GBCC Connect App so we can chat directly.',
  //     );

  //     if (mounted) {
  //       if (success) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Invitation email opened successfully'),
  //             backgroundColor: Colors.green,
  //           ),
  //         );
  //       } else {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text('Failed to open email client'),
  //             backgroundColor: Colors.red,
  //           ),
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Failed to send invitation: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

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
        title: Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle,
                style: TextStyle(
                  color: Colors.grey[600],
                  overflow: TextOverflow.ellipsis,
                )),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (contact.chamberMember)
              const Icon(Icons.business, color: Colors.green, size: 20),
            if (contact.isBlocked)
              const Icon(Icons.block, color: Colors.red, size: 20),
          ],
        ),
        onTap: () => _selectContact(contact),
      ),
    );
  }
}
