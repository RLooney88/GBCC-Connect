// App-wide constants organized by category
class AppConstants {
  // App Information
  static const String appName = 'GBCC Connect';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'GBCC Connect Application';

  // User Defaults
  static const String defaultDisplayName = 'No Name';
  static const String defaultAvatarUrl = 'https://via.placeholder.com/150';
  static const String defaultEmail = 'user@example.com';

  // API & Network
  static const int apiTimeoutSeconds = 30;
  static const int maxRetryAttempts = 3;
  static const String baseApiUrl = 'https://api.gbcc.com';
  static const String apiVersion = 'v1';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String postsCollection = 'posts';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String themeKey = 'app_theme';
  static const String languageKey = 'app_language';
  static const String onboardingKey = 'onboarding_completed';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int minDisplayNameLength = 2;
  static const int maxDisplayNameLength = 50;
  static const int maxBioLength = 500;

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;
  static const double iconSize = 24.0;
  static const double avatarSize = 40.0;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File Upload
  static const int maxImageSizeMB = 10;
  static const int maxFileSizeMB = 50;
  static const List<String> allowedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp'
  ];
  static const List<String> allowedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'txt'
  ];

  // Error Messages
  static const String networkErrorMessage =
      'Network error. Please check your connection.';
  static const String serverErrorMessage =
      'Server error. Please try again later.';
  static const String unknownErrorMessage = 'An unknown error occurred.';
  static const String invalidEmailMessage =
      'Please enter a valid email address.';
  static const String weakPasswordMessage =
      'Password must be at least 8 characters long.';

  // Success Messages
  static const String profileUpdatedMessage = 'Profile updated successfully.';
  static const String passwordChangedMessage = 'Password changed successfully.';
  static const String emailSentMessage = 'Email sent successfully.';

  // Date Formats
  static const String dateFormat = 'MMM dd, yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'MMM dd, yyyy HH:mm';

  // Regex Patterns
  static const String emailRegex = r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$';
  static const String phoneRegex = r'^\+?[\d\s-()]{10,}$';
  static const String urlRegex =
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';

  // Feature Flags
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashlytics = true;
  static const bool enableRemoteConfig = true;

  // Cache Settings
  static const int imageCacheSize = 100;
  static const Duration cacheExpiration = Duration(days: 7);

  // Deep Links
  static const String deepLinkScheme = 'gbccconnect';
  static const String deepLinkHost = 'app.gbcc.com';

  // Social Media
  static const String facebookUrl = 'https://facebook.com/gbccconnect';
  static const String twitterUrl = 'https://twitter.com/gbccconnect';
  static const String instagramUrl = 'https://instagram.com/gbccconnect';
  static const String linkedinUrl = 'https://linkedin.com/company/gbccconnect';

  // Support
  static const String supportEmail = 'support@gbcc.com';
  static const String privacyPolicyUrl = 'https://gbcc.com/privacy';
  static const String termsOfServiceUrl = 'https://gbcc.com/terms';

  // App Store Links
  static const String appStoreUrl = 'https://apps.apple.com/app/gbcc-connect';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.gbcc.connect';

  // Development
  static const bool isDebugMode = true;
  static const String debugApiUrl = 'https://dev-api.gbcc.com';
  static const String stagingApiUrl = 'https://staging-api.gbcc.com';
  static const String productionApiUrl = 'https://api.gbcc.com';
}

// Theme-specific constants
class ThemeConstants {
  static const double elevation = 4.0;
  static const double cardElevation = 2.0;
  static const double appBarElevation = 0.0;

  // Colors (you can customize these based on your theme)
  static const int primaryColorValue = 0xFF2196F3;
  static const int accentColorValue = 0xFFFF4081;
  static const int backgroundColorValue = 0xFFF5F5F5;
  static const int surfaceColorValue = 0xFFFFFFFF;
  static const int errorColorValue = 0xFFD32F2F;
  static const int successColorValue = 0xFF388E3C;
  static const int warningColorValue = 0xFFF57C00;
  static const int infoColorValue = 0xFF1976D2;
}

// Route names for navigation
class RouteConstants {
  static const String home = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String chat = '/chat';
  static const String notifications = '/notifications';
  static const String search = '/search';
  static const String onboarding = '/onboarding';
  static const String forgotPassword = '/forgot-password';
  static const String verifyEmail = '/verify-email';
  static const String emailVerification = '/email-verification';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String privacySettings = '/privacy-settings';
  static const String help = '/help';
  static const String about = '/about';
}

// Asset paths
class AssetConstants {
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';
  static const String fontsPath = 'assets/fonts/';
  static const String animationsPath = 'assets/animations/';

  // Common image assets
  static const String logo = '${imagesPath}logo.png';
  static const String placeholder = '${imagesPath}placeholder.png';
  static const String avatar = '${imagesPath}avatar.png';
  static const String background = '${imagesPath}background.png';

  // Icon assets
  static const String homeIcon = '${iconsPath}home.svg';
  static const String profileIcon = '${iconsPath}profile.svg';
  static const String settingsIcon = '${iconsPath}settings.svg';
  static const String chatIcon = '${iconsPath}chat.svg';
  static const String notificationIcon = '${iconsPath}notification.svg';
  static const String searchIcon = '${iconsPath}search.svg';
}
