# Firestore Index Setup Guide

## 🚨 Current Issue

Your app is failing to load contacts due to missing Firestore indexes. The error message indicates:

```
failed to load contacts: exception: firestore index is missing
```

## 🛠️ Solution Options

### Option 1: Use Firebase CLI (Recommended)

1. **Install Firebase CLI** (if not already installed):

   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:

   ```bash
   firebase login
   ```

3. **Deploy indexes using the script**:
   ```bash
   ./deploy_indexes.sh
   ```

### Option 2: Manual Creation via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `networking-app-bfabb`
3. Navigate to **Firestore Database** → **Indexes** tab
4. Create the following indexes:

#### Contacts Collection Index

- **Collection**: `contacts`
- **Fields**:
  - `ownerId` (Ascending)
  - `name` (Ascending)
  - `__name__` (Ascending)

#### Conversations Collection Index

- **Collection**: `conversations`
- **Fields**:
  - `ownerId` (Ascending)
  - `updatedAt` (Descending)
  - `__name__` (Descending)

#### Users Collection Indexes

- **Collection**: `users`
- **Fields**:

  - `chamberMember` (Ascending)
  - `name` (Ascending)
  - `__name__` (Ascending)

- **Collection**: `users`
- **Fields**:
  - `company` (Ascending)
  - `name` (Ascending)
  - `__name__` (Ascending)

### Option 3: Use Direct Links

For the contacts index, you can use this direct link:
https://console.firebase.google.com/v1/r/project/networking-app-bfabb/firestore/indexes?create_composite=ClVwcm9qZWN0cy9uZXR3b3JraW5nLWFwcC1iZmFiYi9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvY29udGFjdHMvaW5kZXhlcy9fEAEaCwoHb3duZXJJZBABGggKBG5hbWUQARoMCghfX25hbWVfXxAB

## ⏱️ Timeline

- **Index Creation**: 1-2 minutes
- **Index Building**: 5-10 minutes
- **Total Time**: ~10-15 minutes

## ✅ Verification

After creating the indexes:

1. **Wait 5-10 minutes** for indexes to build
2. **Test the app**:

   - Navigate to Contact Library page
   - Verify contacts load without errors
   - Test search functionality
   - Check conversation loading

3. **Monitor in Firebase Console**:
   - Go to Firestore → Indexes
   - Ensure all indexes show "Enabled" status

## 🔧 Troubleshooting

If you still see errors:

1. **Check index status** in Firebase Console
2. **Verify field names** match exactly (case-sensitive)
3. **Ensure collection names** are correct
4. **Wait longer** for indexes to fully build
5. **Restart the app** after index creation

## 📞 Support

If issues persist:

1. Check the detailed `firestore_indexes.md` file
2. Review Firebase Console for any error messages
3. Verify your Firebase project configuration

---

**Note**: The app will work normally once indexes are created and built. This is a one-time setup requirement.
