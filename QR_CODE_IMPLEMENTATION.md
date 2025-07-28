# QR Code Implementation Guide

## Overview

This document outlines the QR code functionality implementation in the GBCC Connect app, including generation, scanning, and data handling.

## Dependencies

### Required Packages

```yaml
dependencies:
  # QR Code Generation and Scanning
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.6
```

## Architecture

### 1. QR Code Service (`lib/src/core/services/qr_code_service.dart`)

The QR code service handles all QR code-related operations:

#### Key Features:

- **QR Code Generation**: Creates QR codes with user profile data
- **Data Encoding/Decoding**: Handles JSON serialization of user data
- **Image Generation**: Converts QR codes to image bytes for sharing
- **Validation**: Validates QR code format and data integrity

#### Data Structure:

```json
{
  "type": "gbcc_connect_profile",
  "version": "1.0",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "user": {
    "id": "user_id",
    "name": "John Doe",
    "displayName": "John",
    "email": "john@example.com",
    "phone": "+1234567890",
    "company": "Company Name",
    "title": "Job Title",
    "website": "https://example.com",
    "address": "Address",
    "social": {
      "linkedin": "linkedin_url",
      "instagram": "instagram_url",
      "facebook": "facebook_url",
      "youtube": "youtube_url",
      "pinterest": "pinterest_url"
    }
  }
}
```

### 2. QR Code Scanner Page (`lib/src/features/qr_code/qr_code_scanner_page.dart`)

#### Features:

- **Real-time Scanning**: Uses `mobile_scanner` for camera-based QR code scanning
- **Custom Overlay**: Visual guide with corner indicators and scan area
- **Data Processing**: Validates and processes scanned QR code data
- **Contact Addition**: Automatically creates contacts from scanned data
- **Error Handling**: Comprehensive error handling and user feedback

#### Key Components:

- `MobileScanner`: Camera view for QR code scanning
- `ScannerOverlay`: Custom painter for visual scan guide
- `QRCodeScannerPage`: Main scanner page with processing logic

#### Scanner Features:

- **Pause/Resume**: Toggle scanning on/off
- **Processing Overlay**: Shows loading state during data processing
- **User Validation**: Prevents scanning own QR code
- **Contact Dialog**: Confirms contact addition with user info

### 3. QR Code Generation Page (`lib/src/features/qr_code/qr_code_page.dart`)

#### Features:

- **QR Code Display**: Shows user's QR code with styling
- **Share Functionality**: Export QR code as image
- **User Info Overlay**: Displays user name on QR code
- **Custom Styling**: Branded appearance with app colors

## Implementation Details

### QR Code Generation

```dart
// Generate QR data
String qrData = qrCodeService.generateQRData(user);

// Create QR widget
Widget qrWidget = qrCodeService.generateQRCodeWidget(user);

// Generate image bytes
Uint8List imageBytes = await qrCodeService.generateQRCodeImage(user);
```

### QR Code Scanning

```dart
// Initialize scanner
MobileScannerController controller = MobileScannerController();

// Handle scan results
MobileScanner(
  controller: controller,
  onDetect: (capture) {
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        _processQRCode(barcode.rawValue!);
        break;
      }
    }
  },
)
```

### Data Processing

```dart
// Parse QR data
Map<String, dynamic>? parsedData = qrCodeService.parseQRData(qrData);

// Extract user data
Map<String, dynamic>? userData = qrCodeService.extractUserDataFromQR(qrData);

// Validate QR code
bool isValid = qrCodeService.isValidUserQRCode(qrData);
```

## UI Components

### Scanner Overlay

The scanner uses a custom overlay with:

- **Semi-transparent background**: Darkens areas outside scan area
- **Border frame**: Highlights the scan area with app colors
- **Corner indicators**: Visual guides at scan area corners
- **Instructions**: User guidance text overlay

### QR Code Styling

Generated QR codes feature:

- **Branded colors**: Uses app primary color
- **Rounded corners**: Modern appearance
- **User info overlay**: Shows name on QR code
- **Shadow effects**: Professional styling

## Error Handling

### Common Issues:

1. **Invalid QR Format**: Non-GBCC Connect QR codes
2. **Missing Data**: Incomplete user information
3. **Own QR Code**: Attempting to scan personal QR code
4. **Network Issues**: Contact creation failures

### Error Messages:

- "Invalid QR code format"
- "Could not extract user data from QR code"
- "This is your own QR code!"
- "Failed to add contact: [error]"

## Security Considerations

### Data Validation:

- **Format Validation**: Ensures QR code follows expected structure
- **Required Fields**: Validates presence of essential user data
- **Type Checking**: Verifies data types and formats
- **Sanitization**: Cleans user input data

### Privacy:

- **User Consent**: Confirms before adding contacts
- **Data Minimization**: Only stores necessary contact information
- **Secure Storage**: Uses Firebase for secure data storage

## Testing

### Manual Testing:

1. **QR Generation**: Generate QR codes for different users
2. **QR Scanning**: Scan various QR code formats
3. **Contact Creation**: Verify contact addition process
4. **Error Scenarios**: Test invalid QR codes and edge cases

### Automated Testing:

- Unit tests for QR code service methods
- Widget tests for scanner and generator pages
- Integration tests for complete QR code workflow

## Future Enhancements

### Planned Features:

1. **Batch Scanning**: Scan multiple QR codes at once
2. **QR Code History**: Track previously scanned codes
3. **Custom QR Styles**: User-selectable QR code appearances
4. **Offline Support**: Cache QR codes for offline access
5. **Analytics**: Track QR code usage and success rates

### Technical Improvements:

1. **Performance Optimization**: Faster QR code generation
2. **Better Error Handling**: More specific error messages
3. **Accessibility**: Screen reader support for scanner
4. **Internationalization**: Multi-language support

## Troubleshooting

### Build Issues:

- **Namespace Errors**: Ensure `mobile_scanner` plugin is properly configured
- **Camera Permissions**: Verify camera access permissions
- **Platform Issues**: Test on both Android and iOS

### Runtime Issues:

- **Scanner Not Working**: Check camera permissions and device compatibility
- **QR Code Not Scanning**: Verify QR code format and quality
- **Contact Not Adding**: Check Firebase connectivity and permissions

## Dependencies Migration

### From qr_code_scanner to mobile_scanner:

- **Better Android Compatibility**: Resolves namespace issues
- **Improved Performance**: More efficient scanning
- **Active Maintenance**: Regularly updated plugin
- **Better Error Handling**: More robust error management

### Migration Steps:

1. Update `pubspec.yaml` dependencies
2. Replace import statements
3. Update scanner implementation
4. Test functionality on both platforms
