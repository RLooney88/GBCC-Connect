import 'package:flutter/material.dart';
import '../../features/auth/login_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/profile/edit_profile_page.dart';
import '../../features/contacts/contact_library_page.dart';
import '../../features/contacts/add_contact_page.dart';
import '../../features/contacts/edit_contact_page.dart';
import '../../features/conversations/conversations_page.dart';
import '../../features/conversations/chat_page.dart';
import '../../features/settings/settings_controller.dart';
import '../../features/settings/settings_service.dart';
import '../../features/settings/settings_view.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while navigating to the route
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
        );

      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardPage(),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => const ProfilePage(),
        );

      case AppRoutes.editProfile:
        return MaterialPageRoute(
          builder: (_) => const EditProfilePage(),
        );

      case AppRoutes.contactLibrary:
        return MaterialPageRoute(
          builder: (_) => const ContactLibraryPage(),
        );

      case AppRoutes.addContact:
        return MaterialPageRoute(
          builder: (_) => const AddContactPage(),
        );

      case AppRoutes.editContact:
        return MaterialPageRoute(
          builder: (_) => const EditContactPage(),
        );

      case AppRoutes.conversations:
        return MaterialPageRoute(
          builder: (_) => const ConversationsPage(),
        );

      case AppRoutes.chat:
        return MaterialPageRoute(
          builder: (_) => const ChatPage(),
        );

      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) =>
              SettingsView(controller: SettingsController(SettingsService())),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
