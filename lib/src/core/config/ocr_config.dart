import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration service for OCR settings
class OCRConfig {
  static OCRConfig? _instance;
  static OCRConfig get instance => _instance ??= OCRConfig._internal();

  OCRConfig._internal();

  /// Get the configured OCR provider
  String get ocrProvider {
    try {
      return dotenv.env['OCR_PROVIDER'] ?? 'mlkit';
    } catch (e) {
      // If dotenv is not initialized, return default
      return 'mlkit';
    }
  }

  /// Check if AI-enhanced parsing is enabled
  bool get enableAIEnhancedParsing {
    try {
      return dotenv.env['ENABLE_AI_ENHANCED_PARSING'] == 'true';
    } catch (e) {
      // If dotenv is not initialized, return default
      return false;
    }
  }

  /// Get OpenAI API key
  String? get openaiApiKey {
    try {
      return dotenv.env['OPENAI_API_KEY'];
    } catch (e) {
      // If dotenv is not initialized, return null
      return null;
    }
  }

  /// Check if OpenAI is configured
  bool get isOpenAIConfigured =>
      openaiApiKey != null && openaiApiKey!.isNotEmpty;

  /// Get available OCR providers
  List<String> get availableProviders {
    return <String>['mlkit'];
  }

  /// Get OCR provider display names
  Map<String, String> get providerDisplayNames => {
        'mlkit': 'Google ML Kit',
      };

  /// Get current OCR provider display name
  String get currentProviderDisplayName {
    return providerDisplayNames[ocrProvider] ?? 'Unknown Provider';
  }

  /// Check if enhanced features are available
  bool get hasEnhancedFeatures {
    return enableAIEnhancedParsing && isOpenAIConfigured;
  }

  /// Get OCR configuration summary
  Map<String, dynamic> get configurationSummary => {
        'provider': ocrProvider,
        'providerDisplayName': currentProviderDisplayName,
        'aiEnhancedParsing': enableAIEnhancedParsing,
        'openaiConfigured': isOpenAIConfigured,
        'availableProviders': availableProviders,
        'hasEnhancedFeatures': hasEnhancedFeatures,
      };
}
