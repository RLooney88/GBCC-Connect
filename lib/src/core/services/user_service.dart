import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'firestore_service.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._internal();

  UserService._internal();

  final FirestoreService _firestoreService = FirestoreService.instance;
  static const String _collection = 'users';

  /// Create a new user
  Future<String> createUser(User user) async {
    try {
      final docRef = await _firestoreService.createDocument(
        collection: _collection,
        data: user.toJson(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  /// Create a user with custom ID (useful for auth users)
  Future<void> createUserWithId(String userId, User user) async {
    try {
      await _firestoreService.createDocumentWithId(
        collection: _collection,
        documentId: userId,
        data: user.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to create user with ID: $e');
    }
  }

  /// Get user by ID
  Future<User?> getUserById(String userId) async {
    try {
      debugPrint('UserService: Getting user by ID: $userId');
      final doc = await _firestoreService.getDocument(
        collection: _collection,
        documentId: userId,
      );

      if (doc != null && doc.exists) {
        debugPrint('UserService: User document found, parsing data...');
        final userData = doc.data() as Map<String, dynamic>;
        debugPrint('UserService: User data: $userData');

        final user = User.fromJson({
          'id': doc.id,
          ...userData,
        });

        debugPrint('UserService: User parsed successfully: ${user.name}');
        return user;
      } else {
        debugPrint('UserService: User document not found or does not exist');
        return null;
      }
    } catch (e) {
      debugPrint('UserService: Error getting user by ID: $e');
      throw Exception('Failed to get user: $e');
    }
  }

  /// Get user by email
  Future<User?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [QueryFilter('email', email)],
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
      debugPrint('UserService: Updating user with ID: $userId');
      debugPrint('UserService: Update data: ${user.toJson()}');

      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: userId,
        data: user.toJson(),
      );

      debugPrint('UserService: User updated successfully in Firestore');
    } catch (e) {
      debugPrint('UserService: Error updating user: $e');
      throw Exception('Failed to update user: $e');
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _firestoreService.deleteDocument(
        collection: _collection,
        documentId: userId,
      );
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  /// Get all users with optional filters
  Future<List<User>> getUsers({
    List<QueryFilter>? filters,
    List<QueryOrder>? orders,
    int? limit,
  }) async {
    try {
      final querySnapshot = await _firestoreService.getDocuments(
        collection: _collection,
        filters: filters,
        orders: orders,
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
        filters: [QueryFilter('chamberMember', true)],
        orders: [QueryOrder('name')],
      );
    } catch (e) {
      throw Exception('Failed to get chamber members: $e');
    }
  }

  /// Get users by company
  Future<List<User>> getUsersByCompany(String company) async {
    try {
      return await getUsers(
        filters: [QueryFilter('company', company)],
        orders: [QueryOrder('name')],
      );
    } catch (e) {
      throw Exception('Failed to get users by company: $e');
    }
  }

  /// Stream user updates in real-time
  Stream<User?> streamUser(String userId) {
    try {
      return _firestoreService
          .streamDocument(
        collection: _collection,
        documentId: userId,
      )
          .map((doc) {
        if (doc != null && doc.exists) {
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
    List<QueryFilter>? filters,
    List<QueryOrder>? orders,
    int? limit,
  }) {
    try {
      return _firestoreService
          .streamDocuments(
        collection: _collection,
        filters: filters,
        orders: orders,
        limit: limit,
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
      final querySnapshot = await _firestoreService.getDocuments(
        collection: _collection,
        orders: [QueryOrder('name')],
      );

      final allUsers = querySnapshot.docs.map((doc) {
        return User.fromJson({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }).toList();

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
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: userId,
        data: {
          'status': status,
          'updatedAt': FieldValue.serverTimestamp(),
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
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: userId,
        data: {
          ...profileData,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
}
