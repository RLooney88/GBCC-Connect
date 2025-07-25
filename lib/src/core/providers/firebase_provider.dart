import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';

/// Data Layer: FirebaseProvider
/// Mission: Talk directly with Firebase (Firestore, Auth, Realtime DB, etc.)
/// - Low-level communication with Firebase
/// - Raw API access: read/write data, query collections, auth, etc.
/// - Should be unaware of Flutter widgets or UI
/// - Should not contain business logic, only CRUD operations
class FirebaseProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // State variables for raw data
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  firebase_auth.FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;
  FirebaseStorage get storage => _storage;

  /// Initialize Firebase services
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint(
          'FirebaseProvider is already initialized, skipping initialization');
      return;
    }

    try {
      debugPrint('FirebaseProvider: Starting initialization...');
      _setLoading(true);
      _clearError();

      // Firebase is initialized by default, just mark as ready
      _isInitialized = true;
      debugPrint('FirebaseProvider: Initialization completed successfully');
    } catch (e) {
      debugPrint('FirebaseProvider: Initialization failed with error: $e');
      _setError('Failed to initialize Firebase: $e');
    } finally {
      _setLoading(false);
    }
  }

  // ========== AUTHENTICATION CRUD OPERATIONS ==========

  /// Get current Firebase user
  firebase_auth.User? getCurrentFirebaseUser() {
    return _auth.currentUser;
  }

  /// Sign in with email and password
  Future<firebase_auth.UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      _setError('Sign in failed: $e');
      rethrow;
    }
  }

  /// Create user with email and password
  Future<firebase_auth.UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
    } catch (e) {
      _setError('User creation failed: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _setError('Sign out failed: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _setError('Password reset failed: $e');
      rethrow;
    }
  }

  // ========== FIRESTORE CRUD OPERATIONS ==========

  /// Create document in collection with automatic server timestamps
  Future<DocumentReference> createDocument(
      String collection, Map<String, dynamic> data) async {
    try {
      // Add server timestamps (will overwrite if already present)
      final documentData = Map<String, dynamic>.from(data);
      documentData.addAll(getCreatedUpdatedTimestampMap());

      return await _firestore.collection(collection).add(documentData);
    } catch (e) {
      _setError('Failed to create document: $e');
      rethrow;
    }
  }

  /// Create document in collection with specific document ID and automatic server timestamps
  Future<DocumentReference> createDocumentWithId(
      String collection, String documentId, Map<String, dynamic> data) async {
    try {
      // Add server timestamps (will overwrite if already present)
      final documentData = Map<String, dynamic>.from(data);
      documentData.addAll(getCreatedUpdatedTimestampMap());

      await _firestore.collection(collection).doc(documentId).set(documentData);
      return _firestore.collection(collection).doc(documentId);
    } catch (e) {
      _setError('Failed to create document with ID: $e');
      rethrow;
    }
  }

  /// Create document without automatic timestamps (for explicit control)
  Future<DocumentReference> createDocumentRaw(
      String collection, Map<String, dynamic> data) async {
    try {
      return await _firestore.collection(collection).add(data);
    } catch (e) {
      _setError('Failed to create document: $e');
      rethrow;
    }
  }

  /// Create document with specific ID without automatic timestamps (for explicit control)
  Future<DocumentReference> createDocumentWithIdRaw(
      String collection, String documentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(documentId).set(data);
      return _firestore.collection(collection).doc(documentId);
    } catch (e) {
      _setError('Failed to create document with ID: $e');
      rethrow;
    }
  }

  /// Get document by ID
  Future<DocumentSnapshot?> getDocument(
      String collection, String documentId) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      return doc.exists ? doc : null;
    } catch (e) {
      _setError('Failed to get document: $e');
      rethrow;
    }
  }

  /// Update document with automatic updatedAt server timestamp
  Future<void> updateDocument(
      String collection, String documentId, Map<String, dynamic> data) async {
    try {
      // Add updatedAt server timestamp (will overwrite if already present)
      final updateData = Map<String, dynamic>.from(data);
      updateData.addAll(getUpdatedTimestampMap());

      await _firestore
          .collection(collection)
          .doc(documentId)
          .update(updateData);
    } catch (e) {
      _setError('Failed to update document: $e');
      rethrow;
    }
  }

  /// Update document without automatic timestamps (for explicit control)
  Future<void> updateDocumentRaw(
      String collection, String documentId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      _setError('Failed to update document: $e');
      rethrow;
    }
  }

  /// Delete document
  Future<void> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      _setError('Failed to delete document: $e');
      rethrow;
    }
  }

  /// Get document reference
  DocumentReference getDocumentReference(String collection, String documentId) {
    return _firestore.collection(collection).doc(documentId);
  }

  /// Run a Firestore transaction
  Future<T> runTransaction<T>(
      Future<T> Function(Transaction) updateFunction) async {
    try {
      return await _firestore.runTransaction(updateFunction);
    } catch (e) {
      _setError('Transaction failed: $e');
      rethrow;
    }
  }

  /// Get documents with filters
  Future<QuerySnapshot> getDocuments(
    String collection, {
    List<MapEntry<String, dynamic>>? filters,
    int? limit,
    DocumentSnapshot? startAfter,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          query = query.where(filter.key, isEqualTo: filter.value);
        }
      }

      // Apply ordering
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      _setError('Failed to get documents: $e');
      rethrow;
    }
  }

  /// Listen to document changes
  Stream<DocumentSnapshot> listenToDocument(
      String collection, String documentId) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }

  /// Listen to collection changes
  Stream<QuerySnapshot> listenToCollection(
    String collection, {
    List<MapEntry<String, dynamic>>? filters,
    String? orderBy,
    bool descending = false,
  }) {
    Query query = _firestore.collection(collection);

    if (filters != null) {
      for (final filter in filters) {
        query = query.where(filter.key, isEqualTo: filter.value);
      }
    }

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    return query.snapshots();
  }

  // ========== STORAGE OPERATIONS ==========

  /// Upload file to Firebase Storage
  Future<String> uploadFile(
      String path, Uint8List bytes, String contentType) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask =
          ref.putData(bytes, SettableMetadata(contentType: contentType));
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _setError('Failed to upload file: $e');
      rethrow;
    }
  }

  /// Delete file from Firebase Storage
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      _setError('Failed to delete file: $e');
      rethrow;
    }
  }

  // ========== SERVER TIME OPERATIONS ==========

  /// Get Firebase server timestamp for use in documents
  /// This is the recommended way to get server time for document fields
  FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// Get actual Firebase server time as DateTime
  /// This makes a network call to get the current server time
  Future<DateTime> getServerTime() async {
    try {
      // Create a temporary document to get server timestamp
      final docRef = _firestore.collection('_serverTime').doc('current');

      // Write a document with server timestamp
      await docRef.set({
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Read it back to get the actual timestamp
      final doc = await docRef.get();
      final timestamp = doc.data()?['timestamp'] as Timestamp?;

      // Clean up the temporary document
      await docRef.delete();

      if (timestamp != null) {
        return timestamp.toDate();
      } else {
        throw Exception('Failed to get server timestamp');
      }
    } catch (e) {
      _setError('Failed to get server time: $e');
      rethrow;
    }
  }

  /// Get server timestamp as ISO string
  Future<String> getServerTimeAsIsoString() async {
    final serverTime = await getServerTime();
    return serverTime.toIso8601String();
  }

  /// Create a map with server timestamp for document creation/updates
  /// Usage: {'field': 'value', ...getServerTimestampMap()}
  Map<String, dynamic> getServerTimestampMap() {
    return {
      'timestamp': FieldValue.serverTimestamp(),
    };
  }

  /// Create a map with createdAt and updatedAt server timestamps
  /// Usage: {'field': 'value', ...getCreatedUpdatedTimestampMap()}
  Map<String, dynamic> getCreatedUpdatedTimestampMap() {
    return {
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// Create a map with only updatedAt server timestamp
  /// Usage: {'field': 'value', ...getUpdatedTimestampMap()}
  Map<String, dynamic> getUpdatedTimestampMap() {
    return {
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // ========== UTILITY METHODS ==========

  /// Clear error state
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Set error state
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear offline cache
  Future<void> clearOfflineCache() async {
    try {
      await _firestore.clearPersistence();
    } catch (e) {
      debugPrint('Failed to clear offline cache: $e');
    }
  }
}
