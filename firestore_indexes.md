# Firestore Indexes Required

The following composite indexes need to be created in your Firebase Console to resolve the query errors:

## 1. Conversations Collection Index

**Collection**: `conversations`
**Fields**:

- `ownerId` (Ascending)
- `updatedAt` (Descending)
- `__name__` (Descending)

**Purpose**: For querying conversations by owner with ordering by updatedAt

**Direct Link**: https://console.firebase.google.com/v1/r/project/networking-app-bfabb/firestore/indexes?create_composite=Clpwcm9qZWN0cy9uZXR3b3JraW5nLWFwcC1iZmFiYi9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvY29udmVyc2F0aW9ucy9pbmRleGVzL18QARoLCgdvd25lcklkEAEaDQoJdXBkYXRlZEF0EAIaDAoIX19uYW1lX18QAg

## 2. Contacts Collection Index

**Collection**: `contacts`
**Fields**:

- `ownerId` (Ascending)
- `name` (Ascending)
- `__name__` (Ascending)

**Purpose**: For querying contacts by owner with ordering by name

**Direct Link**: https://console.firebase.google.com/v1/r/project/networking-app-bfabb/firestore/indexes?create_composite=ClVwcm9qZWN0cy9uZXR3b3JraW5nLWFwcC1iZmFiYi9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvY29udGFjdHMvaW5kZXhlcy9fEAEaCwoHb3duZXJJZBABGggKBG5hbWUQARoMCghfX25hbWVfXxAB

## 3. Users Collection Index - Chamber Members

**Collection**: `users`
**Fields**:

- `chamberMember` (Ascending)
- `name` (Ascending)
- `__name__` (Ascending)

**Purpose**: For querying chamber members with ordering by name

## 4. Users Collection Index - By Company

**Collection**: `users`
**Fields**:

- `company` (Ascending)
- `name` (Ascending)
- `__name__` (Ascending)

**Purpose**: For querying users by company with ordering by name

## How to Create Indexes

1. Go to the Firebase Console: https://console.firebase.google.com/
2. Select your project: `networking-app-bfabb`
3. Go to Firestore Database
4. Click on the "Indexes" tab
5. Click "Create Index"
6. Add the fields as specified above
7. Click "Create"

## Alternative: Use Direct Links

You can click the direct links above to create the indexes automatically in the Firebase Console.

## Manual Creation Steps

For indexes without direct links, follow these steps:

### Users Collection Indexes

1. **Chamber Members Index**:

   - Collection: `users`
   - Fields: `chamberMember` (Ascending), `name` (Ascending), `__name__` (Ascending)

2. **Company Index**:
   - Collection: `users`
   - Fields: `company` (Ascending), `name` (Ascending), `__name__` (Ascending)

## Expected Result

After creating these indexes, the following errors should be resolved:

- `[cloud_firestore/failed-precondition] The query requires an index` for conversations
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

## Troubleshooting

If you still see index errors after creating the indexes:

1. Wait a few minutes for indexes to build
2. Check the Firebase Console Indexes tab to ensure indexes are "Enabled"
3. Verify the field names match exactly (case-sensitive)
4. Ensure the collection names are correct
5. Check that the query in your code matches the index structure
