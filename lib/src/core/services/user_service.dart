import '../models/user.dart';
import '../providers/firebase_provider.dart';

/// UserService
/// Mission: Handle user profile data, user roles, settings, and CRUD operations.
/// Responsibilities:
/// - Create/update user profile in Firestore (after auth)
/// - Get user data (by ID or current)
/// - Manage user roles, preferences, profile picture, etc.
/// - May integrate with AuthService to fetch uid
class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._internal();

  UserService._internal();

  FirebaseProvider? _firebaseProvider;
  static const String _collection = 'users';

  /// Initialize the service with FirebaseProvider
  Future<void> initialize(FirebaseProvider firebaseProvider) async {
    _firebaseProvider = firebaseProvider;
  }

  /// Create a new user
  Future<String> createUser(User user) async {
    try {
      final docRef = await _firebaseProvider!.createDocument(
        _collection,
        user.toJson(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Create a user with custom ID (useful for auth users)
  Future<void> createUserWithId(String userId, User user) async {
    try {
      await _firebaseProvider!.updateDocument(
        _collection,
        userId,
        user.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to create user with ID: $e');
    }
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      final doc = await _firebaseProvider!.getDocument(_collection, userId);

      if (doc != null && doc.exists) {
        final userData = doc.data() as Map<String, dynamic>;
        return User.fromJson({
          'id': doc.id,
          ...userData,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firebaseProvider!.getDocuments(
        _collection,
        filters: [MapEntry('email', email)],
        limit: 1,
      );

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return User.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by email: $e');
    }
  }

  /// Update user
  Future<void> updateUser(String userId, User user) async {
    try {
      await _firebaseProvider!.updateDocument(
        _collection,
        userId,
        user.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firebaseProvider!.deleteDocument(_collection, userId);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Get all users with optional filters
  Future<List<User>> getUsers({
    List<MapEntry<String, dynamic>>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      final querySnapshot = await _firebaseProvider!.getDocuments(
        _collection,
        filters: filters,
        orderBy: orderBy,
        descending: descending,
        limit: limit,
      );

      return querySnapshot.docs.map((doc) {
        return User.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  /// Get chamber members
  Future<List<User>> getChamberMembers() async {
    try {
      return await getUsers(
        filters: [MapEntry('chamberMember', true)],
        orderBy: 'name',
      );
    } catch (e) {
      throw Exception('Failed to get chamber members: $e');
    }
  }

  /// Get users by company
  Future<List<User>> getUsersByCompany(String company) async {
    try {
      return await getUsers(
        filters: [MapEntry('company', company)],
        orderBy: 'name',
      );
    } catch (e) {
      throw Exception('Failed to get users by company: $e');
    }
  }

  /// Stream user updates in real-time
  Stream<User?> streamUser(String userId) {
    try {
      return _firebaseProvider!
          .listenToDocument(_collection, userId)
          .map((doc) {
        if (doc.exists) {
          return User.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
        }
        return null;
      });
    } catch (e) {
      throw Exception('Failed to stream user: $e');
    }
  }

  /// Stream all users with real-time updates
  Stream<List<User>> streamUsers({
    List<MapEntry<String, dynamic>>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    try {
      return _firebaseProvider!
          .listenToCollection(
        _collection,
        filters: filters,
        orderBy: orderBy,
        descending: descending,
      )
          .map((querySnapshot) {
        return querySnapshot.docs.map((doc) {
          return User.fromJson({
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          });
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to stream users: $e');
    }
  }

  /// Search users by name or email
  Future<List<User>> searchUsers(String searchTerm) async {
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a simple prefix search on name field
      // For better search, consider using Algolia or similar service
      final allUsers = await getUsers(orderBy: 'name');

      return allUsers.where((user) {
        final name = user.name.toLowerCase();
        final email = user.email.toLowerCase();
        final search = searchTerm.toLowerCase();

        return name.contains(search) || email.contains(search);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  /// Update user status
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await _firebaseProvider!.updateDocument(
        _collection,
        userId,
        {
          'status': status,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to update user status: $e');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(
      String userId, Map<String, dynamic> profileData) async {
    try {
      await _firebaseProvider!.updateDocument(
        _collection,
        userId,
        {
          ...profileData,
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  /// Get current user from Firebase Auth
  String? getCurrentUserId() {
    final firebaseUser = _firebaseProvider!.getCurrentFirebaseUser();
    return firebaseUser?.uid;
  }

  /// Get current user profile
  Future<User?> getCurrentUser() async {
    final userId = getCurrentUserId();
    if (userId == null) return null;
    return await getUserById(userId);
  }
}
