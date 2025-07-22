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

#### Conversations Collection Indexes

**Index 1: Conversations by Owner with UpdatedAt Ordering**

- **Collection**: `conversations`
- **Fields**:
  - `ownerId` (Ascending)
  - `updatedAt` (Descending)
  - `__name__` (Descending)

**Index 2: Conversations by Owner and Participant**

- **Collection**: `conversations`
- **Fields**:
  - `ownerId` (Ascending)
  - `participantId` (Ascending)
  - `__name__` (Ascending)

**Index 3: Conversations by Participant with UpdatedAt Ordering**

- **Collection**: `conversations`
- **Fields**:
  - `participantId` (Ascending)
  - `updatedAt` (Descending)
  - `__name__` (Descending)

**Index 4: Conversations by Active Status**

- **Collection**: `conversations`
- **Fields**:
  - `isActive` (Ascending)
  - `updatedAt` (Descending)
  - `__name__` (Descending)

#### Messages Collection Indexes

**Index 1: Messages by Conversation with Timestamp Ordering**

- **Collection**: `messages`
- **Fields**:
  - `conversationId` (Ascending)
  - `timestamp` (Descending)
  - `__name__` (Descending)

**Index 2: Messages by Conversation and Status**

- **Collection**: `messages`
- **Fields**:
  - `conversationId` (Ascending)
  - `status` (Ascending)
  - `timestamp` (Descending)

**Index 3: Messages by Sender**

- **Collection**: `messages`
- **Fields**:
  - `from` (Ascending)
  - `timestamp` (Descending)
  - `__name__` (Descending)

**Index 4: Messages by Recipient**

- **Collection**: `messages`
- **Fields**:
  - `to` (Ascending)
  - `timestamp` (Descending)
  - `__name__` (Descending)

**Index 5: Messages by Conversation, Recipient, and Status**

- **Collection**: `messages`
- **Fields**:
  - `conversationId` (Ascending)
  - `to` (Ascending)
  - `status` (Ascending)

**Index 6: Messages by Type**

- **Collection**: `messages`
- **Fields**:
  - `messageType` (Ascending)
  - `timestamp` (Descending)
  - `__name__` (Descending)

#### Contacts Collection Index

- **Collection**: `contacts`
- **Fields**:
  - `ownerId` (Ascending)
  - `name` (Ascending)
  - `__name__` (Ascending)

#### Users Collection Indexes

**Index 1: Chamber Members**

- **Collection**: `users`
- **Fields**:
  - `chamberMember` (Ascending)
  - `name` (Ascending)
  - `__name__` (Ascending)

**Index 2: By Company**

- **Collection**: `users`
- **Fields**:
  - `company` (Ascending)
  - `name` (Ascending)
  - `__name__` (Ascending)

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
   - Test message sending and receiving
   - Verify message status updates work correctly

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

## 🎯 Query Patterns Supported

These indexes support all the query patterns used in your MessageService and ConversationService:

### Conversations

- `where('ownerId', isEqualTo: userId).orderBy('updatedAt', descending: true)`
- `where('ownerId', isEqualTo: ownerId).where('participantId', isEqualTo: participantId)`
- `where('participantId', isEqualTo: userId).orderBy('updatedAt', descending: true)`
- `where('isActive', isEqualTo: true).orderBy('updatedAt', descending: true)`

### Messages

- `where('conversationId', isEqualTo: conversationId).orderBy('timestamp', descending: true)`
- `where('conversationId', isEqualTo: conversationId).where('status', isEqualTo: status)`
- `where('from', isEqualTo: userEmail).orderBy('timestamp', descending: true)`
- `where('to', isEqualTo: userEmail).orderBy('timestamp', descending: true)`
- `where('conversationId', isEqualTo: conversationId).where('to', isEqualTo: userEmail).where('status', isEqualTo: 'delivered')`
- `where('messageType', isEqualTo: 'image').orderBy('timestamp', descending: true)`

---

**Note**: The app will work normally once indexes are created and built. This is a one-time setup requirement.
