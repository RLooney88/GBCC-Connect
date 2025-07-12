# Firebase Testing Checklist

## 🔥 Firebase Core & Configuration

- [ ] Firebase initialization completes without errors
- [ ] Environment variables are properly loaded
- [ ] Firebase options are correctly configured
- [ ] No "No Firebase App '[DEFAULT]' has been created" errors

## 🔐 Authentication

- [ ] Email/password authentication works
- [ ] Google Sign-In integration functions properly
- [ ] Apple Sign-In works on iOS devices
- [ ] User state management (login/logout) works correctly
- [ ] Authentication state persistence across app restarts
- [ ] Error handling for authentication failures

## 📊 Analytics

- [ ] Custom events are logged successfully
- [ ] User properties are set correctly
- [ ] Screen tracking works
- [ ] Events appear in Firebase Console
- [ ] No analytics errors in debug console

## 💥 Crashlytics

- [ ] Test crashes are reported to Firebase Console
- [ ] Custom error logging works
- [ ] User identifiers are set correctly
- [ ] Crash reports include stack traces
- [ ] Non-fatal errors are logged

## 📱 Cloud Messaging (Push Notifications)

- [ ] FCM token is generated successfully
- [ ] Push notifications are received on Android
- [ ] Push notifications are received on iOS
- [ ] Notification handling works when app is in foreground
- [ ] Notification handling works when app is in background
- [ ] Notification handling works when app is terminated

## 🔥 Firestore Database

- [ ] Read operations work correctly
- [ ] Write operations (create, update, delete) work
- [ ] Real-time listeners function properly
- [ ] Offline persistence works
- [ ] Security rules are properly configured
- [ ] Data synchronization works when coming back online
- [ ] Complex queries work as expected

## 📁 Firebase Storage

- [ ] File uploads work correctly
- [ ] File downloads work correctly
- [ ] Image uploads from image picker work
- [ ] Progress tracking for uploads/downloads
- [ ] Storage security rules are properly configured
- [ ] File deletion works

## ⚙️ Remote Config

- [ ] Default values are loaded correctly
- [ ] Remote config values are fetched successfully
- [ ] Feature flags work as expected
- [ ] A/B testing configuration works
- [ ] Config updates are applied without app restart

## 🚀 Performance Monitoring

- [ ] App startup time is tracked
- [ ] Network requests are monitored
- [ ] Custom traces work correctly
- [ ] Performance data appears in Firebase Console
- [ ] No performance monitoring errors

## 🔧 Firebase Functions

- [ ] Cloud Functions can be called successfully
- [ ] Function responses are handled correctly
- [ ] Error handling for function calls works
- [ ] Authentication context is passed correctly

## 📱 Platform-Specific Testing

### Android

- [ ] Google Services plugin is properly configured
- [ ] `google-services.json` is in the correct location
- [ ] ProGuard rules are configured (if using R8)
- [ ] App signing works with Firebase

### iOS

- [ ] `GoogleService-Info.plist` is in the correct location
- [ ] iOS bundle identifier matches Firebase configuration
- [ ] Apple Sign-In capabilities are enabled
- [ ] Push notification capabilities are configured

## 🧪 Testing Commands

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk --debug

# Test on device
flutter run

# Check for Firebase errors in logs
flutter logs | grep -i firebase

# Test specific platforms
flutter run -d android
flutter run -d ios
```

## 🚨 Common Issues to Watch For

1. **"No Firebase App '[DEFAULT]' has been created"**

   - Check if Firebase.initializeApp() is called before using any Firebase services
   - Verify configuration files are in correct locations

2. **Authentication Errors**

   - Verify OAuth client IDs are configured correctly
   - Check SHA-1 fingerprints for Android
   - Ensure bundle identifiers match

3. **Firestore Permission Denied**

   - Check Firestore security rules
   - Verify user authentication state
   - Test with authenticated and unauthenticated users

4. **Push Notification Issues**

   - Verify FCM token generation
   - Check notification permissions
   - Test on physical devices (not just simulators)

5. **Analytics Not Showing**
   - Check if analytics is enabled in Firebase Console
   - Verify events are being logged in debug mode
   - Check network connectivity

## 📊 Success Criteria

- [ ] All Firebase services initialize without errors
- [ ] No Firebase-related crashes or exceptions
- [ ] All features work on both Android and iOS
- [ ] Performance is acceptable (no significant delays)
- [ ] Data is properly synchronized across devices
- [ ] Error handling works gracefully
- [ ] Offline functionality works as expected

## 🔄 Regular Maintenance

- [ ] Monitor Firebase Console for errors
- [ ] Check for Firebase SDK updates monthly
- [ ] Review and update security rules
- [ ] Monitor usage and costs
- [ ] Test after major Flutter updates
