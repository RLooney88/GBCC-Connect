import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_config_service.dart';
import 'package:flutter/foundation.dart'; // Added for debugPrint

class FirestoreService {
  static FirestoreService? _instance;
  static FirestoreService get instance =>
      _instance ??= FirestoreService._internal();

  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseConfigService _configService = FirebaseConfigService.instance;

  /// Get Firestore instance
  FirebaseFirestore get firestore => _firestore;

  /// Create a document with auto-generated ID
  Future<DocumentReference> createDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = await _firestore.collection(collection).add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log analytics event
      await _configService.logEvent(
        name: 'document_created',
        parameters: {
          'collection': collection,
          'document_id': docRef.id,
        },
      );

      return docRef;
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Document creation failed');
      rethrow;
    }
  }

  /// Create a document with custom ID
  Future<void> createDocumentWithId({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log analytics event
      await _configService.logEvent(
        name: 'document_created_with_id',
        parameters: {
          'collection': collection,
          'document_id': documentId,
        },
      );
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Document creation with ID failed');
      rethrow;
    }
  }

  /// Get a document by ID
  Future<DocumentSnapshot?> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      debugPrint(
          'FirestoreService: Getting document from collection: $collection, documentId: $documentId');
      final doc = await _firestore.collection(collection).doc(documentId).get();

      if (doc.exists) {
        debugPrint('FirestoreService: Document found and exists');
        return doc;
      } else {
        debugPrint('FirestoreService: Document does not exist');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('FirestoreService: Error getting document: $e');
      await _configService.logError(e, stackTrace,
          reason: 'Document retrieval failed');
      return null;
    }
  }

  /// Update a document
  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      debugPrint(
          'FirestoreService: Updating document in collection: $collection, documentId: $documentId');
      debugPrint('FirestoreService: Update data: $data');

      await _firestore.collection(collection).doc(documentId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint(
          'FirestoreService: Document updated successfully in Firestore');

      // Log analytics event
      await _configService.logEvent(
        name: 'document_updated',
        parameters: {
          'collection': collection,
          'document_id': documentId,
        },
      );
    } catch (e, stackTrace) {
      debugPrint('FirestoreService: Error updating document: $e');
      await _configService.logError(e, stackTrace,
          reason: 'Document update failed');
      rethrow;
    }
  }

  /// Delete a document
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();

      // Log analytics event
      await _configService.logEvent(
        name: 'document_deleted',
        parameters: {
          'collection': collection,
          'document_id': documentId,
        },
      );
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Document deletion failed');
      rethrow;
    }
  }

  /// Get documents with query
  Future<QuerySnapshot> getDocuments({
    required String collection,
    List<QueryFilter>? filters,
    List<QueryOrder>? orders,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          switch (filter.type) {
            case QueryFilterType.isEqualTo:
              query = query.where(filter.field, isEqualTo: filter.value);
              break;
            case QueryFilterType.arrayContains:
              query = query.where(filter.field, arrayContains: filter.value);
              break;
            case QueryFilterType.arrayContainsAny:
              query = query.where(filter.field, arrayContainsAny: filter.value);
              break;
            case QueryFilterType.whereIn:
              query = query.where(filter.field, whereIn: filter.value);
              break;
            case QueryFilterType.whereNotIn:
              query = query.where(filter.field, whereNotIn: filter.value);
              break;
            case QueryFilterType.isLessThan:
              query = query.where(filter.field, isLessThan: filter.value);
              break;
            case QueryFilterType.isLessThanOrEqualTo:
              query =
                  query.where(filter.field, isLessThanOrEqualTo: filter.value);
              break;
            case QueryFilterType.isGreaterThan:
              query = query.where(filter.field, isGreaterThan: filter.value);
              break;
            case QueryFilterType.isGreaterThanOrEqualTo:
              query = query.where(filter.field,
                  isGreaterThanOrEqualTo: filter.value);
              break;
          }
        }
      }

      // Apply ordering
      if (orders != null) {
        for (final order in orders) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      // Apply pagination
      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      return await query.get();
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Document query failed');
      rethrow;
    }
  }

  /// Stream documents with real-time updates
  Stream<QuerySnapshot> streamDocuments({
    required String collection,
    List<QueryFilter>? filters,
    List<QueryOrder>? orders,
    int? limit,
  }) {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters
      if (filters != null) {
        for (final filter in filters) {
          switch (filter.type) {
            case QueryFilterType.isEqualTo:
              query = query.where(filter.field, isEqualTo: filter.value);
              break;
            case QueryFilterType.arrayContains:
              query = query.where(filter.field, arrayContains: filter.value);
              break;
            case QueryFilterType.arrayContainsAny:
              query = query.where(filter.field, arrayContainsAny: filter.value);
              break;
            case QueryFilterType.whereIn:
              query = query.where(filter.field, whereIn: filter.value);
              break;
            case QueryFilterType.whereNotIn:
              query = query.where(filter.field, whereNotIn: filter.value);
              break;
            case QueryFilterType.isLessThan:
              query = query.where(filter.field, isLessThan: filter.value);
              break;
            case QueryFilterType.isLessThanOrEqualTo:
              query =
                  query.where(filter.field, isLessThanOrEqualTo: filter.value);
              break;
            case QueryFilterType.isGreaterThan:
              query = query.where(filter.field, isGreaterThan: filter.value);
              break;
            case QueryFilterType.isGreaterThanOrEqualTo:
              query = query.where(filter.field,
                  isGreaterThanOrEqualTo: filter.value);
              break;
          }
        }
      }

      // Apply ordering
      if (orders != null) {
        for (final order in orders) {
          query = query.orderBy(order.field, descending: order.descending);
        }
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots();
    } catch (e, stackTrace) {
      _configService.logError(e, stackTrace, reason: 'Document stream failed');
      rethrow;
    }
  }

  /// Stream a single document
  Stream<DocumentSnapshot?> streamDocument({
    required String collection,
    required String documentId,
  }) {
    try {
      return _firestore.collection(collection).doc(documentId).snapshots();
    } catch (e, stackTrace) {
      _configService.logError(e, stackTrace, reason: 'Document stream failed');
      rethrow;
    }
  }

  /// Batch write operations
  Future<void> batchWrite(List<BatchOperation> operations) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        switch (operation.type) {
          case BatchOperationType.create:
            batch.set(
              _firestore
                  .collection(operation.collection)
                  .doc(operation.documentId),
              {
                if (operation.data != null) ...operation.data!,
                'createdAt': FieldValue.serverTimestamp(),
                'updatedAt': FieldValue.serverTimestamp(),
              },
            );
            break;
          case BatchOperationType.update:
            batch.update(
              _firestore
                  .collection(operation.collection)
                  .doc(operation.documentId),
              {
                if (operation.data != null) ...operation.data!,
                'updatedAt': FieldValue.serverTimestamp(),
              },
            );
            break;
          case BatchOperationType.delete:
            batch.delete(
              _firestore
                  .collection(operation.collection)
                  .doc(operation.documentId),
            );
            break;
        }
      }

      await batch.commit();

      // Log analytics event
      await _configService.logEvent(
        name: 'batch_write_completed',
        parameters: {
          'operation_count': operations.length,
        },
      );
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Batch write failed');
      rethrow;
    }
  }

  /// Transaction operations
  Future<T> runTransaction<T>(
      Future<T> Function(Transaction) transactionFunction) async {
    try {
      return await _firestore.runTransaction(transactionFunction);
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Transaction failed');
      rethrow;
    }
  }

  /// Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Offline persistence setup failed');
      rethrow;
    }
  }

  /// Clear offline cache
  Future<void> clearOfflineCache() async {
    try {
      await _firestore.clearPersistence();
    } catch (e, stackTrace) {
      await _configService.logError(e, stackTrace,
          reason: 'Cache clearing failed');
      rethrow;
    }
  }
}

/// Query filter class
class QueryFilter {
  final String field;
  final dynamic value;
  final QueryFilterType type;

  QueryFilter(this.field, this.value, {this.type = QueryFilterType.isEqualTo});
}

/// Query filter types
enum QueryFilterType {
  isEqualTo,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
}

/// Query order class
class QueryOrder {
  final String field;
  final bool descending;

  QueryOrder(this.field, {this.descending = false});
}

/// Batch operation types
enum BatchOperationType { create, update, delete }

/// Batch operation class
class BatchOperation {
  final BatchOperationType type;
  final String collection;
  final String documentId;
  final Map<String, dynamic>? data;

  BatchOperation.create({
    required this.collection,
    required this.documentId,
    required this.data,
  }) : type = BatchOperationType.create;

  BatchOperation.update({
    required this.collection,
    required this.documentId,
    required this.data,
  }) : type = BatchOperationType.update;

  BatchOperation.delete({
    required this.collection,
    required this.documentId,
  })  : type = BatchOperationType.delete,
        data = null;
}
