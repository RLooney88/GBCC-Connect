import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:gbcc_connect_app/src/shared/widgets/custom_snackbar.dart';
import '../../core/models/user.dart';
import '../../core/models/contact.dart';
import '../../core/services/service_manager.dart';
import '../../core/routes/app_routes.dart';
import '../../app.dart';

class QRCodeScannerPage extends StatefulWidget {
  final User user;
  final ServiceManager serviceManager;
  final Function(Map<String, dynamic>)?
      onDataExtracted; // Callback for form population

  const QRCodeScannerPage({
    super.key,
    required this.user,
    required this.serviceManager,
    this.onDataExtracted, // Optional callback for form population
  });

  static const routeName = '/qr-code-scanner';

  @override
  State<QRCodeScannerPage> createState() => _QRCodeScannerPageState();
}

class _QRCodeScannerPageState extends State<QRCodeScannerPage> {
  MobileScannerController? controller;
  bool _isScanning = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              setState(() {
                _isScanning = !_isScanning;
              });
              if (_isScanning) {
                controller?.start();
              } else {
                controller?.stop();
              }
            },
          ),
        ],
      ),
      body: _buildScannerContent(),
    );
  }

  Widget _buildScannerContent() {
    return Stack(
      children: [
        // QR Scanner View
        MobileScanner(
          controller: controller,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null && !_isProcessing) {
                _processQRCode(barcode.rawValue!);
                break; // Process only the first barcode
              }
            }
          },
        ),

        // Scanner Overlay
        CustomPaint(
          painter: ScannerOverlay(),
        ),

        // Instructions Overlay
        Positioned(
          top: 100,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Position the QR code within the frame to scan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),

        // Processing Overlay
        if (_isProcessing)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Processing QR Code...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _processQRCode(String qrData) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Pause scanning while processing
      controller?.stop();

      // Parse QR code data
      final qrCodeService = widget.serviceManager.qrCodeService;
      final parsedData = qrCodeService.parseQRData(qrData);

      if (parsedData == null) {
        context.showErrorSnackBar('Invalid QR code format');
        return;
      }

      // Extract user data
      final userData = qrCodeService.extractUserDataFromQR(qrData);
      if (userData == null) {
        context.showErrorSnackBar('Could not extract user data from QR code');
        return;
      }

      // Check if it's the same user
      if (userData['id'] == widget.user.id) {
        context.showWarningSnackBar('This is your own QR code!');
        return;
      }

      // If callback is provided, return data for form population
      if (widget.onDataExtracted != null) {
        Navigator.pop(context, userData);
        return;
      }

      // Show user info dialog for direct contact addition
      await _showUserInfoDialog(userData);
    } catch (e) {
      context.showErrorSnackBar('Error processing QR code: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
      // Resume scanning
      controller?.start();
    }
  }

  Future<void> _showUserInfoDialog(Map<String, dynamic> userData) async {
    final displayName =
        userData['displayName'] ?? userData['name'] ?? 'Unknown User';
    final email = userData['email'] ?? '';
    final company = userData['company'];
    final title = userData['title'];
    final phone = userData['phone'];

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Email: $email'),
              ],
              if (company != null && company.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Company: $company'),
              ],
              if (title != null && title.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Title: $title'),
              ],
              if (phone != null && phone.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text('Phone: $phone'),
              ],
              const SizedBox(height: 16),
              const Text(
                'Would you like to add this person to your contacts?',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _addContact(userData);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MyApp.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add Contact'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addContact(Map<String, dynamic> userData) async {
    try {
      // Create contact from user data
      final contact = Contact(
        id: '', // Will be generated by Firestore
        ownerId: widget.user.id,
        owner: widget.user,
        name: userData['displayName'] ?? userData['name'] ?? 'Unknown User',
        displayName:
            userData['displayName'] ?? userData['name'] ?? 'Unknown User',
        email: userData['email'] ?? '',
        phone: userData['phone'],
        company: userData['company'],
        website: userData['website'],
        position: userData['title'],
        notes: 'Added via QR code scan',
        instagram: userData['social']?['instagram'],
        facebook: userData['social']?['facebook'],
        youtube: userData['social']?['youtube'],
        linkedin: userData['social']?['linkedin'],
        pinterest: userData['social']?['pinterest'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Add contact using service
      await widget.serviceManager.contactService.createContact(contact);

      context.showSuccessSnackBar('Contact added successfully!');

      // Navigate back to contact library
      Navigator.of(context).pushReplacementNamed(AppRoutes.contactLibrary);
    } catch (e) {
      context.showErrorSnackBar('Failed to add contact: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

// Custom painter for scanner overlay
class ScannerOverlay extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: 250,
      height: 250,
    );

    // Draw the background
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()
          ..addRRect(
              RRect.fromRectAndRadius(scanArea, const Radius.circular(12))),
      ),
      paint,
    );

    // Draw the border
    final borderPaint = Paint()
      ..color = MyApp.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawRRect(
      RRect.fromRectAndRadius(scanArea, const Radius.circular(12)),
      borderPaint,
    );

    // Draw corner indicators
    final cornerLength = 30.0;
    final cornerThickness = 3.0;
    final cornerPaint = Paint()
      ..color = MyApp.primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerThickness;

    // Top-left corner
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top + cornerLength),
      Offset(scanArea.left, scanArea.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top),
      Offset(scanArea.left + cornerLength, scanArea.top),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.top),
      Offset(scanArea.right, scanArea.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.top),
      Offset(scanArea.right, scanArea.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom - cornerLength),
      Offset(scanArea.left, scanArea.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom),
      Offset(scanArea.left + cornerLength, scanArea.bottom),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.bottom),
      Offset(scanArea.right, scanArea.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.bottom - cornerLength),
      Offset(scanArea.right, scanArea.bottom),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
