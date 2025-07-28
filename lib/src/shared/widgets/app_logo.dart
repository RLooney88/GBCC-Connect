import 'package:flutter/material.dart';

/// A reusable widget for displaying the app logo/icon
class AppLogo extends StatelessWidget {
  /// The size of the logo
  final double size;

  /// The color of the logo (if using icon instead of image)
  final Color? color;

  /// Whether to use the app icon image or a fallback icon
  final bool useAppIcon;

  /// Additional styling for the logo
  final BoxDecoration? decoration;

  /// Padding around the logo
  final EdgeInsetsGeometry? padding;

  /// Whether to show a background circle
  final bool showBackground;

  /// Background color for the circle
  final Color? backgroundColor;

  const AppLogo({
    super.key,
    this.size = 80.0,
    this.color,
    this.useAppIcon = true,
    this.decoration,
    this.padding,
    this.showBackground = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget logoWidget = useAppIcon ? _buildAppIcon() : _buildFallbackIcon();

    if (showBackground) {
      logoWidget = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor ?? Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: logoWidget),
      );
    }

    return Container(
      padding: padding,
      decoration: decoration,
      child: logoWidget,
    );
  }

  /// Builds the app icon using the actual app icon asset
  Widget _buildAppIcon() {
    return Image.asset(
      'assets/images/app_icon.png', // Using the actual app icon
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback to icon if image fails to load
        return _buildFallbackIcon();
      },
    );
  }

  /// Builds a fallback icon using Material Icons
  Widget _buildFallbackIcon() {
    return Icon(
      Icons.connect_without_contact,
      size: size,
      color: color ?? Colors.blue,
    );
  }
}

/// A specialized logo widget for authentication screens
class AuthLogo extends StatelessWidget {
  /// The size of the logo
  final double size;

  /// The color theme to use
  final Color? primaryColor;

  /// Whether to show the app name
  final bool showAppName;

  /// Custom app name text
  final String? appName;

  /// Whether to show background circle
  final bool showBackground;

  const AuthLogo({
    super.key,
    this.size = 80.0,
    this.primaryColor,
    this.showAppName = true,
    this.appName,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppLogo(
          size: size,
          color: primaryColor,
          decoration: showBackground
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(size / 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
        ),
        if (showAppName) ...[
          const SizedBox(height: 16),
          Text(
            appName ?? 'GBCC Connect',
            style: TextStyle(
              fontSize: size * 0.3,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// A compact logo widget for headers and navigation
class CompactLogo extends StatelessWidget {
  /// The size of the logo
  final double size;

  /// The color theme to use
  final Color? color;

  const CompactLogo({
    super.key,
    this.size = 32.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppLogo(
      size: size,
      color: color,
      showBackground: false,
    );
  }
}
