import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/firebase_provider.dart';
import '../../core/models/user.dart';
import '../../core/routes/app_routes.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

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
  final _titleController = TextEditingController();
  final _companyController = TextEditingController();
  final _companyPhoneController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _addressController = TextEditingController();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize Firebase provider
      context.read<FirebaseProvider>().initialize();
      _loadUserData();
    });
  }

  void _loadUserData() {
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _originalUser = user;
      setState(() {
        _nameController.text = user.name;
        _emailController.text = user.email;
        _phoneController.text = user.phone ?? '';
        _displayNameController.text = user.displayName ?? '';
        _titleController.text = user.title ?? '';
        _companyController.text = user.company ?? '';
        _companyPhoneController.text = user.companyPhone ?? '';
        _companyEmailController.text = user.companyEmail ?? '';
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _displayNameController.dispose();
    _titleController.dispose();
    _companyController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
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
        backgroundColor: Theme.of(context).primaryColor,
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
      body: Consumer2<AuthProvider, FirebaseProvider>(
        builder: (context, authProvider, firebaseProvider, child) {
          // Check if user is authenticated
          if (!authProvider.isAuthenticated) {
            return _buildUnauthenticatedView(context);
          }

          if (_originalUser == null) {
            return _buildLoadingView();
          }

          return _buildEditForm(context, authProvider, firebaseProvider);
        },
      ),
    );
  }

  Widget _buildUnauthenticatedView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Authentication Required',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please log in to edit your profile',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () =>
                Navigator.pushReplacementNamed(context, AppRoutes.login),
            child: const Text('Go to Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading profile data...'),
        ],
      ),
    );
  }

  Widget _buildEditForm(BuildContext context, AuthProvider authProvider,
      FirebaseProvider firebaseProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture Section
            _buildProfilePictureSection(context),
            const SizedBox(height: 24),

            // Basic Information Section
            _buildSectionHeader('Basic Information'),
            _buildTextField(
              controller: _nameController,
              label: 'Full Name',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            _buildTextField(
              controller: _displayNameController,
              label: 'Display Name',
              icon: Icons.badge,
              hint: 'How you want to be displayed',
            ),
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              icon: Icons.email,
              enabled: false, // Email should not be editable
              hint: 'Email cannot be changed',
            ),
            _buildTextField(
              controller: _phoneController,
              label: 'Phone Number',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: _titleController,
              label: 'Job Title',
              icon: Icons.work,
            ),
            const SizedBox(height: 16),

            // Company Information Section
            _buildSectionHeader('Company Information'),
            _buildTextField(
              controller: _companyController,
              label: 'Company Name',
              icon: Icons.business,
            ),
            _buildTextField(
              controller: _companyPhoneController,
              label: 'Company Phone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              controller: _companyEmailController,
              label: 'Company Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Address Section
            _buildSectionHeader('Address'),
            _buildTextField(
              controller: _addressController,
              label: 'Address',
              icon: Icons.location_on,
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Website Section
            _buildSectionHeader('Website'),
            _buildTextField(
              controller: _websiteController,
              label: 'Website',
              icon: Icons.language,
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 16),

            // Social Media Section
            _buildSectionHeader('Social Media'),
            _buildTextField(
              controller: _instagramController,
              label: 'Instagram',
              icon: Icons.camera_alt,
              prefix: '@',
            ),
            _buildTextField(
              controller: _facebookController,
              label: 'Facebook',
              icon: Icons.facebook,
            ),
            _buildTextField(
              controller: _youtubeController,
              label: 'YouTube',
              icon: Icons.play_circle_filled,
            ),
            _buildTextField(
              controller: _linkedinController,
              label: 'LinkedIn',
              icon: Icons.link,
            ),
            _buildTextField(
              controller: _pinterestController,
              label: 'Pinterest',
              icon: Icons.link,
            ),
            const SizedBox(height: 16),

            // Preferences Section
            _buildSectionHeader('Preferences'),
            _buildChamberMemberSwitch(),
            const SizedBox(height: 16),

            // Notes Section
            _buildSectionHeader('Notes'),
            _buildTextField(
              controller: _notesController,
              label: 'Notes',
              icon: Icons.note,
              maxLines: 4,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureSection(BuildContext context) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 60,
            backgroundColor: Theme.of(context).primaryColor,
            child: Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile picture upload coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.camera_alt),
            label: const Text('Change Photo'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    String? prefix,
    bool enabled = true,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon),
          prefixText: prefix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: !enabled,
          fillColor: enabled ? null : Colors.grey[100],
        ),
      ),
    );
  }

  Widget _buildChamberMemberSwitch() {
    return Card(
      child: SwitchListTile(
        title: const Text('Chamber Member'),
        subtitle: const Text('I am a member of the chamber'),
        value: _isChamberMember,
        onChanged: (value) {
          setState(() {
            _isChamberMember = value;
          });
        },
        activeColor: Theme.of(context).primaryColor,
        secondary: const Icon(Icons.business),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final firebaseProvider = context.read<FirebaseProvider>();
      final authProvider = context.read<AuthProvider>();

      // Create the updated user object
      final updatedUser = _originalUser!.copyWith(
        name: _nameController.text.trim(),
        displayName: _displayNameController.text.trim().isEmpty
            ? null
            : _displayNameController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        company: _companyController.text.trim().isEmpty
            ? null
            : _companyController.text.trim(),
        companyPhone: _companyPhoneController.text.trim().isEmpty
            ? null
            : _companyPhoneController.text.trim(),
        companyEmail: _companyEmailController.text.trim().isEmpty
            ? null
            : _companyEmailController.text.trim(),
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
        updatedAt: DateTime.now(),
      );

      // Update the user using Firebase
      await firebaseProvider.updateCurrentUser(updatedUser);

      // Update the auth provider's current user
      authProvider.updateCurrentUser(updatedUser);

      if (mounted) {
        _showSuccessSnackBar('Profile updated successfully!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to update profile: ${e.toString()}');
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
