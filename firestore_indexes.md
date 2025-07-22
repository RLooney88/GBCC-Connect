# Firestore Indexes Required

The following composite indexes need to be created in your Firebase Console to resolve the query errors:

## 1. Conversations Collection Indexes

### Conversations by Owner with UpdatedAt Ordering

**Collection**: `conversations`
**Fields**:

- `ownerId` (Ascending)
- `updatedAt` (Descending)
- `__name__` (Descending)

**Purpose**: For querying conversations by owner with ordering by updatedAt

### Conversations by Owner and Participant

**Collection**: `conversations`
**Fields**:

- `ownerId` (Ascending)
- `participantId` (Ascending)
- `__name__` (Ascending)

**Purpose**: For finding specific conversations between two users

### Conversations by Participant with UpdatedAt Ordering

**Collection**: `conversations`
**Fields**:

- `participantId` (Ascending)
- `updatedAt` (Descending)
- `__name__` (Descending)

**Purpose**: For querying conversations where user is participant

### Conversations by Active Status

**Collection**: `conversations`
**Fields**:

- `isActive` (Ascending)
- `updatedAt` (Descending)
- `__name__` (Descending)

**Purpose**: For filtering active/archived conversations

## 2. Messages Collection Indexes

### Messages by Conversation with Timestamp Ordering

**Collection**: `messages`
**Fields**:

- `conversationId` (Ascending)
- `timestamp` (Descending)
- `__name__` (Descending)

**Purpose**: For retrieving messages in a conversation ordered by time

### Messages by Conversation and Status

**Collection**: `messages`
**Fields**:

- `conversationId` (Ascending)
- `status` (Ascending)
- `timestamp` (Descending)

**Purpose**: For filtering messages by status within a conversation

### Messages by Sender

**Collection**: `messages`
**Fields**:

- `from` (Ascending)
- `timestamp` (Descending)
- `__name__` (Descending)

**Purpose**: For querying messages sent by a specific user

### Messages by Recipient

**Collection**: `messages`
**Fields**:

- `to` (Ascending)
- `timestamp` (Descending)
- `__name__` (Descending)

**Purpose**: For querying messages received by a specific user

### Messages by Conversation, Recipient, and Status

**Collection**: `messages`
**Fields**:

- `conversationId` (Ascending)
- `to` (Ascending)
- `status` (Ascending)

**Purpose**: For marking messages as read (filtering by recipient and status)

### Messages by Type

**Collection**: `messages`
**Fields**:

- `messageType` (Ascending)
- `timestamp` (Descending)
- `__name__` (Descending)

**Purpose**: For filtering messages by type (text, image, file)

## 3. Contacts Collection Index

**Collection**: `contacts`
**Fields**:

- `ownerId` (Ascending)
- `name` (Ascending)
- `__name__` (Ascending)

**Purpose**: For querying contacts by owner with ordering by name

## 4. Users Collection Indexes

### Chamber Members

**Collection**: `users`
**Fields**:

- `chamberMember` (Ascending)
- `name` (Ascending)
- `__name__` (Ascending)

**Purpose**: For querying chamber members with ordering by name

### By Company

**Collection**: `users`
**Fields**:

- `company` (Ascending)
- `name` (Ascending)
- `__name__` (Ascending)

**Purpose**: For querying users by company with ordering by name

## How to Create Indexes

### Option 1: Use Firebase CLI (Recommended)

```bash
# Install Firebase CLI if not already installed
npm install -g firebase-tools

# Login to Firebase
firebase login

# Deploy indexes using the script
./deploy_indexes.sh
```

### Option 2: Manual Creation via Firebase Console

1. Go to the Firebase Console: https://console.firebase.google.com/
2. Select your project: `networking-app-bfabb`
3. Go to Firestore Database
4. Click on the "Indexes" tab
5. Click "Create Index"
6. Add the fields as specified above
7. Click "Create"

## Expected Result

After creating these indexes, the following errors should be resolved:

- `[cloud_firestore/failed-precondition] The query requires an index` for conversations
- `[cloud_firestore/failed-precondition] The query requires an index` for messages
- `[cloud_firestore/failed-precondition] The query requires an index` for contacts
- `[cloud_firestore/failed-precondition] The query requires an index` for users

## Note

Index creation may take a few minutes to complete. The app will continue to work, but queries may be slower until the indexes are fully built.

## Verification

After creating the indexes, you can verify they are working by:

1. Running the app and navigating to the Contact Library page
2. Checking that contacts load without errors
3. Testing the search functionality
4. Verifying that chamber member queries work
5. Testing conversation loading
6. Testing message sending and receiving
7. Verifying message status updates work correctly

## Troubleshooting

If you still see index errors after creating the indexes:

1. Wait a few minutes for indexes to build
2. Check the Firebase Console Indexes tab to ensure indexes are "Enabled"
3. Verify the field names match exactly (case-sensitive)
4. Ensure the collection names are correct
5. Check that the query in your code matches the index structure

## Query Patterns Supported

These indexes support the following query patterns used in your codebase:

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
