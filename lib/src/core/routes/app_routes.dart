class AppRoutes {
  // Auth routes
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';

  // Main app routes
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Contact routes
  static const String contactLibrary = '/contact-library';
  static const String addContact = '/add-contact';
  static const String contactDetails = '/contact-details';

  // Conversation routes
  static const String conversations = '/conversations';
  static const String chat = '/chat';

  // Sample feature routes (can be removed later)
  static const String sampleItemList = '/sample-items';
  static const String sampleItemDetails = '/sample-item-details';

  // Helper method to get all routes
  static List<String> get allRoutes => [
        login,
        forgotPassword,
        dashboard,
        profile,
        settings,
        contactLibrary,
        addContact,
        contactDetails,
        conversations,
        chat,
        sampleItemList,
        sampleItemDetails,
      ];
}
