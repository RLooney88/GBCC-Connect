import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/contact.dart';
import '../../core/models/user.dart';
import '../../core/routes/app_routes.dart';
import '../../app.dart';
import '../../core/services/service_manager.dart';

class ContactProfilePage extends StatefulWidget {
  final User user;
  final ServiceManager serviceManager;
  final String contactId;

  const ContactProfilePage(
      {super.key,
      required this.user,
      required this.serviceManager,
      required this.contactId});

  static const routeName = '/contact-profile';

  @override
  State<ContactProfilePage> createState() => _ContactProfilePageState();
}

class _ContactProfilePageState extends State<ContactProfilePage> {
  Contact? _contact;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadContact();
  }

  Future<void> _loadContact() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final contact = await widget.serviceManager.contactService
          .getContactById(widget.contactId);

      if (mounted) {
        setState(() {
          _contact = contact;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load contact: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Profile'),
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_contact != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.editContact,
                  arguments: _contact,
                );
              },
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
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
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContact,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_contact == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Contact not found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    final contact = _contact!;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  MyApp.primaryColor,
                  MyApp.primaryColor.withOpacity(0.8),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      contact.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: MyApp.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (contact.position != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      contact.position!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  if (contact.company != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      contact.company!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.chat,
                        arguments: {'chatId': contact.email},
                      );
                    },
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MyApp.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        contact.phone != null && contact.phone!.isNotEmpty
                            ? () {
                                // Handle call action
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Call feature coming soon!'),
                                  ),
                                );
                              }
                            : null,
                    icon: const Icon(Icons.call),
                    label: const Text('Call'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor:
                          contact.phone != null && contact.phone!.isNotEmpty
                              ? MyApp.primaryColor
                              : Colors.grey,
                      side: BorderSide(
                        color:
                            contact.phone != null && contact.phone!.isNotEmpty
                                ? MyApp.primaryColor
                                : Colors.grey,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contact Information
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3748),
                  ),
                ),
                const SizedBox(height: 16),

                // Email
                _buildInfoTile(
                  context: context,
                  icon: Icons.email_outlined,
                  title: 'Email',
                  subtitle: contact.email,
                  onTap: () {
                    // Handle email action
                  },
                ),

                // Phone
                const SizedBox(height: 12),
                _buildInfoTile(
                  context: context,
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  subtitle: contact.phone ?? 'No Phone Number',
                  onTap: null,
                ),

                // Company
                const SizedBox(height: 12),
                _buildInfoTile(
                  context: context,
                  icon: Icons.business,
                  title: 'Company',
                  subtitle: contact.company ?? 'No Company',
                  onTap: null,
                ),

                // Position
                const SizedBox(height: 12),
                _buildInfoTile(
                  context: context,
                  icon: Icons.work_outline,
                  title: 'Position',
                  subtitle: contact.position ?? 'No Position',
                  onTap: null,
                ),

                // Website
                const SizedBox(height: 12),
                _buildInfoTile(
                  context: context,
                  icon: Icons.language_outlined,
                  title: 'Website',
                  subtitle: contact.website ?? 'No Website',
                  onTap: () {
                    _launchUrl(contact.website ?? '');
                  },
                ),

                // Social Media Links
                const SizedBox(height: 12),
                const Text(
                  'Social Media',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF718096),
                  ),
                ),
                const SizedBox(height: 8),

                // Instagram
                _buildInfoTile(
                  context: context,
                  icon: FontAwesomeIcons.instagram,
                  title: 'Instagram',
                  subtitle: contact.instagram ?? 'No Instagram Link',
                  onTap: () {
                    _launchUrl(contact.instagram ?? '');
                  },
                  iconColor: const Color(0xFFE4405F),
                ),
                const SizedBox(height: 12),

                // Facebook
                _buildInfoTile(
                  context: context,
                  icon: FontAwesomeIcons.facebook,
                  title: 'Facebook',
                  subtitle: contact.facebook ?? 'No Facebook Link',
                  onTap: () {
                    _launchUrl(contact.facebook ?? '');
                  },
                  iconColor: const Color(0xFF1877F2),
                ),
                const SizedBox(height: 12),

                // YouTube
                _buildInfoTile(
                  context: context,
                  icon: FontAwesomeIcons.youtube,
                  title: 'YouTube',
                  subtitle: contact.youtube ?? 'No YouTube Link',
                  onTap: () {
                    _launchUrl(contact.youtube ?? '');
                  },
                  iconColor: const Color(0xFFFF0000),
                ),
                const SizedBox(height: 12),

                // LinkedIn
                _buildInfoTile(
                  context: context,
                  icon: FontAwesomeIcons.linkedin,
                  title: 'LinkedIn',
                  subtitle: contact.linkedin ?? 'No LinkedIn Link',
                  onTap: () {
                    _launchUrl(contact.linkedin ?? '');
                  },
                  iconColor: const Color(0xFF0A66C2),
                ),
                const SizedBox(height: 12),

                // Pinterest
                _buildInfoTile(
                  context: context,
                  icon: FontAwesomeIcons.pinterest,
                  title: 'Pinterest',
                  subtitle: contact.pinterest ?? 'No Pinterest Link',
                  onTap: () {
                    _launchUrl(contact.pinterest ?? '');
                  },
                  iconColor: const Color(0xFFBD081C),
                ),
              ],
            ),
          ),

          // Notes Section
          if (contact.notes != null && contact.notes!.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2d3748),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Text(
                      contact.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Additional Information
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Additional Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2d3748),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoTile(
                  context: context,
                  icon: Icons.calendar_today_outlined,
                  title: 'Added',
                  subtitle: _formatDate(contact.createdAt),
                  onTap: null,
                ),
                const SizedBox(height: 12),
                _buildInfoTile(
                  context: context,
                  icon: Icons.update_outlined,
                  title: 'Last Updated',
                  subtitle: _formatDate(contact.updatedAt),
                  onTap: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: iconColor ?? MyApp.primaryColor,
          size: 24,
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF718096),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2d3748),
          ),
        ),
        trailing: onTap != null
            ? const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF718096),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not launch $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error launching $url: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
