import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'src/app.dart';
import 'src/core/providers/auth_provider.dart';
import 'src/core/providers/firebase_provider.dart';
import 'src/core/config/firebase_config.dart';
import 'src/features/settings/settings_controller.dart';
import 'src/features/settings/settings_service.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase first
  try {
    await FirebaseConfigService.instance.initialize();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    // Continue with app startup even if Firebase fails
  }

  // Set up the SettingsController, which will glue user settings to multiple
  // Flutter Widgets.
  final settingsController = SettingsController(SettingsService());

  // Load the user's preferred theme while the splash screen is displayed.
  // This prevents a sudden theme change when the app is first displayed.
  await settingsController.loadSettings();

  // Run the app and pass in the SettingsController. The app listens to the
  // SettingsController for changes, then passes it further down to the
  // SettingsView.
  runApp(
    MultiProvider(
      providers: [
        // Provide the singleton AuthProvider (consolidated auth management)
        ChangeNotifierProvider.value(value: AuthProvider.instance),

        // Provide FirebaseProvider for service initialization
        ChangeNotifierProvider.value(value: FirebaseProvider()),

        // Provide auth state stream for reactive UI updates
        StreamProvider<dynamic>(
          create: (context) => AuthProvider.instance.authStateChanges,
          initialData: null,
        ),
      ],
      child: MyApp(settingsController: settingsController),
    ),
  );
}
