import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/models/contact.dart';
import '../../core/services/service_manager.dart';
import '../../app.dart';

class EditContactPage extends StatefulWidget {
  final ServiceManager serviceManager;
  final Contact contact;

  const EditContactPage({
    super.key,
    required this.serviceManager,
    required this.contact,
  });

  static const routeName = '/edit-contact';

  @override
  State<EditContactPage> createState() => _EditContactPageState();
}

class _EditContactPageState extends State<EditContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _websiteController = TextEditingController();
  final _positionController = TextEditingController();
  final _notesController = TextEditingController();

  // Social media controllers
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _pinterestController = TextEditingController();

  bool _isLoading = false;
  bool _isFavorite = false;
  bool _isChamberMember = false;
  Contact? _originalContact;

  @override
  void initState() {
    super.initState();
    _originalContact = widget.contact;
    _populateFormFields(widget.contact);
  }

  void _populateFormFields(Contact contact) {
    setState(() {
      _nameController.text = contact.name;
      _emailController.text = contact.email;
      _phoneController.text = contact.phone ?? '';
      _positionController.text = contact.position ?? '';
      _companyController.text = contact.company ?? '';
      _websiteController.text = contact.website ?? '';
      _notesController.text = contact.notes ?? '';

      // Populate social media fields
      _instagramController.text = contact.instagram ?? '';
      _facebookController.text = contact.facebook ?? '';
      _youtubeController.text = contact.youtube ?? '';
      _linkedinController.text = contact.linkedin ?? '';
      _pinterestController.text = contact.pinterest ?? '';

      _isChamberMember = contact.chamberMember;
      _isFavorite = contact.isFavorite;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _companyController.dispose();
    _websiteController.dispose();
    _notesController.dispose();

    // Dispose social media controllers
    _instagramController.dispose();
    _facebookController.dispose();
    _youtubeController.dispose();
    _linkedinController.dispose();
    _pinterestController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Contact'),
          backgroundColor: MyApp.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : _saveContact,
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
        body: _originalContact == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture Section
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: MyApp.primaryColor,
                              child: Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                // TODO: Implement image picker
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Image picker coming soon!'),
                                  ),
                                );
                              },
                              child: const Text('Change Photo'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Contact Information
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter an email address';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            // Basic phone validation - allows digits, spaces, dashes, parentheses, and +
                            if (!RegExp(r'^[\+]?[0-9\s\-\(\)]{10,}$')
                                .hasMatch(value.trim())) {
                              return 'Please enter a valid phone number';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Professional Information
                      const Text(
                        'Professional Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Position Field
                      TextFormField(
                        controller: _positionController,
                        decoration: const InputDecoration(
                          labelText: 'Position',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.work_outline),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Company Field
                      TextFormField(
                        controller: _companyController,
                        decoration: const InputDecoration(
                          labelText: 'Company',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Website Field
                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: 'Website',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.language_outlined),
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            // Basic URL validation
                            final urlPattern = RegExp(
                              r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
                            );
                            if (!urlPattern.hasMatch(value.trim())) {
                              return 'Please enter a valid URL (e.g., https://example.com)';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Social Media Links Section
                      const Text(
                        'Social Media Links',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Instagram Field
                      TextFormField(
                        controller: _instagramController,
                        decoration: const InputDecoration(
                          labelText: 'Instagram',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(FontAwesomeIcons.instagram,
                              color: Color(0xFFE4405F)),
                          hintText: 'https://instagram.com/username',
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final instagramPattern = RegExp(
                              r'^https?:\/\/(www\.)?(instagram\.com|instagr\.am)\/[a-zA-Z0-9._]+\/?$',
                            );
                            if (!instagramPattern.hasMatch(value.trim())) {
                              return 'Please enter a valid Instagram URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Facebook Field
                      TextFormField(
                        controller: _facebookController,
                        decoration: const InputDecoration(
                          labelText: 'Facebook',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(FontAwesomeIcons.facebook,
                              color: Color(0xFF1877F2)),
                          hintText: 'https://facebook.com/username',
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final facebookPattern = RegExp(
                              r'^https?:\/\/(www\.)?(facebook\.com|fb\.com)\/[a-zA-Z0-9._]+\/?$',
                            );
                            if (!facebookPattern.hasMatch(value.trim())) {
                              return 'Please enter a valid Facebook URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // LinkedIn Field
                      TextFormField(
                        controller: _linkedinController,
                        decoration: const InputDecoration(
                          labelText: 'LinkedIn',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(FontAwesomeIcons.linkedin,
                              color: Color(0xFF0A66C2)),
                          hintText: 'https://linkedin.com/in/username',
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final linkedinPattern = RegExp(
                              r'^https?:\/\/(www\.)?(linkedin\.com\/in|linkedin\.com\/company)\/[a-zA-Z0-9._-]+\/?$',
                            );
                            if (!linkedinPattern.hasMatch(value.trim())) {
                              return 'Please enter a valid LinkedIn URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // YouTube Field
                      TextFormField(
                        controller: _youtubeController,
                        decoration: const InputDecoration(
                          labelText: 'YouTube',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(FontAwesomeIcons.youtube,
                              color: Color(0xFFFF0000)),
                          hintText: 'https://youtube.com/@channel',
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final youtubePattern = RegExp(
                              r'^https?:\/\/(www\.)?(youtube\.com\/(@|channel\/|c\/)|youtu\.be\/)[a-zA-Z0-9._-]+\/?$',
                            );
                            if (!youtubePattern.hasMatch(value.trim())) {
                              return 'Please enter a valid YouTube URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Pinterest Field
                      TextFormField(
                        controller: _pinterestController,
                        decoration: const InputDecoration(
                          labelText: 'Pinterest',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(FontAwesomeIcons.pinterest,
                              color: Color(0xFFBD081C)),
                          hintText: 'https://pinterest.com/username',
                        ),
                        keyboardType: TextInputType.url,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final pinterestPattern = RegExp(
                              r'^https?:\/\/(www\.)?pinterest\.com\/[a-zA-Z0-9._]+\/?$',
                            );
                            if (!pinterestPattern.hasMatch(value.trim())) {
                              return 'Please enter a valid Pinterest URL';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Chamber Member Checkbox
                      CheckboxListTile(
                        title: const Text('Chamber Member'),
                        subtitle: const Text(
                            'Is this contact a member of the chamber?'),
                        value: _isChamberMember,
                        onChanged: (bool? value) {
                          setState(() {
                            _isChamberMember = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: MyApp.primaryColor,
                      ),
                      const SizedBox(height: 16),

                      // Favorite Checkbox
                      CheckboxListTile(
                        title: const Text('Favorite'),
                        subtitle: const Text('Mark this contact as a favorite'),
                        value: _isFavorite,
                        onChanged: (bool? value) {
                          setState(() {
                            _isFavorite = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: MyApp.primaryColor,
                      ),
                      const SizedBox(height: 24),

                      // Notes Section
                      const Text(
                        'Additional Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes Field
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note_outlined),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveContact,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MyApp.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Update Contact',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // Check if there are unsaved changes
    if (_hasUnsavedChanges()) {
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
              'You have unsaved changes. Are you sure you want to leave?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      return result ?? false;
    }
    return true;
  }

  bool _hasUnsavedChanges() {
    if (_originalContact == null) return false;

    return _nameController.text.trim() != _originalContact!.name ||
        _emailController.text.trim() != _originalContact!.email ||
        _phoneController.text.trim() != (_originalContact!.phone ?? '') ||
        _positionController.text.trim() != (_originalContact!.position ?? '') ||
        _companyController.text.trim() != (_originalContact!.company ?? '') ||
        _websiteController.text.trim() != (_originalContact!.website ?? '') ||
        _notesController.text.trim() != (_originalContact!.notes ?? '') ||
        _instagramController.text.trim() !=
            (_originalContact!.instagram ?? '') ||
        _facebookController.text.trim() != (_originalContact!.facebook ?? '') ||
        _youtubeController.text.trim() != (_originalContact!.youtube ?? '') ||
        _linkedinController.text.trim() != (_originalContact!.linkedin ?? '') ||
        _pinterestController.text.trim() !=
            (_originalContact!.pinterest ?? '') ||
        _isChamberMember != _originalContact!.chamberMember ||
        _isFavorite != _originalContact!.isFavorite;
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use the ServiceManager provided by AuthenticatedPageWrapper
      final serviceManager = widget.serviceManager;

      if (_originalContact == null) {
        _showErrorSnackBar('Contact data not found.');
        return;
      }

      final email = _emailController.text.trim();
      final currentUser = _originalContact!.owner;

      // Check for duplicate email, but exclude the current contact being edited
      final isDuplicate = await serviceManager.contactService.isEmailDuplicate(
        currentUser.id,
        email,
      );

      // If email is duplicate and it's not the same as the original contact's email
      if (isDuplicate &&
          email.toLowerCase() != _originalContact!.email.toLowerCase()) {
        if (mounted) {
          _showErrorSnackBar('A contact with this email already exists.');
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Create the updated contact object
      final updatedContact = _originalContact!.copyWith(
        name: _nameController.text.trim(),
        displayName:
            _nameController.text.trim(), // Update displayName to match name
        email: email,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        company: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        position: _positionController.text.trim().isEmpty
            ? null
            : _positionController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        instagram: _instagramController.text.trim().isEmpty
            ? null
            : _instagramController.text.trim(),
        facebook: _facebookController.text.trim().isEmpty
            ? null
            : _facebookController.text.trim(),
        youtube: _youtubeController.text.trim().isEmpty
            ? null
            : _youtubeController.text.trim(),
        linkedin: _linkedinController.text.trim().isEmpty
            ? null
            : _linkedinController.text.trim(),
        pinterest: _pinterestController.text.trim().isEmpty
            ? null
            : _pinterestController.text.trim(),
        chamberMember: _isChamberMember,
        isFavorite: _isFavorite,
      );

      // Update the contact using ServiceManager
      await serviceManager.contactService
          .updateContact(updatedContact.id, updatedContact);

      if (mounted) {
        _showSuccessSnackBar('Contact updated successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to update contact: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
