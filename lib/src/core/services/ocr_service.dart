import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../config/ocr_config.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

/// Service for OCR (Optical Character Recognition) operations
/// Handles business card text extraction and parsing
class OCRService {
  static OCRService? _instance;
  static OCRService get instance => _instance ??= OCRService._internal();

  OCRService._internal();

  final OCRConfig _config = OCRConfig.instance;
  TextRecognizer? _textRecognizer;
  bool _mlKitAvailable = false;

  /// Initialize the text recognizer
  Future<void> _initializeTextRecognizer() async {
    if (_textRecognizer == null) {
      try {
        debugPrint('Initializing ML Kit text recognizer...');
        _textRecognizer = TextRecognizer();
        _mlKitAvailable = true;
        debugPrint('ML Kit text recognizer initialized successfully');
      } catch (e) {
        _mlKitAvailable = false;
        debugPrint('Failed to initialize ML Kit text recognizer: $e');
        throw Exception('Failed to initialize text recognizer: $e');
      }
    }
  }

  /// Check if ML Kit text recognition is available
  Future<bool> isTextRecognitionAvailable() async {
    try {
      await _initializeTextRecognizer();
      final isAvailable = _mlKitAvailable && _textRecognizer != null;
      debugPrint('ML Kit availability check: $isAvailable');
      return isAvailable;
    } catch (e) {
      debugPrint('ML Kit availability check failed: $e');
      return false;
    }
  }

  /// Extract text from an image file
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      // Use ML Kit if available and configured
      if (await isTextRecognitionAvailable()) {
        debugPrint('Attempting ML Kit OCR processing...');
        final mlKitResult = await _extractTextWithMLKit(imageFile);
        if (mlKitResult.isNotEmpty) {
          return mlKitResult;
        } else {
          debugPrint('ML Kit OCR returned empty result');
        }
      } else {
        debugPrint('ML Kit text recognition not available');
      }

