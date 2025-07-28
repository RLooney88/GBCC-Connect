import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import '../models/user.dart';
import 'qr_code_service.dart';

/// Share Service
/// Mission: Handle sharing functionality for QR codes and other content
/// Responsibilities:
/// - Share QR code images
/// - Share user profile information
/// - Handle platform-specific sharing
/// - Generate shareable content
class ShareService {
  static ShareService? _instance;
  static ShareService get instance => _instance ??= ShareService._internal();

  ShareService._internal();

  /// Share QR code as image file
  Future<bool> shareQRCode(User user, {String? message}) async {
    try {
      final qrCodeService = QRCodeService.instance;
      final filePath = await qrCodeService.saveQRCodeToFile(user);

      final displayName = user.displayName ?? user.name ?? 'User';
      final shareMessage = message ??
          'Connect with $displayName on GBCC Connect! 📱\n\n'
              'Scan this QR code to automatically add this contact to your address book. '
              'The QR code contains all contact information including name, email, phone, and social media links.\n\n'
              'Download GBCC Connect app to scan and connect!';

      final success = await _shareFile(filePath, shareMessage);

      // Clean up temporary file after sharing
      await _cleanupTempFile(filePath);

      return success;
    } catch (e) {
      debugPrint('ShareService: Error sharing QR code: $e');
      return false;
    }
  }

  /// Share user profile information as text
  Future<bool> shareUserProfile(User user, {String? message}) async {
    try {
      final shareText = _generateProfileShareText(user, message);
      return await _shareText(shareText);
    } catch (e) {
      debugPrint('ShareService: Error sharing user profile: $e');
      return false;
    }
  }

  /// Generate shareable text for user profile
  String _generateProfileShareText(User user, String? customMessage) {
    final displayName = user.displayName ?? user.name ?? 'User';
    final company = user.company;
    final title = user.title;
    final email = user.email;
    final phone = user.phone;
    final website = user.website;

    final message = customMessage ?? 'Connect with me on GBCC Connect!';

    final profileInfo = <String>[];

    if (company != null && company.isNotEmpty) {
      profileInfo.add('Company: $company');
    }
    if (title != null && title.isNotEmpty) {
      profileInfo.add('Title: $title');
    }
    if (email.isNotEmpty) {
      profileInfo.add('Email: $email');
    }
    if (phone != null && phone.isNotEmpty) {
      profileInfo.add('Phone: $phone');
    }
    if (website != null && website.isNotEmpty) {
      profileInfo.add('Website: $website');
    }

    final profileText = profileInfo.isNotEmpty
        ? '\n\nProfile Information:\n${profileInfo.join('\n')}'
        : '';

    return '$message\n\n$displayName$profileText\n\nDownload GBCC Connect to connect with me!';
  }

  /// Share text content
  Future<bool> _shareText(String text) async {
    try {
      // Try native sharing first
      await Share.share(
        text,
        subject: 'GBCC Connect Profile',
      );

      // Share.share() returns void, so we assume success if no exception
      return true;
    } catch (e) {
      debugPrint('ShareService: Error sharing text: $e');

      // Fallback to email sharing
      try {
        final uri = Uri.parse(
            'mailto:?subject=GBCC Connect Profile&body=${Uri.encodeComponent(text)}');

        if (await canLaunchUrl(uri)) {
          return await launchUrl(uri);
        } else {
          // Final fallback: copy to clipboard
          return await _copyToClipboard(text);
        }
      } catch (e) {
        debugPrint('ShareService: Error with email fallback: $e');
        // Final fallback: copy to clipboard
        return await _copyToClipboard(text);
      }
    }
  }

  /// Share file (QR code image) with proper platform sharing
  Future<bool> _shareFile(String filePath, String message) async {
    try {
      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        debugPrint('ShareService: File does not exist: $filePath');
        return false;
      }

      // Use Share.shareXFiles for proper file sharing
      await Share.shareXFiles(
        [XFile(filePath)],
        text: message,
        subject: 'GBCC Connect QR Code',
      );

      // Share.shareXFiles() returns void, so we assume success if no exception
      return true;
    } catch (e) {
      debugPrint('ShareService: Error sharing file: $e');

      // Fallback: try to copy file path to clipboard
      final fallbackText = 'QR Code saved to: $filePath\n\n$message';
      return await _copyToClipboard(fallbackText);
    }
  }

  /// Copy text to clipboard with proper implementation
  Future<bool> _copyToClipboard(String text) async {
    try {
      await Clipboard.setData(ClipboardData(text: text));
      debugPrint('ShareService: Text copied to clipboard successfully');
      return true;
    } catch (e) {
      debugPrint('ShareService: Error copying to clipboard: $e');
      return false;
    }
  }

  /// Clean up temporary file
  Future<void> _cleanupTempFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('ShareService: Temporary file cleaned up: $filePath');
      }
    } catch (e) {
      debugPrint('ShareService: Error cleaning up temporary file: $e');
    }
  }

  /// Generate a shareable link for the user profile
  String generateProfileLink(User user) {
    // This would typically be a deep link to your app
    // For now, we'll create a simple URL scheme
    return 'gbccconnect://profile/${user.id}';
  }

  /// Share profile link
  Future<bool> shareProfileLink(User user, {String? message}) async {
    try {
      final link = generateProfileLink(user);
      final displayName = user.displayName ?? user.name ?? 'User';
      final shareMessage =
          message ?? 'Connect with $displayName on GBCC Connect!';

      final shareText = '$shareMessage\n\n$link';
      return await _shareText(shareText);
    } catch (e) {
      debugPrint('ShareService: Error sharing profile link: $e');
      return false;
    }
  }

  /// Get share options for a user
  List<ShareOption> getShareOptions(User user) {
    return [
      ShareOption(
        title: 'Share QR Code',
        subtitle: 'Share your QR code as an image',
        icon: Icons.qr_code,
        action: () => shareQRCode(user),
      ),
      ShareOption(
        title: 'Share Profile',
        subtitle: 'Share your profile information as text',
        icon: Icons.person,
        action: () => shareUserProfile(user),
      ),
      ShareOption(
        title: 'Share Link',
        subtitle: 'Share a link to your profile',
        icon: Icons.link,
        action: () => shareProfileLink(user),
      ),
    ];
  }
}

/// Share option model
class ShareOption {
  final String title;
  final String subtitle;
  final IconData icon;
  final Future<bool> Function() action;

  ShareOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.action,
  });
}
