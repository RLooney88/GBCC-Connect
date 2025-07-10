import 'package:flutter/material.dart';
import '../../core/models/contact.dart';

class ContactProfilePage extends StatelessWidget {
  const ContactProfilePage({super.key});

  static const routeName = '/contact-profile';

  @override
  Widget build(BuildContext context) {
    final contact = ModalRoute.of(context)!.settings.arguments as Contact;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Profile'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/edit-contact',
                arguments: contact,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF667eea),
                    Color(0xFF764ba2),
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
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
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
                          '/chatting-room',
                          arguments: contact,
                        );
                      },
                      icon: const Icon(Icons.message),
                      label: const Text('Message'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF667eea),
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
                      onPressed: () {
                        // Handle call action
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Call feature coming soon!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.call),
                      label: const Text('Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF667eea),
                        side: const BorderSide(color: Color(0xFF667eea)),
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
                    icon: Icons.email_outlined,
                    title: 'Email',
                    subtitle: contact.email,
                    onTap: () {
                      // Handle email action
                    },
                  ),

                  // Phone
                  if (contact.phone != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      subtitle: contact.phone!,
                      onTap: () {
                        // Handle phone action
                      },
                    ),
                  ],

                  // Company
                  if (contact.company != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      icon: Icons.business_outlined,
                      title: 'Company',
                      subtitle: contact.company!,
                      onTap: null,
                    ),
                  ],

                  // Position
                  if (contact.position != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoTile(
                      icon: Icons.work_outline,
                      title: 'Position',
                      subtitle: contact.position!,
                      onTap: null,
                    ),
                  ],
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
                    icon: Icons.calendar_today_outlined,
                    title: 'Added',
                    subtitle: _formatDate(contact.createdAt),
                    onTap: null,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile(
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
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
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
          color: const Color(0xFF667eea),
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
}
