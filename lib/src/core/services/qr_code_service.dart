import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../models/user.dart';

/// QR Code Service
/// Mission: Handle QR code generation, sharing, and data encoding/decoding
/// Responsibilities:
/// - Generate QR codes for user profiles
/// - Encode/decode user data for QR codes
/// - Share QR codes as images
/// - Handle QR code scanning and data extraction
class QRCodeService {
  static QRCodeService? _instance;
  static QRCodeService get instance => _instance ??= QRCodeService._internal();

  QRCodeService._internal();

  /// Generate QR code data for a user profile
  /// This creates a structured JSON object with user information
  String generateQRData(User user) {
    final qrData = {
      'type': 'gbcc_connect_profile',
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'user': {
        'id': user.id,
        'name': user.name,
        'displayName': user.displayName,
        'email': user.email,
        'phone': user.phone,
        'company': user.company,
        'title': user.title,
        'website': user.website,
        'address': user.address,
        'social': {
          'linkedin': user.linkedin,
          'instagram': user.instagram,
          'facebook': user.facebook,
          'youtube': user.youtube,
          'pinterest': user.pinterest,
        },
      },
    };

    return jsonEncode(qrData);
  }

  /// Parse QR code data and extract user information
  Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final data = jsonDecode(qrData) as Map<String, dynamic>;

      // Validate that this is a GBCC Connect profile QR code
      if (data['type'] != 'gbcc_connect_profile') {
        return null;
      }

      return data;
    } catch (e) {
      return null;
    }
  }

  /// Generate QR code widget with user data
  Widget generateQRCodeWidget(
    User user, {
    double size = 200,
    Color? foregroundColor,
    Color? backgroundColor,
  }) {
    final qrData = generateQRData(user);

    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor ?? Colors.black,
      backgroundColor: backgroundColor ?? Colors.white,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
      padding: const EdgeInsets.all(8),
    );
  }

  /// Generate QR code as image bytes
  Future<Uint8List> generateQRCodeImage(
    User user, {
    double size = 200,
    Color? foregroundColor,
    Color? backgroundColor,
  }) async {
    final qrData = generateQRData(user);

    final qrPainter = QrPainter(
      data: qrData,
      version: QrVersions.auto,
      color: foregroundColor ?? Colors.black,
      emptyColor: backgroundColor ?? Colors.white,
      gapless: true,
      embeddedImageStyle: null,
      embeddedImage: null,
      errorCorrectionLevel: QrErrorCorrectLevel.M,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(200, 200);

    qrPainter.paint(canvas, size);
    final picture = recorder.endRecording();
    final image =
        await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  /// Save QR code to temporary file for sharing
  Future<String> saveQRCodeToFile(
    User user, {
    double size = 200,
    Color? foregroundColor,
    Color? backgroundColor,
  }) async {
    final imageBytes = await generateQRCodeImage(
      user,
      size: size,
      foregroundColor: foregroundColor,
      backgroundColor: backgroundColor,
    );

    final tempDir = await getTemporaryDirectory();
    final fileName =
        'qr_code_${user.id}_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File('${tempDir.path}/$fileName');

    await file.writeAsBytes(imageBytes);
    return file.path;
  }

  /// Create a styled QR code widget with user info overlay
  Widget generateStyledQRCodeWidget(
    User user, {
    double size = 200,
    Color? foregroundColor,
    Color? backgroundColor,
    bool showUserInfo = true,
  }) {
    final displayName = user.displayName ?? user.name ?? 'User';

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // QR Code
          Center(
            child: generateQRCodeWidget(
              user,
              size: size * 0.8,
              foregroundColor: foregroundColor,
              backgroundColor: backgroundColor,
            ),
          ),

          // User info overlay (optional)
          if (showUserInfo)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Validate if a QR code contains valid user data
  bool isValidUserQRCode(String qrData) {
    final parsed = parseQRData(qrData);
    if (parsed == null) return false;

    final user = parsed['user'] as Map<String, dynamic>?;
    if (user == null) return false;

    // Check for required fields
    return user['id'] != null && user['email'] != null;
  }

  /// Extract user data from QR code
  Map<String, dynamic>? extractUserDataFromQR(String qrData) {
    final parsed = parseQRData(qrData);
    return parsed?['user'] as Map<String, dynamic>?;
  }
}
