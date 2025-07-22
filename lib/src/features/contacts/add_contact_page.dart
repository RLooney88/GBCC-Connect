import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/models/contact.dart';
import '../../core/models/user.dart';
import '../../core/services/service_manager.dart';
import '../../core/services/ocr_service.dart';
import '../../core/routes/app_routes.dart';
import 'business_card_scanner_page.dart';
import '../../app.dart';

class AddContactPage extends StatefulWidget {
  final User user;
  final ServiceManager serviceManager;
  final String? preFilledName;
  final String? preFilledEmail;
  final String? returnToChatId; // To return to chat after adding contact

  const AddContactPage({
    super.key,
    required this.user,
    required this.serviceManager,
    this.preFilledName,
    this.preFilledEmail,
    this.returnToChatId,
  });

  static const routeName = '/add-contact';

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _positionController = TextEditingController();
  final _companyController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();

  // Social media controllers
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _pinterestController = TextEditingController();

  bool _isLoading = false;

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
  void initState() {
    super.initState();
    if (widget.preFilledName != null) {
      _nameController.text = widget.preFilledName!;
    }
    if (widget.preFilledEmail != null) {
      _emailController.text = widget.preFilledEmail!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Contact'),
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
      body: _buildAddContactForm(context),
    );
  }

  Widget _buildAddContactForm(BuildContext context) {
    return SingleChildScrollView(
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
                    child: const Icon(
                      Icons.person_add,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement image picker
                    },
                    child: const Text('Add Photo'),
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
                prefixIcon: Icon(Icons.person),
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
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter an email address';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value.trim())) {
                  return 'Please enter a valid email';
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
            ),
            const SizedBox(height: 16),

            // Scan Business Card Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _scanBusinessCard,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Scan Business Card'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
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
                prefixIcon: Icon(Icons.work),
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
                prefixIcon: Icon(Icons.language),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value != null && value.trim().isNotEmpty) {
                  // Basic URL validation
                  final urlPattern = RegExp(
                    r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
                    caseSensitive: false,
                  );
                  if (!urlPattern.hasMatch(value.trim())) {
                    return 'Please enter a valid website URL';
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
                prefixIcon:
                    Icon(FontAwesomeIcons.instagram, color: Color(0xFFE4405F)),
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
                prefixIcon:
                    Icon(FontAwesomeIcons.facebook, color: Color(0xFF1877F2)),
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
                prefixIcon:
                    Icon(FontAwesomeIcons.linkedin, color: Color(0xFF0A66C2)),
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
                prefixIcon:
                    Icon(FontAwesomeIcons.youtube, color: Color(0xFFFF0000)),
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
                prefixIcon:
                    Icon(FontAwesomeIcons.pinterest, color: Color(0xFFBD081C)),
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
                prefixIcon: Icon(Icons.note),
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
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Contact',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Scan business card and extract contact information
  Future<void> _scanBusinessCard() async {
    try {
      final result = await Navigator.push<BusinessCardData>(
        context,
        MaterialPageRoute(
          builder: (context) => BusinessCardScannerPage(
            onDataExtracted: _populateFormWithScannedData,
          ),
        ),
      );

      if (result != null) {
        _populateFormWithScannedData(result);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to scan business card: $e');
      }
    }
  }

  /// Populate form fields with scanned business card data
  void _populateFormWithScannedData(BusinessCardData data) {
    setState(() {
      if (data.name.isNotEmpty) _nameController.text = data.name;
      if (data.email.isNotEmpty) _emailController.text = data.email;
      if (data.phone.isNotEmpty) _phoneController.text = data.phone;
      if (data.company.isNotEmpty) _companyController.text = data.company;
      if (data.position.isNotEmpty) _positionController.text = data.position;
      if (data.website.isNotEmpty) _websiteController.text = data.website;

      // Populate social media fields
      if (data.linkedinUrl != null && data.linkedinUrl!.isNotEmpty) {
        _linkedinController.text = data.linkedinUrl!;
      }
      if (data.facebookUrl != null && data.facebookUrl!.isNotEmpty) {
        _facebookController.text = data.facebookUrl!;
      }
      if (data.instagramUrl != null && data.instagramUrl!.isNotEmpty) {
        _instagramController.text = data.instagramUrl!;
      }
      if (data.youtubeUrl != null && data.youtubeUrl!.isNotEmpty) {
        _youtubeController.text = data.youtubeUrl!;
      }
      if (data.pinterestUrl != null && data.pinterestUrl!.isNotEmpty) {
        _pinterestController.text = data.pinterestUrl!;
      }

      // Add raw text to notes if no other data was extracted
      if (data.rawText.isNotEmpty && !data.hasData) {
        _notesController.text = 'Raw OCR text:\n${data.rawText}';
      }
    });

    if (mounted) {
      _showSuccessSnackBar('Contact information extracted successfully!');
    }
  }

  Future<void> _saveContact() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = widget.user;
      final serviceManager = widget.serviceManager;
      final email = _emailController.text.trim();

      // Check for duplicate email
      final isDuplicate = await serviceManager.contactService.isEmailDuplicate(
        currentUser.id,
        email,
      );

      if (isDuplicate) {
        if (mounted) {
          _showErrorSnackBar('A contact with this email already exists.');
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Create the contact object
      final contact = Contact(
        id: '', // Will be generated by Firestore
        ownerId: currentUser.id,
        owner: currentUser,
        name: _nameController.text.trim(),
        displayName: _nameController.text.trim(),
        email: email,
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        company: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        website: _websiteController.text.trim().isEmpty
            ? null
            : _websiteController.text.trim(),
        position: _positionController.text.trim().isEmpty
            ? null
            : _positionController.text.trim(),
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
        isFavorite: false,
        isBlocked: false,
        chamberMember: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save the contact using ServiceManager
      await serviceManager.contactService.createContact(contact);

      if (mounted) {
        _showSuccessSnackBar('Contact saved successfully!');

        // If we have a returnToChatId, navigate back to chat with the new contact
        if (widget.returnToChatId != null) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.chat,
            arguments: {'chatId': widget.returnToChatId},
          );
        } else {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to save contact: ${e.toString()}');
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
