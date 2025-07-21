import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/ocr_config.dart';
import 'ocr_service.dart';

/// Enhanced OCR Service that combines multiple OCR providers and AI-powered parsing
class EnhancedOCRService {
  static EnhancedOCRService? _instance;
  static EnhancedOCRService get instance =>
      _instance ??= EnhancedOCRService._internal();

  EnhancedOCRService._internal();

  final OCRService _mlKitService = OCRService.instance;
  final OCRConfig _config = OCRConfig.instance;
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  ));

  /// Extract text from image using ML Kit OCR
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      // Validate input file
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist');
      }

      final fileSize = await imageFile.length();
      if (fileSize == 0) {
        throw Exception('Image file is empty');
      }

      if (fileSize > 10 * 1024 * 1024) {
        // 10MB limit
        throw Exception('Image file is too large (max 10MB)');
      }

      String extractedText = '';

      // Use ML Kit for text extraction
      try {
        final mlKitText = await _mlKitService.extractTextFromImage(imageFile);
        if (mlKitText.isNotEmpty) {
          extractedText = mlKitText;
          debugPrint(
              'ML Kit OCR successful: ${mlKitText.length} characters extracted');
        }
      } catch (e) {
        debugPrint('ML Kit OCR failed: $e');
        throw Exception('OCR processing failed: $e');
      }

      return extractedText;
    } catch (e) {
      throw Exception('Failed to extract text from image: $e');
    }
  }

  /// Parse business card text with AI-enhanced parsing
  Future<BusinessCardData> parseBusinessCardTextWithAI(String rawText) async {
    try {
      // First try AI-enhanced parsing if enabled
      if (_config.hasEnhancedFeatures) {
        try {
          return await _parseWithOpenAI(rawText);
        } catch (e) {
          debugPrint('AI parsing failed, falling back to regex: $e');
        }
      }

      // Fallback to regex-based parsing
      return _mlKitService.parseBusinessCardText(rawText);
    } catch (e) {
      throw Exception('Failed to parse business card text: $e');
    }
  }

  /// Parse business card text using OpenAI
  Future<BusinessCardData> _parseWithOpenAI(String rawText) async {
    if (!_config.isOpenAIConfigured) {
      throw Exception('OpenAI API key not configured');
    }

    final prompt = '''
Please parse the following business card text and extract structured information. Return the result as a JSON object with the following fields:
- name: Full name of the person
- email: Email address
- phone: Phone number
- company: Company name
- position: Job title/position
- website: Website URL
- address: Physical address (if present)
- socialMedia: Array of social media URLs (LinkedIn, Facebook, Twitter, Instagram, etc.)

Business card text:
$rawText

Return only the JSON object, no additional text.
''';

    try {
      final response = await _dio.post(
        'https://api.openai.com/v1/chat/completions',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_config.openaiApiKey}',
          },
        ),
        data: {
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a business card parser. Extract contact information and return it as JSON.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 500,
          'temperature': 0.1,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final content = data['choices'][0]['message']['content'];

        // Extract JSON from the response
        final jsonMatch =
            RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}', dotAll: true)
                .firstMatch(content);
        if (jsonMatch != null) {
          try {
            final jsonData = jsonDecode(jsonMatch.group(0)!);

            return BusinessCardData(
              name: jsonData['name'] ?? '',
              email: jsonData['email'] ?? '',
              phone: jsonData['phone'] ?? '',
              company: jsonData['company'] ?? '',
              position: jsonData['position'] ?? '',
              website: jsonData['website'] ?? '',
              address: jsonData['address'] ?? '',
              socialMedia: List<String>.from(jsonData['socialMedia'] ?? []),
              rawText: rawText,
            );
          } catch (jsonError) {
            debugPrint('Failed to parse JSON from OpenAI response: $jsonError');
            throw Exception('Failed to parse JSON from OpenAI response');
          }
        }
      }

      throw Exception('Failed to parse OpenAI response');
    } catch (e) {
      throw Exception('OpenAI API call failed: $e');
    }
  }

  /// Check if text recognition is available
  Future<bool> isTextRecognitionAvailable() async {
    return await _mlKitService.isTextRecognitionAvailable();
  }

  /// Get configuration information
  Map<String, dynamic> getConfigurationInfo() {
    return _config.configurationSummary;
  }

  /// Get detailed OCR status information
  Future<Map<String, dynamic>> getOCRStatus() async {
    return {
      'enhancedOCRService': 'Active',
      'mlKitService': 'Active',
      'config': _config.configurationSummary,
      'availableProviders': _config.availableProviders,
      'currentProvider': _config.ocrProvider,
      'providerDisplayName': _config.currentProviderDisplayName,
    };
  }

  /// Dispose resources
  void dispose() {
    _mlKitService.dispose();
  }
}
