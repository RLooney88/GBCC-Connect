import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/services/ocr_service.dart';
import '../../core/services/enhanced_ocr_service.dart';
import '../../app.dart';

class BusinessCardScannerPage extends StatefulWidget {
  final Function(BusinessCardData) onDataExtracted;

  const BusinessCardScannerPage({
    super.key,
    required this.onDataExtracted,
  });

  static const routeName = '/business-card-scanner';

  @override
  State<BusinessCardScannerPage> createState() =>
      _BusinessCardScannerPageState();
}

class _BusinessCardScannerPageState extends State<BusinessCardScannerPage> {
  final ImagePicker _picker = ImagePicker();
  final EnhancedOCRService _ocrService = EnhancedOCRService.instance;

  File? _selectedImage;
  BusinessCardData? _extractedData;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkMLKitAvailability();
  }

  /// Check if ML Kit text recognition is available
  Future<void> _checkMLKitAvailability() async {
    try {
      final isAvailable = await _ocrService.isTextRecognitionAvailable();
      if (!isAvailable) {
        setState(() {
          _error =
              'Text recognition is not available on this device. Please ensure you have the latest version of the app.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize text recognition: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Business Card'),
        backgroundColor: MyApp.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Instructions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: MyApp.primaryColor),
                      const SizedBox(width: 8),
                      const Text(
                        'How to scan a business card:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Place the business card on a flat surface\n'
                    '2. Ensure good lighting\n'
                    '3. Take a clear photo of the entire card\n'
                    '4. The app will extract contact information automatically',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Image preview or placeholder
          Expanded(
            child: _buildImageSection(),
          ),

          const SizedBox(height: 16),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    if (_isProcessing) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Processing image...'),
          ],
        ),
      );
    }

    if (_selectedImage != null) {
      return Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          if (_extractedData != null) ...[
            const SizedBox(height: 16),
            _buildExtractedDataPreview(),
          ],
        ],
      );
    }

    return Container(
      decoration: BoxDecoration(
        border:
            Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No image selected',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Tap the camera button to take a photo',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtractedDataPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                const Text(
                  'Extracted Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_extractedData!.name.isNotEmpty)
              _buildDataRow('Name', _extractedData!.name),
            if (_extractedData!.email.isNotEmpty)
              _buildDataRow('Email', _extractedData!.email),
            if (_extractedData!.phone.isNotEmpty)
              _buildDataRow('Phone', _extractedData!.phone),
            if (_extractedData!.company.isNotEmpty)
              _buildDataRow('Company', _extractedData!.company),
            if (_extractedData!.position.isNotEmpty)
              _buildDataRow('Position', _extractedData!.position),
            if (_extractedData!.website.isNotEmpty)
              _buildDataRow('Website', _extractedData!.website),
            if (_extractedData!.socialMedia.isNotEmpty)
              _buildDataRow(
                  'Social Media', _extractedData!.socialMedia.join(', ')),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              border: Border.all(color: Colors.red.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MyApp.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _showManualInputDialog,
            icon: const Icon(Icons.edit),
            label: const Text('Enter Manually'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (_extractedData != null && _extractedData!.hasData) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                widget.onDataExtracted(_extractedData!);
                Navigator.pop(context);
              },
              icon: const Icon(Icons.check),
              label: const Text('Use This Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _setError('Failed to take photo: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _setError('Failed to pick image from gallery: $e');
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _selectedImage = imageFile;
      _isProcessing = true;
      _error = null;
      _extractedData = null;
    });

    try {
      // Extract text from image using enhanced OCR
      debugPrint('Starting OCR text extraction...');
      final extractedText = await _ocrService.extractTextFromImage(imageFile);
      debugPrint(
          'OCR extraction completed. Text length: ${extractedText.length}');
      debugPrint('Extracted text: "$extractedText"');

      if (extractedText.isEmpty) {
        throw Exception(
            'No text was found in the image. Please try with a clearer photo.');
      }

      // Parse the extracted text with AI-enhanced parsing
      debugPrint('Starting text parsing...');
      final parsedData =
          await _ocrService.parseBusinessCardTextWithAI(extractedText);
      debugPrint('Text parsing completed');

      setState(() {
        _extractedData = parsedData;
        _isProcessing = false;
      });

      if (!parsedData.hasData) {
        _setError(
            'No contact information could be extracted from the image. Please try again with a clearer photo.\n\nExtracted text: $extractedText');
      } else {
        debugPrint('Successfully extracted contact data: ${parsedData.name}');
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
      _setError('Failed to process image: $e');
    }
  }

  void _setError(String error) {
    setState(() {
      _error = error;
      _isProcessing = false;
    });
  }

  void _showManualInputDialog() {
    final nameController =
        TextEditingController(text: _extractedData?.name ?? '');
    final emailController =
        TextEditingController(text: _extractedData?.email ?? '');
    final phoneController =
        TextEditingController(text: _extractedData?.phone ?? '');
    final companyController =
        TextEditingController(text: _extractedData?.company ?? '');
    final positionController =
        TextEditingController(text: _extractedData?.position ?? '');
    final websiteController =
        TextEditingController(text: _extractedData?.website ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Business Card Information'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: companyController,
                  decoration: const InputDecoration(labelText: 'Company'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: positionController,
                  decoration: const InputDecoration(labelText: 'Position'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: websiteController,
                  decoration: const InputDecoration(labelText: 'Website'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Use This Data'),
              onPressed: () {
                final manualData = BusinessCardData(
                  name: nameController.text,
                  email: emailController.text,
                  phone: phoneController.text,
                  company: companyController.text,
                  position: positionController.text,
                  website: websiteController.text,
                  address: '',
                  socialMedia: [],
                  rawText: 'Manually entered data',
                );
                widget.onDataExtracted(manualData);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
