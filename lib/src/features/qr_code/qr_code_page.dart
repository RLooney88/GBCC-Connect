import 'package:flutter/material.dart';
import 'package:gbcc_connect_app/src/core/constants/constants.dart';
import 'package:gbcc_connect_app/src/shared/widgets/custom_snackbar.dart';
import '../../core/models/user.dart';
import '../../core/services/service_manager.dart';
import '../../core/routes/app_routes.dart';
import '../../app.dart';

class QRCodePage extends StatefulWidget {
  final User user;
  final ServiceManager serviceManager;

  const QRCodePage({
    super.key,
    required this.user,
    required this.serviceManager,
  });

  static const routeName = AppRoutes.qrCode;

  @override
  State<QRCodePage> createState() => _QRCodePageState();
}

class _QRCodePageState extends State<QRCodePage> {
  final bool _isGeneratingQR = false;
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sharing QR Code'),
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildQRCodeContent(context, widget.user),
    );
  }

  Widget _buildQRCodeContent(BuildContext context, dynamic user) {
    final displayName =
        user.displayName ?? user.name ?? AppConstants.defaultDisplayName;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // User Info Card
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: MyApp.primaryColor,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (user.email != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // QR Code Placeholder
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _isGeneratingQR
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Generating QR Code...'),
                      ],
                    ),
                  )
                : widget.serviceManager.qrCodeService
                    .generateStyledQRCodeWidget(
                    user,
                    size: 220,
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.white,
                    showUserInfo: false,
                  ),
          ),

          const SizedBox(height: 32),

          // Share Buttons
          Column(
            children: [
              // Primary Share Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSharing ? null : _shareQRCode,
                  icon: _isSharing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.share),
                  label: Text(_isSharing ? 'Sharing...' : 'Share QR Code'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MyApp.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),

          const SizedBox(height: 12),

          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: MyApp.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MyApp.primaryColor.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: MyApp.primaryColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'How to use:',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: MyApp.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '• Share your QR code via mobile sharing apps\n'
                  '• Recipients can scan the QR code to add you to their contacts\n'
                  '• The QR code contains all your contact information\n'
                  '• Works with any QR code scanner app',
                  style: TextStyle(
                    fontSize: 13,
                    color: MyApp.primaryColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _shareQRCode() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final displayName = widget.user.displayName ?? widget.user.name ?? 'User';
      final success = await widget.serviceManager.shareService.shareQRCode(
        widget.user,
        message: 'Connect with $displayName on GBCC Connect! 📱\n\n'
            'Scan this QR code to automatically add this contact to your address book. '
            'The QR code contains all contact information including name, email, phone, and social media links.\n\n'
            'Download GBCC Connect app to scan and connect!',
      );

      if (success) {
        context.showSuccessSnackBar('QR code shared successfully!');
      } else {
        context.showWarningSnackBar(
            'Sharing was cancelled or failed. The QR code has been copied to clipboard as a fallback.');
      }
    } catch (e) {
      context.showErrorSnackBar('Error sharing QR code: ${e.toString()}');
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  /// Share user profile as text
  Future<void> _shareProfile() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final success = await widget.serviceManager.shareService.shareUserProfile(
        widget.user,
        message: 'Connect with me on GBCC Connect!',
      );

      if (success) {
        context.showSuccessSnackBar('Profile shared successfully!');
      } else {
        context.showWarningSnackBar(
            'Sharing was cancelled or failed. Profile information has been copied to clipboard as a fallback.');
      }
    } catch (e) {
      context.showErrorSnackBar('Error sharing profile: ${e.toString()}');
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }

  /// Share profile link
  Future<void> _shareLink() async {
    setState(() {
      _isSharing = true;
    });

    try {
      final success = await widget.serviceManager.shareService.shareProfileLink(
        widget.user,
        message: 'Connect with me on GBCC Connect!',
      );

      if (success) {
        context.showSuccessSnackBar('Profile link shared successfully!');
      } else {
        context.showWarningSnackBar(
            'Sharing was cancelled or failed. Profile link has been copied to clipboard as a fallback.');
      }
    } catch (e) {
      context.showErrorSnackBar('Error sharing profile link: ${e.toString()}');
    } finally {
      setState(() {
        _isSharing = false;
      });
    }
  }
}
