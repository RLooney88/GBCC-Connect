import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

enum SnackBarType {
  success,
  warning,
  error,
  info,
}

class CustomSnackBar {
  static void show({
    required BuildContext context,
    required String message,
    required SnackBarType type,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool showCloseIcon = true,
  }) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          _buildIcon(type),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showCloseIcon)
            IconButton(
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 20,
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
      backgroundColor: _getBackgroundColor(type),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.all(16),
      duration: duration,
      action: action,
      elevation: 6,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static Widget _buildIcon(SnackBarType type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case SnackBarType.success:
        iconData = FontAwesomeIcons.checkCircle;
        iconColor = Colors.white;
        break;
      case SnackBarType.warning:
        iconData = FontAwesomeIcons.triangleExclamation;
        iconColor = Colors.white;
        break;
      case SnackBarType.error:
        iconData = FontAwesomeIcons.circleXmark;
        iconColor = Colors.white;
        break;
      case SnackBarType.info:
        iconData = FontAwesomeIcons.infoCircle;
        iconColor = Colors.white;
        break;
    }

    return FaIcon(
      iconData,
      color: iconColor,
      size: 20,
    );
  }

  static Color _getBackgroundColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return const Color(0xFF0E722F);
      case SnackBarType.warning:
        return const Color(0xFFC57702);
      case SnackBarType.error:
        return const Color(0xFFA82C23);
      case SnackBarType.info:
        return const Color(0xFF00a6bb);
    }
  }

  // Convenience methods for different types
  static void showSuccess({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool showCloseIcon = true,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.success,
      duration: duration,
      action: action,
      showCloseIcon: showCloseIcon,
    );
  }

  static void showWarning({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool showCloseIcon = true,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.warning,
      duration: duration,
      action: action,
      showCloseIcon: showCloseIcon,
    );
  }

  static void showError({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool showCloseIcon = true,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.error,
      duration: duration,
      action: action,
      showCloseIcon: showCloseIcon,
    );
  }

  static void showInfo({
    required BuildContext context,
    required String message,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool showCloseIcon = true,
  }) {
    show(
      context: context,
      message: message,
      type: SnackBarType.info,
      duration: duration,
      action: action,
      showCloseIcon: showCloseIcon,
    );
  }
}

// Extension for easier usage
extension SnackBarExtension on BuildContext {
  void showSuccessSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool showCloseIcon = true,
  }) {
    CustomSnackBar.showSuccess(
      context: this,
      message: message,
      duration: duration,
      action: action,
      showCloseIcon: showCloseIcon,
    );
  }

  void showWarningSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool showCloseIcon = true,
  }) {
    CustomSnackBar.showWarning(
      context: this,
      message: message,
      duration: duration,
      action: action,
      showCloseIcon: showCloseIcon,
    );
  }

  void showErrorSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool showCloseIcon = true,
  }) {
    CustomSnackBar.showError(
      context: this,
      message: message,
      duration: duration,
      action: action,
      showCloseIcon: showCloseIcon,
    );
  }

  void showInfoSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    bool showCloseIcon = true,
  }) {
    CustomSnackBar.showInfo(
      context: this,
      message: message,
      duration: duration,
      action: action,
      showCloseIcon: showCloseIcon,
    );
  }
}
