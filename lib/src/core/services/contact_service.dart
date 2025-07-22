import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contact.dart';
import '../models/user.dart';
import '../providers/firebase_provider.dart';

/// Domain/Business Logic Layer: ContactService
/// Mission: Implement contact-specific logic and transform data for the UI
/// - Business logic for contacts (fetching, searching, saving, deleting, etc.)
/// - Pure Dart code (no Flutter imports)
/// - Abstracts over FirebaseProvider or any data source
/// - Handles data mapping/DTOs if necessary
class ContactService {
  static ContactService? _instance;
  static ContactService get instance =>
      _instance ??= ContactService._internal();

  ContactService._internal();

  FirebaseProvider? _firebaseProvider;
  static const String _collection = 'contacts';

  /// Initialize the service with FirebaseProvider
  Future<void> initialize(FirebaseProvider firebaseProvider) async {
    _firebaseProvider = firebaseProvider;
  }

  /// Create a new contact
  Future<String> createContact(Contact contact) async {
    try {
      final docRef = await _firebaseProvider!.createDocument(
        _collection,
        contact.toJson(),
      );
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create contact: $e');
    }
  }

  /// Get contact by ID
  Future<Contact?> getContactById(String contactId) async {
    try {
      final doc = await _firebaseProvider!.getDocument(_collection, contactId);

      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // Fetch the owner user data
        User? owner;
        if (data['ownerId'] != null) {
          owner = await _getUserById(data['ownerId']);
        }

        return Contact.fromJson({
          'id': doc.id,
          ...data,
          'owner': owner != null ? owner.toJson() : data['owner'],
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
      await _firebaseProvider!.updateDocument(
        _collection,
        contactId,
        contact.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to update contact: $e');
    }
  }

  /// Delete contact
  Future<void> deleteContact(String contactId) async {
    try {
      await _firebaseProvider!.deleteDocument(_collection, contactId);
    } catch (e) {
      throw Exception('Failed to delete contact: $e');
    }
  }

  /// Get contacts by owner
  Future<List<Contact>> getContactsByOwner(
    String ownerId, {
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      // Fetch owner data once instead of for each contact
      final owner = await _getUserById(ownerId);

      final filters = [MapEntry('ownerId', ownerId)];
      final querySnapshot = await _firebaseProvider!.getDocuments(
        _collection,
        filters: filters,
        limit: limit,
        startAfter: startAfter,
        // Removed orderBy to avoid indexing requirement
      );

      final contacts = <Contact>[];
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        contacts.add(Contact.fromJson({
          'id': doc.id,
          ...data,
          'owner': owner != null ? owner.toJson() : data['owner'],
        }));
      }

      // Sort contacts by name on the client side
      contacts
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      return contacts;
    } catch (e) {
      throw Exception('Failed to get contacts by owner: $e');
    }
  }

  /// Search contacts by name or displayName
  Future<List<Contact>> searchContacts(
      String ownerId, String searchTerm) async {
    try {
      if (searchTerm.trim().isEmpty) {
        return await getContactsByOwner(ownerId);
      }

      final searchLower = searchTerm.toLowerCase();
      final allContacts = await getContactsByOwner(ownerId);

      return allContacts.where((contact) {
        return contact.name.toLowerCase().contains(searchLower) ||
            (contact.displayName.toLowerCase().contains(searchLower)) ||
            contact.email.toLowerCase().contains(searchLower) ||
            (contact.phone?.toLowerCase().contains(searchLower) ?? false) ||
            (contact.company?.toLowerCase().contains(searchLower) ?? false) ||
            (contact.position?.toLowerCase().contains(searchLower) ?? false) ||
            (contact.website?.toLowerCase().contains(searchLower) ?? false) ||
            (contact.instagram?.toLowerCase().contains(searchLower) ?? false) ||
            (contact.facebook?.toLowerCase().contains(searchLower) ?? false) ||
            (contact.linkedin?.toLowerCase().contains(searchLower) ?? false) ||
            (contact.youtube?.toLowerCase().contains(searchLower) ?? false) ||
            (contact.pinterest?.toLowerCase().contains(searchLower) ?? false) ||
            (contact.notes?.toLowerCase().contains(searchLower) ?? false);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search contacts: $e');
    }
  }

  /// Toggle contact favorite status
  Future<void> toggleFavorite(String contactId, bool isFavorite) async {
    try {
      await _firebaseProvider!.updateDocument(
        _collection,
        contactId,
        {
          'isFavorite': isFavorite,
          'updatedAt': DateTime.now().toIso8601String()
        },
      );
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  /// Get contact statistics
  Future<Map<String, int>> getContactStats(String ownerId) async {
    try {
      final contacts = await getContactsByOwner(ownerId);
      return {
        'total': contacts.length,
        'favorites': contacts.where((c) => c.isFavorite).length,
        'chamberMembers': contacts.where((c) => c.chamberMember).length,
        'blocked': contacts.where((c) => c.isBlocked).length,
      };
    } catch (e) {
      throw Exception('Failed to get contact stats: $e');
    }
  }

  /// Stream contacts in real-time
  Stream<List<Contact>> streamContactsByOwner(String ownerId) {
    try {
      final filters = [MapEntry('ownerId', ownerId)];
      return _firebaseProvider!
          .listenToCollection(
        _collection,
        filters: filters,
        // Removed orderBy to avoid indexing requirement
      )
          .asyncMap((snapshot) async {
        final owner = await _getUserById(ownerId);
        final contacts = <Contact>[];

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          contacts.add(Contact.fromJson({
            'id': doc.id,
            ...data,
            'owner': owner != null ? owner.toJson() : data['owner'],
          }));
        }

        // Sort contacts by name on the client side
        contacts.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        return contacts;
      });
    } catch (e) {
      throw Exception('Failed to stream contacts: $e');
    }
  }

  /// Validate contact data
  bool validateContact(Contact contact) {
    if (contact.name.trim().isEmpty) return false;
    if (contact.email.trim().isEmpty) return false;
    if (!_isValidEmail(contact.email)) return false;
    return true;
  }

  /// Check if email is valid
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  /// Get user by ID (helper method)
  Future<User?> _getUserById(String userId) async {
    try {
      final doc = await _firebaseProvider!.getDocument('users', userId);
      if (doc != null && doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return User.fromJson({
          'id': doc.id,
          ...data,
        });
      }
      return null;
    } catch (e) {
      // Return null if user not found, don't throw
      return null;
    }
  }

  /// Create contact from user data
  Contact createContactFromUser(User user, String ownerId) {
    return Contact(
      id: '',
      ownerId: ownerId,
      owner: user,
      name: user.name ?? '',
      displayName: user.displayName ?? user.name ?? '',
      email: user.email,
      phone: user.phone,
      company: user.company,
      website: user.website,
      position: user.title,
      notes: user.notes,
      isFavorite: false,
      isBlocked: false,
      chamberMember: user.chamberMember,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Export contacts to CSV format
  String exportContactsToCsv(List<Contact> contacts) {
    final csv = StringBuffer();

    // Header
    csv.writeln(
        'Name,Email,Phone,Company,Position,Website,Instagram,Facebook,LinkedIn,YouTube,Pinterest,Notes,Chamber Member,Blocked');

    // Data
    for (final contact in contacts) {
      csv.writeln([
        contact.name,
        contact.email,
        contact.phone ?? '',
        contact.company ?? '',
        contact.position ?? '',
        contact.website ?? '',
        contact.instagram ?? '',
        contact.facebook ?? '',
        contact.linkedin ?? '',
        contact.youtube ?? '',
        contact.pinterest ?? '',
        contact.notes ?? '',
        contact.chamberMember ? 'Yes' : 'No',
        contact.isBlocked ? 'Yes' : 'No',
      ].map((field) => '"${field.replaceAll('"', '""')}"').join(','));
    }

    return csv.toString();
  }

  /// Import contacts from CSV format
  List<Contact> importContactsFromCsv(
      String csvData, String ownerId, User owner) {
    final lines = csvData.split('\n');
    final contacts = <Contact>[];

    // Skip header
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      try {
        final fields = _parseCsvLine(line);
        if (fields.length >= 14) {
          final contact = Contact(
            id: '',
            ownerId: ownerId,
            owner: owner,
            name: fields[0],
            displayName: fields[0],
            email: fields[1],
            phone: fields[2].isEmpty ? null : fields[2],
            company: fields[3].isEmpty ? null : fields[3],
            position: fields[4].isEmpty ? null : fields[4],
            website: fields[5].isEmpty ? null : fields[5],
            instagram: fields[6].isEmpty ? null : fields[6],
            facebook: fields[7].isEmpty ? null : fields[7],
            linkedin: fields[8].isEmpty ? null : fields[8],
            youtube: fields[9].isEmpty ? null : fields[9],
            pinterest: fields[10].isEmpty ? null : fields[10],
            notes: fields[11].isEmpty ? null : fields[11],
            isFavorite: false,
            isBlocked: fields[13].toLowerCase() == 'yes',
            chamberMember: fields[12].toLowerCase() == 'yes',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          contacts.add(contact);
        }
      } catch (e) {
        // Skip invalid lines
        continue;
      }
    }

    return contacts;
  }

  /// Parse CSV line with proper quote handling
  List<String> _parseCsvLine(String line) {
    final fields = <String>[];
    final buffer = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          // Escaped quote
          buffer.write('"');
          i++; // Skip next quote
        } else {
          // Toggle quote state
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        // End of field
        fields.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }

    // Add last field
    fields.add(buffer.toString());
    return fields;
  }

  /// Check if a contact is a registered user
  Future<bool> isContactRegisteredUser(String email) async {
    try {
      final filters = [MapEntry('email', email)];
      final querySnapshot = await _firebaseProvider!.getDocuments(
        'users',
        filters: filters,
        limit: 1,
      );

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // If there's an error checking, assume not registered
      return false;
    }
  }

  /// Get user by email if they are registered
  Future<User?> getRegisteredUserByEmail(String email) async {
    try {
      final filters = [MapEntry('email', email)];
      final querySnapshot = await _firebaseProvider!.getDocuments(
        'users',
        filters: filters,
        limit: 1,
      );

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return User.fromJson({
          'id': doc.id,
          ...(doc.data() as Map<String, dynamic>),
        });
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
