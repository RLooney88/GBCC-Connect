import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact.dart';
import '../models/user.dart';
import 'firestore_service.dart';
import 'user_service.dart';

class ContactService {
  static ContactService? _instance;
  static ContactService get instance =>
      _instance ??= ContactService._internal();

  ContactService._internal();

  final FirestoreService _firestoreService = FirestoreService.instance;
  final UserService _userService = UserService.instance;
  static const String _collection = 'contacts';

  /// Create a new contact
  Future<String> createContact(Contact contact) async {
    try {
      final docRef = await _firestoreService.createDocument(
        collection: _collection,
        data: contact.toJson(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create contact: $e');
    }
  }

  /// Get contact by ID
  Future<Contact?> getContactById(String contactId) async {
    try {
      final doc = await _firestoreService.getDocument(
        collection: _collection,
        documentId: contactId,
      );

      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Fetch the owner user data
        User? owner;
        if (data['ownerId'] != null) {
          owner = await _userService.getUserById(data['ownerId']);
        }

        return Contact.fromJson({
          'id': doc.id,
          ...data,
          'owner': owner?.toJson() ?? data['owner'],
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get contact: $e');
    }
  }

  /// Update contact
  Future<void> updateContact(String contactId, Contact contact) async {
    try {
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: contactId,
        data: contact.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

  /// Delete contact
  Future<void> deleteContact(String contactId) async {
    try {
      await _firestoreService.deleteDocument(
        collection: _collection,
        documentId: contactId,
      );
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }

  /// Get contacts by owner ID
  Future<List<Contact>> getContactsByOwner(String ownerId) async {
    try {
      final querySnapshot = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [QueryFilter('ownerId', ownerId)],
        orders: [QueryOrder('name')],
      );

      final contacts = <Contact>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Fetch the owner user data
        User? owner;
        if (data['ownerId'] != null) {
          owner = await _userService.getUserById(data['ownerId']);
        }

        contacts.add(Contact.fromJson({
          'id': doc.id,
          ...data,
          'owner': owner?.toJson() ?? data['owner'],
        }));
      }

      return contacts;
    } catch (e) {
      throw Exception('Failed to get contacts by owner: $e');
    }
  }

  /// Get favorite contacts by owner ID
  Future<List<Contact>> getFavoriteContacts(String ownerId) async {
    try {
      final querySnapshot = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [
          QueryFilter('ownerId', ownerId),
          QueryFilter('isFavorite', true),
        ],
        orders: [QueryOrder('name')],
      );

      final contacts = <Contact>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Fetch the owner user data
        User? owner;
        if (data['ownerId'] != null) {
          owner = await _userService.getUserById(data['ownerId']);
        }

        contacts.add(Contact.fromJson({
          'id': doc.id,
          ...data,
          'owner': owner?.toJson() ?? data['owner'],
        }));
      }

      return contacts;
    } catch (e) {
      throw Exception('Failed to get favorite contacts: $e');
    }
  }

  /// Get blocked contacts by owner ID
  Future<List<Contact>> getBlockedContacts(String ownerId) async {
    try {
      final querySnapshot = await _firestoreService.getDocuments(
        collection: _collection,
        filters: [
          QueryFilter('ownerId', ownerId),
          QueryFilter('isBlocked', true),
        ],
        orders: [QueryOrder('name')],
      );

      final contacts = <Contact>[];

      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Fetch the owner user data
        User? owner;
        if (data['ownerId'] != null) {
          owner = await _userService.getUserById(data['ownerId']);
        }

        contacts.add(Contact.fromJson({
          'id': doc.id,
          ...data,
          'owner': owner?.toJson() ?? data['owner'],
        }));
      }

      return contacts;
    } catch (e) {
      throw Exception('Failed to get blocked contacts: $e');
    }
  }

  /// Search contacts by name or email
  Future<List<Contact>> searchContacts(
      String ownerId, String searchTerm) async {
    try {
      final allContacts = await getContactsByOwner(ownerId);

      return allContacts.where((contact) {
        final name = contact.name.toLowerCase();
        final email = contact.email.toLowerCase();
        final search = searchTerm.toLowerCase();

        return name.contains(search) || email.contains(search);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search contacts: $e');
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String contactId, bool isFavorite) async {
    try {
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: contactId,
        data: {
          'isFavorite': isFavorite,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  /// Toggle blocked status
  Future<void> toggleBlocked(String contactId, bool isBlocked) async {
    try {
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: contactId,
        data: {
          'isBlocked': isBlocked,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw Exception('Failed to toggle blocked: $e');
    }
  }

  /// Stream contacts by owner with real-time updates
  Stream<List<Contact>> streamContactsByOwner(String ownerId) {
    try {
      return _firestoreService.streamDocuments(
        collection: _collection,
        filters: [QueryFilter('ownerId', ownerId)],
        orders: [QueryOrder('name')],
      ).asyncMap((querySnapshot) async {
        final contacts = <Contact>[];

        for (final doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Fetch the owner user data
          User? owner;
          if (data['ownerId'] != null) {
            owner = await _userService.getUserById(data['ownerId']);
          }

          contacts.add(Contact.fromJson({
            'id': doc.id,
            ...data,
            'owner': owner?.toJson() ?? data['owner'],
          }));
        }

        return contacts;
      });
    } catch (e) {
      throw Exception('Failed to stream contacts: $e');
    }
  }

  /// Stream favorite contacts with real-time updates
  Stream<List<Contact>> streamFavoriteContacts(String ownerId) {
    try {
      return _firestoreService.streamDocuments(
        collection: _collection,
        filters: [
          QueryFilter('ownerId', ownerId),
          QueryFilter('isFavorite', true),
        ],
        orders: [QueryOrder('name')],
      ).asyncMap((querySnapshot) async {
        final contacts = <Contact>[];

        for (final doc in querySnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;

          // Fetch the owner user data
          User? owner;
          if (data['ownerId'] != null) {
            owner = await _userService.getUserById(data['ownerId']);
          }

          contacts.add(Contact.fromJson({
            'id': doc.id,
            ...data,
            'owner': owner?.toJson() ?? data['owner'],
          }));
        }

        return contacts;
      });
    } catch (e) {
      throw Exception('Failed to stream favorite contacts: $e');
    }
  }

  /// Get contacts by company
  Future<List<Contact>> getContactsByCompany(
      String ownerId, String company) async {
    try {
      final allContacts = await getContactsByOwner(ownerId);

      return allContacts.where((contact) {
        return contact.company?.toLowerCase() == company.toLowerCase();
      }).toList();
    } catch (e) {
      throw Exception('Failed to get contacts by company: $e');
    }
  }

  /// Update contact notes
  Future<void> updateContactNotes(String contactId, String notes) async {
    try {
      await _firestoreService.updateDocument(
        collection: _collection,
        documentId: contactId,
        data: {
          'notes': notes,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    } catch (e) {
      throw Exception('Failed to update contact notes: $e');
    }
  }

  /// Get contact statistics for a user
  Future<Map<String, int>> getContactStats(String ownerId) async {
    try {
      final allContacts = await getContactsByOwner(ownerId);

      return {
        'total': allContacts.length,
        'favorites': allContacts.where((c) => c.isFavorite).length,
        'blocked': allContacts.where((c) => c.isBlocked).length,
        'withCompany': allContacts
            .where((c) => c.company != null && c.company!.isNotEmpty)
            .length,
      };
    } catch (e) {
      throw Exception('Failed to get contact stats: $e');
    }
  }
}
