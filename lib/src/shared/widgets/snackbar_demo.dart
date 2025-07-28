import 'package:flutter/material.dart';
import 'custom_snackbar.dart';

class SnackBarDemo extends StatelessWidget {
  const SnackBarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SnackBar Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Custom SnackBar Examples',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Success SnackBar
            ElevatedButton.icon(
              onPressed: () {
                context.showSuccessSnackBar(
                  'Operation completed successfully!',
                  duration: const Duration(seconds: 3),
                );
              },
              icon: const Icon(Icons.check_circle),
              label: const Text('Show Success SnackBar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Warning SnackBar
            ElevatedButton.icon(
              onPressed: () {
                context.showWarningSnackBar(
                  'Please check your input before proceeding.',
                  duration: const Duration(seconds: 4),
                );
              },
              icon: const Icon(Icons.warning),
              label: const Text('Show Warning SnackBar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Error SnackBar
            ElevatedButton.icon(
              onPressed: () {
                context.showErrorSnackBar(
                  'An error occurred while processing your request.',
                  duration: const Duration(seconds: 5),
                );
              },
              icon: const Icon(Icons.error),
              label: const Text('Show Error SnackBar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // SnackBar with Action
            ElevatedButton.icon(
              onPressed: () {
                CustomSnackBar.showSuccess(
                  context: context,
                  message: 'File uploaded successfully!',
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: Colors.white,
                    onPressed: () {
                      // Handle undo action
                      context.showWarningSnackBar('Upload cancelled');
                    },
                  ),
                );
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Show SnackBar with Action'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 16),

            // Custom Duration SnackBar
            ElevatedButton.icon(
              onPressed: () {
                CustomSnackBar.show(
                  context: context,
                  message: 'This message will stay for 10 seconds',
                  type: SnackBarType.warning,
                  duration: const Duration(seconds: 10),
                  showCloseIcon: true,
                );
              },
              icon: const Icon(Icons.timer),
              label: const Text('Show Long Duration SnackBar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 40),

            // Usage Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usage Instructions:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Use context.showSuccessSnackBar() for success messages\n'
                    '• Use context.showWarningSnackBar() for warning messages\n'
                    '• Use context.showErrorSnackBar() for error messages\n'
                    '• Or use CustomSnackBar.show() for more control\n'
                    '• All methods support custom duration and actions',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
