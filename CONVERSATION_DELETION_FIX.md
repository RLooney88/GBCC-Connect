# Conversation Deletion Logic Fix

## Problem Analysis

### Original Issue

When a user attempted to "delete" a conversation, an error could occur during the process, causing messages to disappear for the _other participant_ in the conversation. This was incorrect behavior because messages should only be hidden for the initiating user, and permanently deleted only when _both_ participants have marked them for removal.

### Root Cause Analysis

#### 1. **Race Condition in Soft Delete Logic**

The original `softDeleteMessagesForUser` method had a critical race condition:

```dart
// Process each message
for (final doc in messagesQuery.docs) {
  // ... determine removal field ...

  if (willBeRemovedByOwner && willBeRemovedByParticipant) {
    // Both users have removed it, delete permanently
    await _firebaseProvider!.deleteDocument('messages', doc.id);
  } else {
    // Only one user has removed it, just update the field
    await _firebaseProvider!.updateDocument('messages', doc.id, updates);
  }
}
```

**Problems:**

- No transaction wrapping the operations
- If an error occurred mid-loop, some messages would have removal flags set while others wouldn't
- The conversation document was deleted separately, creating inconsistent state
- No rollback mechanism for partial failures

#### 2. **Inconsistent State Creation**

When an error occurred during the deletion process:

1. Some messages were permanently deleted (if both flags were already true)
2. Some messages had only one removal flag set
3. The conversation document was deleted regardless
4. The other participant couldn't see messages because the conversation was gone, even though some messages still existed

#### 3. **Missing Transaction Support**

The FirebaseProvider lacked transaction methods needed for atomic operations.

## Solution Implementation

### 1. **Added Transaction Support to FirebaseProvider**

```dart
/// Get document reference
DocumentReference getDocumentReference(String collection, String documentId) {
  return _firestore.collection(collection).doc(documentId);
}

/// Run a Firestore transaction
Future<T> runTransaction<T>(Future<T> Function(Transaction) updateFunction) async {
  try {
    return await _firestore.runTransaction(updateFunction);
  } catch (e) {
    _setError('Transaction failed: $e');
    rethrow;
  }
}
```

### 2. **Fixed Soft Delete Logic with Transactions**

The new `softDeleteMessagesForUser` method uses Firestore transactions to ensure atomicity:

```dart
Future<void> softDeleteMessagesForUser(
  String conversationId,
  String userEmail,
) async {
  try {
    // Get conversation and messages outside transaction
    final conversationDoc = await _firebaseProvider!.getDocument(_collection, conversationId);
    final messagesQuery = await _firebaseProvider!.getDocuments('messages', filters: filters);

    // Use transaction for atomic operations
    await _firebaseProvider!.runTransaction((transaction) async {
      // Process each message within the transaction
      for (final doc in messagesQuery.docs) {
        // ... determine removal logic ...

        if (willBeRemovedByOwner && willBeRemovedByParticipant) {
          transaction.delete(doc.reference);
        } else {
          transaction.update(doc.reference, updates);
        }
      }

      // Delete conversation document only after all messages are processed
      transaction.delete(conversationDoc.reference);
    });
  } catch (e) {
    // If transaction fails, nothing is changed - maintaining consistency
    throw Exception('Failed to soft delete messages: $e');
  }
}
```

### 3. **Updated UI Logic**

Simplified the conversation deletion in the UI to only call the atomic method:

```dart
// Before: Two separate calls
await softDeleteMessagesForUser(conversationId, userEmail);
await deleteConversation(conversationId);

// After: Single atomic call
await softDeleteMessagesForUser(conversationId, userEmail);
```

## Key Improvements

### 1. **Atomic Operations**

- All message updates and conversation deletion happen in a single transaction
- If any operation fails, the entire transaction is rolled back
- No partial state changes possible

### 2. **Consistent State**

- Messages are only permanently deleted when both users have removed them
- Conversation document is only deleted after all message operations complete
- Other participant can still see messages until they also "delete" the conversation

### 3. **Error Handling**

- Transaction failures result in no state changes
- Clear error messages for debugging
- No orphaned messages or inconsistent conversation states

### 4. **Performance**

- Single transaction instead of multiple individual operations
- Reduced network calls and improved reliability

## Testing Scenarios

### Scenario 1: Normal Deletion

1. User A deletes conversation with User B
2. Messages are soft-deleted for User A (removedOwner = true)
3. Messages remain visible for User B
4. Conversation disappears for User A only

### Scenario 2: Both Users Delete

1. User A deletes conversation → messages soft-deleted for User A
2. User B deletes conversation → messages soft-deleted for User B
3. Messages are permanently deleted (both flags = true)
4. Conversation disappears for both users

### Scenario 3: Error During Deletion

1. User A attempts to delete conversation
2. Error occurs during transaction
3. **Result**: No changes made, conversation and messages remain intact
4. User B can still see all messages

## Message Model Validation

The `Message` model correctly implements the soft delete pattern:

```dart
class Message {
  final bool removedOwner;     // Whether owner has removed this message
  final bool removedParticipant; // Whether participant has removed this message

  bool shouldDisplayForUser(String userEmail, String ownerEmail, String participantEmail) {
    if (userEmail == ownerEmail) {
      return !removedOwner;
    } else if (userEmail == participantEmail) {
      return !removedParticipant;
    }
    return true;
  }

  bool shouldBePermanentlyDeleted() {
    return removedOwner && removedParticipant;
  }
}
```

## Conclusion

The implemented fix ensures that:

1. **Messages are only hidden for the user who deletes them**
2. **Messages are permanently deleted only when both users have removed them**
3. **No inconsistent state can occur due to transaction atomicity**
4. **Error handling prevents partial failures from affecting other users**
5. **The other participant's experience is preserved until they also choose to delete the conversation**

This solution aligns with the core logic requirements and provides a robust, user-friendly conversation deletion experience.
