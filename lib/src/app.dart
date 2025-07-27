import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/routes/app_routes.dart';
import 'core/routes/route_generator.dart';
import 'features/settings/settings_controller.dart';
import 'features/settings/settings_view.dart';
import 'localization/app_localizations.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  // Define the primary color
  static const Color primaryColor = Color(0xFF00a6bb);

  @override
  Widget build(BuildContext context) {
    // Glue the SettingsController to the MaterialApp.
    //
    // The ListenableBuilder Widget listens to the SettingsController for changes.
    // Whenever the user updates their settings, the MaterialApp is rebuilt.
    return ListenableBuilder(
      listenable: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          // Providing a restorationScopeId allows the Navigator built by the
          // MaterialApp to restore the navigation stack when a user leaves and
          // returns to the app after it has been killed while running in the
          // background.
          restorationScopeId: 'app',

          // Provide the generated AppLocalizations to the MaterialApp. This
          // allows descendant Widgets to display the correct translations
          // depending on the user's locale.
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en', ''), // English, no country code
          ],

          // Use AppLocalizations to configure the correct application title
          // depending on the user's locale.
          //
          // The appTitle is defined in .arb files found in the localization
          // directory.
          onGenerateTitle: (BuildContext context) =>
              AppLocalizations.of(context)!.appTitle,

          // Define a light and dark color theme. Then, read the user's
          // preferred ThemeMode (light, dark, or system default) from the
          // SettingsController to display the correct theme.
          theme: ThemeData(
            primarySwatch: MaterialColor(primaryColor.value, {
              50: primaryColor.withOpacity(0.1),
              100: primaryColor.withOpacity(0.2),
              200: primaryColor.withOpacity(0.3),
              300: primaryColor.withOpacity(0.4),
              400: primaryColor.withOpacity(0.5),
              500: primaryColor,
              600: primaryColor.withOpacity(0.7),
              700: primaryColor.withOpacity(0.8),
              800: primaryColor.withOpacity(0.9),
              900: primaryColor.withOpacity(1.0),
            }),
            primaryColor: primaryColor,
            appBarTheme: const AppBarTheme(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            // Custom TextField theme for light mode
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[300]!, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[300]!, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
              labelStyle: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
              floatingLabelStyle: const TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Text selection theme
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: primaryColor,
              selectionColor: Color(0x1A00a6bb),
              selectionHandleColor: primaryColor,
            ),
            // Custom Checkbox theme for light mode
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryColor;
                }
                return Colors.transparent;
              }),
              checkColor: WidgetStateProperty.all(Colors.white),
              side: BorderSide(
                color: Colors.grey[400]!,
                width: 2.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
            // Progress indicator theme for light mode
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: primaryColor,
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            primaryColor: primaryColor,
            appBarTheme: const AppBarTheme(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
            floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
            // Custom TextField theme for dark mode
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.grey[850],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[600]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[300]!, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.red[300]!, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
              labelStyle: TextStyle(
                color: Colors.grey[300],
                fontSize: 16,
              ),
              floatingLabelStyle: const TextStyle(
                color: primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            // Text selection theme for dark mode
            textSelectionTheme: TextSelectionThemeData(
              cursorColor: primaryColor,
              selectionColor: Color(0x1A00a6bb),
              selectionHandleColor: primaryColor,
            ),
            // Custom Checkbox theme for dark mode
            checkboxTheme: CheckboxThemeData(
              fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryColor;
                }
                return Colors.transparent;
              }),
              checkColor: WidgetStateProperty.all(Colors.white),
              side: BorderSide(
                color: Colors.grey[500]!,
                width: 2.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4.0),
              ),
              materialTapTargetSize: MaterialTapTargetSize.padded,
            ),
            progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: primaryColor,
            ),
            tabBarTheme: TabBarThemeData(indicatorColor: primaryColor),
          ),
          themeMode: settingsController.themeMode,

          // Use centralized route generation
          onGenerateRoute: (RouteSettings settings) {
            // For settings route, pass the settings controller as arguments
            if (settings.name == AppRoutes.settings) {
              return MaterialPageRoute(
                settings: settings,
                builder: (context) =>
                    SettingsView(controller: settingsController),
              );
            }
            return RouteGenerator.generateRoute(settings);
          },

          // Set initial route
          initialRoute: '/splash',
        );
      },
    );
  }
}