      // Return empty string if ML Kit is not configured or failed
      debugPrint('No OCR provider available or configured');
      return '';
    } catch (e) {
      debugPrint('OCR processing failed: $e');
      throw Exception('Failed to extract text from image: $e');
    }
  }

  /// Extract text using ML Kit
  Future<String> _extractTextWithMLKit(File imageFile) async {
    if (_textRecognizer == null) {
      throw Exception('Text recognizer not initialized');
    }

    try {
      debugPrint('Processing image with ML Kit: ${imageFile.path}');

      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText =
          await _textRecognizer!.processImage(inputImage);

      String extractedText = '';
      int blockCount = 0;
      int lineCount = 0;

      for (TextBlock block in recognizedText.blocks) {
        blockCount++;
        for (TextLine line in block.lines) {
          lineCount++;
          final lineText = line.text.trim();
          if (lineText.isNotEmpty) {
            extractedText += '$lineText\n';
            debugPrint('Extracted line $lineCount: "$lineText"');
          }
        }
      }

      debugPrint(
          'ML Kit processing complete: $blockCount blocks, $lineCount lines');
      return extractedText.trim();
    } catch (e) {
      debugPrint('ML Kit processing error: $e');
      throw Exception('ML Kit text recognition failed: $e');
    }
  }

  /// Parse extracted text into structured contact information
  BusinessCardData parseBusinessCardText(String rawText) {
    final lines =
        rawText.split('\n').where((line) => line.trim().isNotEmpty).toList();

    String name = '';
    String email = '';
    String phone = '';
    String company = '';
    String position = '';
    String website = '';
    String address = '';
    List<String> socialMedia = [];

    // Extract email
    final emailRegex =
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b');
    final emailMatch = emailRegex.firstMatch(rawText);
    if (emailMatch != null) {
      email = emailMatch.group(0)!;
    }

    // Extract phone numbers
    final phoneRegex = RegExp(r'(\+?[\d\s\-\(\)\.]{7,})');
    final phoneMatches = phoneRegex.allMatches(rawText);
    if (phoneMatches.isNotEmpty) {
      phone = phoneMatches.first.group(0)!.replaceAll(RegExp(r'[^\d\+]'), '');
    }

    // Extract website
    final websiteRegex = RegExp(r'https?://[^\s]+');
    final websiteMatch = websiteRegex.firstMatch(rawText);
    if (websiteMatch != null) {
      website = websiteMatch.group(0)!;
    }

    // Extract social media links
    final socialMediaPatterns = {
      'linkedin': RegExp(r'linkedin\.com/[^\s]+', caseSensitive: false),
      'facebook': RegExp(r'facebook\.com/[^\s]+', caseSensitive: false),
      'instagram': RegExp(r'instagram\.com/[^\s]+', caseSensitive: false),
      'twitter': RegExp(r'twitter\.com/[^\s]+', caseSensitive: false),
      'youtube': RegExp(r'youtube\.com/[^\s]+', caseSensitive: false),
      'pinterest': RegExp(r'pinterest\.com/[^\s]+', caseSensitive: false),
    };

    for (final entry in socialMediaPatterns.entries) {
      final match = entry.value.firstMatch(rawText);
      if (match != null) {
        socialMedia.add('https://${match.group(0)}');
      }
    }

    // Extract name (usually the first prominent line)
    if (lines.isNotEmpty) {
      // Look for a line that doesn't contain email, phone, or website patterns
      for (String line in lines.take(3)) {
        final cleanLine = line.trim();
        if (cleanLine.isNotEmpty &&
            !emailRegex.hasMatch(cleanLine) &&
            !phoneRegex.hasMatch(cleanLine) &&
            !websiteRegex.hasMatch(cleanLine) &&
            !cleanLine.contains('@') &&
            !cleanLine.contains('www.') &&
            !cleanLine.contains('http')) {
          name = cleanLine;
          break;
        }
      }
    }

    // Extract company and position
    for (String line in lines) {
      final cleanLine = line.trim();
      if (cleanLine.isNotEmpty && cleanLine != name) {
        // Look for job titles
        final jobTitleKeywords = [
          'CEO',
          'CTO',
          'CFO',
          'COO',
          'President',
          'Vice President',
          'VP',
          'Director',
          'Manager',
          'Lead',
          'Senior',
          'Junior',
          'Associate',
          'Coordinator',
          'Specialist',
          'Analyst',
          'Engineer',
          'Developer',
          'Designer',
          'Consultant',
          'Advisor',
          'Partner',
          'Founder',
          'Co-founder'
        ];

        bool isJobTitle = jobTitleKeywords.any((keyword) =>
            cleanLine.toLowerCase().contains(keyword.toLowerCase()));

        if (isJobTitle && position.isEmpty) {
          position = cleanLine;
        } else if (!isJobTitle &&
            !emailRegex.hasMatch(cleanLine) &&
            !phoneRegex.hasMatch(cleanLine) &&
            !websiteRegex.hasMatch(cleanLine) &&
            !cleanLine.contains('@') &&
            company.isEmpty) {
          company = cleanLine;
        }
      }
    }

    return BusinessCardData(
      name: name,
      email: email,
      phone: phone,
      company: company,
      position: position,
      website: website,
      address: address,
      socialMedia: socialMedia,
      rawText: rawText,
    );
  }

  /// Dispose resources
  void dispose() {
    _textRecognizer?.close();
  }

  /// Get configuration information
  Map<String, dynamic> getConfigurationInfo() {
    return _config.configurationSummary;
  }
}

/// Data class to hold parsed business card information
class BusinessCardData {
  final String name;
  final String email;
  final String phone;
  final String company;
  final String position;
  final String website;
  final String address;
  final List<String> socialMedia;
  final String rawText;

  BusinessCardData({
    required this.name,
    required this.email,
    required this.phone,
    required this.company,
    required this.position,
    required this.website,
    required this.address,
    required this.socialMedia,
    required this.rawText,
  });

  /// Check if any meaningful data was extracted
  bool get hasData =>
      name.isNotEmpty ||
      email.isNotEmpty ||
      phone.isNotEmpty ||
      company.isNotEmpty;

  /// Get LinkedIn URL if present
  String? get linkedinUrl => socialMedia.firstWhere(
        (url) => url.toLowerCase().contains('linkedin'),
        orElse: () => '',
      );

  /// Get Facebook URL if present
  String? get facebookUrl => socialMedia.firstWhere(
        (url) => url.toLowerCase().contains('facebook'),
        orElse: () => '',
      );

  /// Get Instagram URL if present
  String? get instagramUrl => socialMedia.firstWhere(
        (url) => url.toLowerCase().contains('instagram'),
        orElse: () => '',
      );

  /// Get YouTube URL if present
  String? get youtubeUrl => socialMedia.firstWhere(
        (url) => url.toLowerCase().contains('youtube'),
        orElse: () => '',
      );

  /// Get Pinterest URL if present
  String? get pinterestUrl => socialMedia.firstWhere(
        (url) => url.toLowerCase().contains('pinterest'),
        orElse: () => '',
      );
}
