# Firebase Services Documentation

This directory contains Firebase services that connect your models to Firebase Firestore. The services provide a clean, type-safe interface for all Firebase operations.

## Overview

The Firebase services are organized as follows:

- **ServiceManager**: Central manager that initializes and provides access to all services
- **UserService**: Handles user-related operations
- **ContactService**: Handles contact-related operations
- **MessageService**: Handles messaging operations
- **FirebaseProvider**: State management provider for UI integration

## Quick Start

### 1. Initialize Services

```dart
// In your main.dart or app initialization
final serviceManager = ServiceManager.instance;
await serviceManager.initialize();
```

### 2. Use with Provider (Recommended)

```dart
// In your main.dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => FirebaseProvider()),
    // ... other providers
  ],
  child: MyApp(),
)

// In your widget
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<FirebaseProvider>(
      builder: (context, firebaseProvider, child) {
        // Access Firebase services through the provider
        return Text('User: ${firebaseProvider.currentUser?.name ?? "Not logged in"}');
      },
    );
  }
}
```

### 3. Direct Service Usage

```dart
// Get service instances
final userService = UserService.instance;
final contactService = ContactService.instance;
final messageService = MessageService.instance;

// Use services directly
final user = await userService.getUserById('user-id');
final contacts = await contactService.getContactsByOwner('owner-id');
```

## Services Overview

### UserService

Handles all user-related operations:

```dart
// Create a user
final user = User(
  id: '',
  name: 'John Doe',
  email: 'john@example.com',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
final userId = await userService.createUser(user);

// Get user by ID
final user = await userService.getUserById('user-id');

// Get user by email
final user = await userService.getUserByEmail('john@example.com');

// Update user
await userService.updateUser('user-id', updatedUser);

// Search users
final results = await userService.searchUsers('john');

// Stream users in real-time
userService.streamUsers().listen((users) {
  print('Users updated: ${users.length}');
});
```

### ContactService

Handles contact management:

```dart
// Create a contact
final contact = Contact(
  id: '',
  ownerId: 'current-user-id',
  owner: currentUser,
  name: 'Jane Smith',
  email: 'jane@example.com',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
final contactId = await contactService.createContact(contact);

// Get contacts by owner
final contacts = await contactService.getContactsByOwner('owner-id');

// Get favorite contacts
final favorites = await contactService.getFavoriteContacts('owner-id');

// Toggle favorite status
await contactService.toggleFavorite('contact-id', true);

// Search contacts
final results = await contactService.searchContacts('owner-id', 'jane');

// Stream contacts in real-time
contactService.streamContactsByOwner('owner-id').listen((contacts) {
  print('Contacts updated: ${contacts.length}');
});
```

### MessageService

Handles messaging functionality:

```dart
// Send a message
final message = Message(
  id: '',
  senderId: 'sender-id',
  receiverId: 'receiver-id',
  content: 'Hello!',
  timestamp: DateTime.now(),
);
final messageId = await messageService.createMessage(message);

// Get conversation between two users
final conversation = await messageService.getConversation('user1-id', 'user2-id');

// Get recent conversations
final conversations = await messageService.getRecentConversations('user-id');

// Mark messages as read
await messageService.markMessagesAsRead('receiver-id', 'sender-id');

// Stream conversation in real-time
messageService.streamConversation('user1-id', 'user2-id').listen((messages) {
  print('New messages: ${messages.length}');
});
```

## Error Handling

All services include comprehensive error handling:

```dart
try {
  final user = await userService.getUserById('user-id');
  // Handle success
} catch (e) {
  // Handle error
  print('Error: $e');
}
```

## Real-time Updates

Services provide real-time updates using Firestore streams:

```dart
// Listen to user updates
userService.streamUser('user-id').listen((user) {
  if (user != null) {
    print('User updated: ${user.name}');
  }
});

// Listen to contacts updates
contactService.streamContactsByOwner('owner-id').listen((contacts) {
  print('Contacts updated: ${contacts.length}');
});

// Listen to conversation updates
messageService.streamConversation('user1-id', 'user2-id').listen((messages) {
  print('New messages: ${messages.length}');
});
```

## Offline Support

Firestore services include offline persistence:

```dart
// Enable offline persistence (done automatically in ServiceManager)
await firestoreService.enableOfflinePersistence();

// Clear offline cache
await firestoreService.clearOfflineCache();
```

## Batch Operations

For multiple operations, use batch writes:

```dart
final batch = [
  BatchOperation.create(
    collection: 'users',
    documentId: 'user1',
    data: user1Data,
  ),
  BatchOperation.update(
    collection: 'users',
    documentId: 'user2',
    data: user2Data,
  ),
  BatchOperation.delete(
    collection: 'users',
    documentId: 'user3',
  ),
];

await firestoreService.batchWrite(batch);
```

## Transactions

For atomic operations:

```dart
await firestoreService.runTransaction((transaction) async {
  // Perform transaction operations
  return result;
});
```

## Health Monitoring

Monitor service health:

```dart
// Check service health
final healthStatus = await serviceManager.getHealthStatus();
print('Services healthy: ${healthStatus.values.every((status) => status)}');

// Get service statistics
final stats = await serviceManager.getServiceStats();
print('Service stats: $stats');

// Perform health check
final isHealthy = await serviceManager.performHealthCheck();
```

## Best Practices

1. **Always use the ServiceManager** for initialization
2. **Use the FirebaseProvider** for UI state management
3. **Handle errors gracefully** with try-catch blocks
4. **Use streams for real-time updates** when possible
5. **Implement proper loading states** in your UI
6. **Cache data appropriately** using offline persistence
7. **Monitor service health** in production

## Example Usage

See `lib/src/features/sample_feature/widgets/firebase_example_widget.dart` for a complete example of how to use these services in a Flutter widget.

## Configuration

Make sure your Firebase configuration is properly set up in the `env` file and that all required Firebase dependencies are included in your `pubspec.yaml`.

The services will automatically use the Firebase configuration from your environment variables.
