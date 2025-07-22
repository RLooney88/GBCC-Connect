import 'package:url_launcher/url_launcher.dart';

/// Domain/Business Logic Layer: EmailService
/// Mission: Handle email operations for unregistered users
/// - Send emails to unregistered users when contacted
/// - Handle email templates and formatting
/// - Pure Dart code (no Flutter imports)
/// - Abstracts over URL launcher or any email service
class EmailService {
  static EmailService? _instance;
  static EmailService get instance => _instance ??= EmailService._internal();

  EmailService._internal();

  /// Send email to unregistered user
  /// This opens the default email client with a pre-filled message
  Future<bool> sendEmailToUnregisteredUser({
    required String toEmail,
    required String fromName,
    required String fromEmail,
    required String messageContent,
    String subject = 'Message from GBCC Connect App',
  }) async {
    try {
      final emailBody = _createEmailBody(
        fromName: fromName,
        fromEmail: fromEmail,
        messageContent: messageContent,
      );

      final emailUrl = _createEmailUrl(
        to: toEmail,
        subject: subject,
        body: emailBody,
      );

      final uri = Uri.parse(emailUrl);

      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      } else {
        throw Exception('Could not launch email client');
      }
    } catch (e) {
      throw Exception('Failed to send email: $e');
    }
  }

  /// Create email body with proper formatting
  String _createEmailBody({
    required String fromName,
    required String fromEmail,
    required String messageContent,
  }) {
    return '''
Hello,

You have received a message from $fromName ($fromEmail) through the GBCC Connect App.

Message:
$messageContent

---
This message was sent via GBCC Connect App.
To join the conversation and start chatting, please download the app and register with your email address.

Best regards,
GBCC Connect Team
''';
  }

  /// Create email URL for mailto: protocol
  String _createEmailUrl({
    required String to,
    required String subject,
    required String body,
  }) {
    final encodedSubject = Uri.encodeComponent(subject);
    final encodedBody = Uri.encodeComponent(body);

    return 'mailto:$to?subject=$encodedSubject&body=$encodedBody';
  }

  /// Check if email is valid
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Get email domain from email address
  String getEmailDomain(String email) {
    final parts = email.split('@');
    return parts.length > 1 ? parts[1] : '';
  }

  /// Create invitation email for unregistered users
  Future<bool> sendInvitationEmail({
    required String toEmail,
    required String fromName,
    required String fromEmail,
    String invitationMessage =
        'I would like to connect with you on GBCC Connect App.',
  }) async {
    return await sendEmailToUnregisteredUser(
      toEmail: toEmail,
      fromName: fromName,
      fromEmail: fromEmail,
      messageContent: invitationMessage,
      subject: 'Invitation to join GBCC Connect App',
    );
  }

  /// Send follow-up email for unregistered users
  Future<bool> sendFollowUpEmail({
    required String toEmail,
    required String fromName,
    required String fromEmail,
    String followUpMessage =
        'I sent you a message earlier. Please check your inbox.',
  }) async {
    return await sendEmailToUnregisteredUser(
      toEmail: toEmail,
      fromName: fromName,
      fromEmail: fromEmail,
      messageContent: followUpMessage,
      subject: 'Follow-up: Message from GBCC Connect App',
    );
  }
}
