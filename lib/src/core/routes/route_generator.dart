import 'package:flutter/material.dart';
import '../../features/auth/login_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/sample_feature/sample_item_details_view.dart';
import '../../features/sample_feature/sample_item_list_view.dart';
import '../../features/settings/settings_controller.dart';
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

      case AppRoutes.settings:
        // Extract settings controller from arguments
        if (args is SettingsController) {
          return MaterialPageRoute(
            builder: (_) => SettingsView(controller: args),
          );
        }
        // If no arguments were passed, it means the route is
        // being navigated to without any parameters, so we'll
        // just create an empty route.
        return _errorRoute();

      case AppRoutes.sampleItemList:
        return MaterialPageRoute(
          builder: (_) => const SampleItemListView(),
        );

      case AppRoutes.sampleItemDetails:
        // Extract item from arguments
        if (args is Map<String, dynamic> && args.containsKey('item')) {
          return MaterialPageRoute(
            builder: (_) => SampleItemDetailsView(item: args['item']),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const SampleItemDetailsView(),
        );

      // TODO: Add other routes as they are implemented
      // case AppRoutes.profile:
      //   return MaterialPageRoute(
      //     builder: (_) => const ProfilePage(),
      //   );

      // case AppRoutes.contactLibrary:
      //   return MaterialPageRoute(
      //     builder: (_) => const ContactLibraryPage(),
      //   );

      // case AppRoutes.addContact:
      //   return MaterialPageRoute(
      //     builder: (_) => const AddContactPage(),
      //   );

      // case AppRoutes.conversations:
      //   return MaterialPageRoute(
      //     builder: (_) => const ConversationsPage(),
      //   );

      default:
        // If there is no such named route, return an error page
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Route not found!'),
        ),
      );
    });
  }
}
