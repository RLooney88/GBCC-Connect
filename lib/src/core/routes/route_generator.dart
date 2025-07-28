import 'package:flutter/material.dart';
import '../../features/auth/login_page.dart';
import '../../features/auth/register_page.dart';
import '../../features/auth/forgot_password_page.dart';
import '../../core/widgets/auth_splash_screen.dart';
import '../../core/widgets/authenticated_page_wrapper.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/profile/profile_page.dart';
import '../../features/profile/edit_profile_page.dart';
import '../../features/contacts/contact_library_page.dart';
import '../../features/contacts/add_contact_page.dart';
import '../../features/contacts/edit_contact_page.dart';
import '../../features/contacts/contact_profile_page.dart';
import '../../features/conversations/conversations_page.dart';
import '../../features/conversations/chat_page.dart';
import '../../features/conversations/contact_selection_page.dart';
import '../../features/qr_code/qr_code_page.dart';
import '../../features/qr_code/qr_code_scanner_page.dart';
import '../../core/models/contact.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while navigating to the route
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => DashboardPage(
              user: user,
              serviceManager: serviceManager,
            ),
          ),
        );

      case AppRoutes.splash:
        return MaterialPageRoute(
          builder: (_) => const AuthSplashScreen(),
        );

      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        );

      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => const RegisterScreen(),
        );

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
        );

      case AppRoutes.dashboard:
        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => DashboardPage(
              user: user,
              serviceManager: serviceManager,
            ),
          ),
        );

      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => ProfilePage(
              user: user,
              serviceManager: serviceManager,
            ),
          ),
        );

      case AppRoutes.editProfile:
        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => EditProfilePage(
              user: user,
              serviceManager: serviceManager,
            ),
          ),
        );

      case AppRoutes.contactLibrary:
        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => ContactLibraryPage(
              user: user,
              serviceManager: serviceManager,
            ),
          ),
        );

      case AppRoutes.addContact:
        // Extract optional parameters for pre-filling form
        String? preFilledName;
        String? preFilledEmail;
        String? returnToChatId;

        if (args is Map<String, dynamic>) {
          preFilledName = args['preFilledName'] as String?;
          preFilledEmail = args['preFilledEmail'] as String?;
          returnToChatId = args['returnToChatId'] as String?;
        }

        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => AddContactPage(
              user: user,
              serviceManager: serviceManager,
              preFilledName: preFilledName,
              preFilledEmail: preFilledEmail,
              returnToChatId: returnToChatId,
            ),
          ),
        );

      case AppRoutes.editContact:
        final contact = args as Contact?;
        if (contact == null) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              body: Center(
                child: Text('Contact not found'),
              ),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => EditContactPage(
              serviceManager: serviceManager,
              contact: contact,
            ),
          ),
        );

      case AppRoutes.contactProfile:
        // Extract contactId from arguments
        String? contactId;

        if (args is Map<String, dynamic>) {
          contactId = args['contactId'] as String?;
        } else if (args is String) {
          contactId = args;
        }

        if (contactId == null || contactId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: const Text('Invalid Contact'),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Invalid Contact Parameters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Missing required parameter: contactId',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => ContactProfilePage(
              user: user,
              serviceManager: serviceManager,
              contactId: contactId!,
            ),
          ),
        );

      case AppRoutes.conversations:
        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => ConversationsPage(
              user: user,
              serviceManager: serviceManager,
            ),
          ),
        );

      case AppRoutes.chat:
        // Extract chatId from arguments
        String? chatId;

        if (args is Map<String, dynamic>) {
          chatId = args['chatId'] as String?;
        } else if (args is String) {
          chatId = args;
        }

        if (chatId == null || chatId.isEmpty) {
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(
                title: const Text('Invalid Chat'),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Invalid Chat Parameters',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Missing required parameter: chatId',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => ChatPage(
              user: user,
              serviceManager: serviceManager,
              chatId: chatId!,
            ),
          ),
        );

      case AppRoutes.contactSelection:
        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => ContactSelectionPage(
              user: user,
              serviceManager: serviceManager,
            ),
          ),
        );

      case AppRoutes.qrCode:
        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => QRCodePage(
              user: user,
              serviceManager: serviceManager,
            ),
          ),
        );

      case AppRoutes.qrCodeScanner:
        return MaterialPageRoute(
          builder: (_) => AuthenticatedPageWrapper(
            child: (context, user, serviceManager) => QRCodeScannerPage(
              user: user,
              serviceManager: serviceManager,
            ),
          ),
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
