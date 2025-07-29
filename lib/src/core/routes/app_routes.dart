class AppRoutes {
  // Root route
  static const String home = '/';

  // Auth routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';

  // Main app routes
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';

  // Contact routes
  static const String contactLibrary = '/contact-library';
  static const String addContact = '/add-contact';
  static const String editContact = '/edit-contact';
  static const String contactProfile = '/contact-profile';
  static const String qrCode = '/qr-code';
  static const String qrCodeScanner = '/qr-code-scanner';

  // Conversation routes
  static const String conversations = '/conversations';
  static const String chat = '/chat';
  static const String contactSelection = '/contact-selection';

  // Sample feature routes (can be removed later)
  static const String sampleItemList = '/sample-items';
  static const String sampleItemDetails = '/sample-item-details';

  // Helper method to get all routes
  static List<String> get allRoutes => [
        home,
        splash,
        login,
        register,
        forgotPassword,
        emailVerification,
        dashboard,
        profile,
        editProfile,
        settings,
        contactLibrary,
        addContact,
        editContact,
        contactProfile,
        qrCode,
        qrCodeScanner,
        conversations,
        chat,
        contactSelection,
        sampleItemList,
        sampleItemDetails,
      ];
}
