import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../core/models/user.dart';
import '../../core/services/service_manager.dart';
import '../../core/routes/app_routes.dart';
import '../../app.dart';

class EditProfilePage extends StatefulWidget {
  final User user;
  final ServiceManager serviceManager;

  const EditProfilePage({
    super.key,
    required this.user,
    required this.serviceManager,
  });

  static const routeName = AppRoutes.editProfile;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _companyController = TextEditingController();
  final _titleController = TextEditingController();
  final _websiteController = TextEditingController();
  final _notesController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();
  final _youtubeController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _pinterestController = TextEditingController();

  bool _isLoading = false;
  bool _isChamberMember = false;
  User? _originalUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadUserData();
    });
  }

  Future<void> _loadUserData() async {
    try {
      // Use the user passed to the widget instead of AuthProvider
      final user = widget.user;

      // Check if user is available
      _originalUser = user;
      _populateFormFields(user);
      debugPrint('EditProfilePage: User data loaded successfully');
    } catch (e) {
      debugPrint('EditProfilePage: Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  void _populateFormFields(User user) {
    if (!mounted) return;

    setState(() {
      _nameController.text = user.name ?? '';
      _emailController.text = user.email;
      _phoneController.text = user.phone ?? '';
      _displayNameController.text = user.displayName ?? '';
      _titleController.text = user.title ?? '';
      _companyController.text = user.company ?? '';
      _addressController.text = user.address ?? '';
      _websiteController.text = user.website ?? '';
      _notesController.text = user.notes ?? '';
      _instagramController.text = user.instagram ?? '';
      _facebookController.text = user.facebook ?? '';
      _youtubeController.text = user.youtube ?? '';
      _linkedinController.text = user.linkedin ?? '';
      _pinterestController.text = user.pinterest ?? '';
      _isChamberMember = user.chamberMember;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Create updated user object
      final updatedUser = _originalUser!.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        company: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
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
      );

      // Update user using ServiceManager
      await widget.serviceManager.userService
          .updateUser(updatedUser.id, updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('EditProfilePage: Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _displayNameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _youtubeController.dispose();
    _linkedinController.dispose();
    _pinterestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: _isLoading
                ? SizedBox(
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
      body:
          _originalUser == null ? _buildLoadingView() : _buildEditProfileForm(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading profile...'),
        ],
      ),
    );
  }

  Widget _buildEditProfileForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Basic Information Section
            _buildSectionHeader('Basic Information'),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email_outlined,
              enabled: false, // Email should not be editable
            ),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone',
              icon: Icons.phone,
            ),
            _buildTextField(
              controller: _displayNameController,
              label: 'Display Name',
              icon: Icons.person_outline,
            ),
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on_outlined,
              maxLines: 2,
            ),

            const SizedBox(height: 24),

            // Company Information Section
            _buildSectionHeader('Company Information'),
            _buildTextField(
              controller: _titleController,
              label: 'Title/Position',
              icon: Icons.work_outline,
            ),
            _buildTextField(
              controller: _companyController,
              label: 'Company',
              icon: Icons.business,
            ),
            _buildTextField(
              controller: _websiteController,
              label: 'Website',
              icon: Icons.language_outlined,
            ),

            const SizedBox(height: 24),

            // Additional Information Section
            _buildSectionHeader('Additional Information'),

            _buildTextField(
              controller: _notesController,
              label: 'Notes',
              icon: Icons.note_outlined,
              maxLines: 3,
            ),

            const SizedBox(height: 16),

            // Chamber Member Checkbox
            CheckboxListTile(
              title: const Text('Chamber Member'),
              subtitle: const Text('I am a member of the chamber'),
              value: _isChamberMember,
              onChanged: (value) {
                setState(() {
                  _isChamberMember = value ?? false;
                });
              },
              activeColor: MyApp.primaryColor,
            ),

            const SizedBox(height: 24),

            // Social Media Section
            _buildSectionHeader('Social Media'),
            _buildTextField(
              controller: _instagramController,
              label: 'Instagram',
              icon: FontAwesomeIcons.instagram,
              iconColor: const Color(0xFFE4405F),
            ),
            _buildTextField(
              controller: _facebookController,
              label: 'Facebook',
              icon: FontAwesomeIcons.facebook,
              iconColor: const Color(0xFF1877F2),
            ),
            _buildTextField(
              controller: _youtubeController,
              label: 'YouTube',
              icon: FontAwesomeIcons.youtube,
              iconColor: const Color(0xFFFF0000),
            ),
            _buildTextField(
              controller: _linkedinController,
              label: 'LinkedIn',
              icon: FontAwesomeIcons.linkedin,
              iconColor: const Color(0xFF0A66C2),
            ),
            _buildTextField(
              controller: _pinterestController,
              label: 'Pinterest',
              icon: FontAwesomeIcons.pinterest,
              iconColor: const Color(0xFFBD081C),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: iconColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: MyApp.primaryColor, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        validator: validator,
      ),
    );
  }
}
