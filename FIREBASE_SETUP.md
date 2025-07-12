# Firebase Setup Guide

This guide will help you set up Firebase for the GBCC Connect app and resolve the "No Firebase App '[DEFAULT]' has been created" error.

## Prerequisites

1. A Firebase project (create one at [Firebase Console](https://console.firebase.google.com/))
2. Flutter development environment set up

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Create a project" or select an existing project
3. Follow the setup wizard to create your project

## Step 2: Add Firebase to Your App

### For Android:

1. In Firebase Console, go to Project Settings > General
2. Scroll down to "Your apps" section
3. Click the Android icon to add an Android app
4. Enter your Android package name (found in `android/app/build.gradle`)
5. Download the `google-services.json` file
6. Place `google-services.json` in the `android/app/` directory

### For iOS:

1. In Firebase Console, go to Project Settings > General
2. Scroll down to "Your apps" section
3. Click the iOS icon to add an iOS app
4. Enter your iOS bundle ID (found in `ios/Runner/Info.plist`)
5. Download the `GoogleService-Info.plist` file
6. Place `GoogleService-Info.plist` in the `ios/Runner/` directory

## Step 3: Create Environment File

Create a `.env` file in the root directory of your project with the following content:

```env
# Firebase Configuration
# Replace these values with your actual Firebase project configuration
# You can find these values in your Firebase Console > Project Settings > General > Your apps

FIREBASE_API_KEY=your_api_key_here
FIREBASE_APP_ID=your_app_id_here
FIREBASE_MESSAGING_SENDER_ID=your_messaging_sender_id_here
FIREBASE_PROJECT_ID=your_project_id_here
FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com
FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
FIREBASE_MEASUREMENT_ID=your_measurement_id_here

# Firebase Services Configuration
ENABLE_ANALYTICS=true
ENABLE_CRASHLYTICS=true
ENABLE_PERFORMANCE=true

# Environment
ENVIRONMENT=development
```

### How to Find These Values:

1. **FIREBASE_API_KEY**: Found in `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
2. **FIREBASE_APP_ID**: Found in Firebase Console > Project Settings > General > Your apps
3. **FIREBASE_MESSAGING_SENDER_ID**: Found in Firebase Console > Project Settings > Cloud Messaging
4. **FIREBASE_PROJECT_ID**: Your Firebase project ID (visible in the URL when you're in Firebase Console)
5. **FIREBASE_STORAGE_BUCKET**: Usually `your_project_id.appspot.com`
6. **FIREBASE_AUTH_DOMAIN**: Usually `your_project_id.firebaseapp.com`
7. **FIREBASE_MEASUREMENT_ID**: Found in Firebase Console > Project Settings > General > Your apps

## Step 4: Enable Firebase Services

In Firebase Console, enable the services you want to use:

1. **Authentication**: Go to Authentication > Sign-in method and enable desired providers
2. **Firestore**: Go to Firestore Database and create a database
3. **Storage**: Go to Storage and set up storage rules
4. **Analytics**: Automatically enabled when you add the app
5. **Crashlytics**: Go to Crashlytics and enable it
6. **Performance**: Go to Performance and enable it

## Step 5: Update Android Configuration

Make sure your `android/app/build.gradle` has the Google Services plugin:

```gradle
// Add this at the bottom of the file
apply plugin: 'com.google.gms.google-services'
```

And in `android/build.gradle`, add the Google Services classpath:

```gradle
buildscript {
    dependencies {
        // Add this line
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

## Step 6: Test the Setup

1. Run `flutter clean`
2. Run `flutter pub get`
3. Run your app: `flutter run`

## Troubleshooting

### "No Firebase App '[DEFAULT]' has been created" Error

This error occurs when:

1. Firebase configuration files are missing
2. Environment variables are not set correctly
3. Firebase is not initialized before being used

**Solutions:**

1. Ensure `google-services.json` is in `android/app/`
2. Ensure `GoogleService-Info.plist` is in `ios/Runner/`
3. Create and populate the `.env` file with correct values
4. Make sure Firebase is initialized in `main.dart` (already done)

### Missing Environment Variables

If you see errors about missing environment variables:

1. Check that your `.env` file exists in the root directory
2. Verify all required variables are set
3. Make sure there are no extra spaces or quotes around values

### Platform-Specific Issues

**Android:**

- Ensure `google-services.json` is in the correct location
- Check that the package name in `google-services.json` matches your app's package name

**iOS:**

- Ensure `GoogleService-Info.plist` is in the correct location
- Check that the bundle ID in `GoogleService-Info.plist` matches your app's bundle ID

## Security Notes

1. Never commit your `.env` file to version control
2. Keep your Firebase configuration files secure
3. Use different Firebase projects for development and production
4. Set up proper security rules in Firestore and Storage

## Next Steps

After setting up Firebase:

1. Configure authentication methods in Firebase Console
2. Set up Firestore security rules
3. Configure Storage security rules
4. Test all Firebase services in your app
