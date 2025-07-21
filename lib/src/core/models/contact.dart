import 'user.dart';

class Contact {
  final String id;
  final String ownerId; // ID of the user who owns this contact
  final User owner; // Reference to the owner user object
  final String name;
  final String displayName;
  final String email;
  final String? phone;
  final String? company;
  final String? website;
  final String? position;
  final String? notes;
  final String? instagram;
  final String? facebook;
  final String? youtube;
  final String? linkedin;
  final String? pinterest;
  final bool isFavorite;
  final bool isBlocked;
  final bool chamberMember;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    required this.id,
    required this.ownerId,
    required this.owner,
    required this.name,
    required this.displayName,
    required this.email,
    this.phone,
    this.company,
    this.website,
    this.position,
    this.notes,
    this.instagram,
    this.facebook,
    this.youtube,
    this.linkedin,
    this.pinterest,
    this.isFavorite = false,
    this.isBlocked = false,
    this.chamberMember = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    // Handle owner data more robustly
    User owner;
    try {
      if (json['owner'] != null && json['owner'] is Map<String, dynamic>) {
        owner = User.fromJson(json['owner'] as Map<String, dynamic>);
      } else {
        // Create a minimal user object if owner data is missing
        owner = User(
          id: json['ownerId'] ?? '',
          name: 'Unknown User',
          email: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      // Fallback user object if parsing fails
      owner = User(
        id: json['ownerId'] ?? '',
        name: 'Unknown User',
        email: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    return Contact(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      owner: owner,
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      company: json['company'],
      website: json['website'],
      position: json['position'],
      notes: json['notes'],
      instagram: json['instagram'],
      facebook: json['facebook'],
      youtube: json['youtube'],
      linkedin: json['linkedin'],
      pinterest: json['pinterest'],
      isFavorite: json['isFavorite'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      chamberMember: json['chamberMember'] ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  // Helper method to parse DateTime safely
  static DateTime _parseDateTime(dynamic dateTimeValue) {
    if (dateTimeValue == null) {
      return DateTime.now();
    }

    if (dateTimeValue is DateTime) {
      return dateTimeValue;
    }

    if (dateTimeValue is String) {
      try {
        return DateTime.parse(dateTimeValue);
      } catch (e) {
        return DateTime.now();
      }
    }

    // Handle Firestore Timestamp objects
    if (dateTimeValue.toString().contains('Timestamp')) {
      try {
        // This is a Firestore Timestamp, convert to DateTime
        final timestamp = dateTimeValue as dynamic;
        if (timestamp.toDate != null) {
          return timestamp.toDate();
        }
      } catch (e) {
        return DateTime.now();
      }
    }

    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    final json = {
      'ownerId': ownerId,
      'owner': owner.toJson(),
      'name': name,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'company': company,
      'website': website,
      'position': position,
      'notes': notes,
      'instagram': instagram,
      'facebook': facebook,
      'youtube': youtube,
      'linkedin': linkedin,
      'pinterest': pinterest,
      'isFavorite': isFavorite,
      'isBlocked': isBlocked,
      'chamberMember': chamberMember,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };

    // Only include ID if it's not empty
    if (id.isNotEmpty) {
      json['id'] = id;
    }

    return json;
  }

  Contact copyWith({
    String? id,
    String? ownerId,
    User? owner,
    String? name,
    String? displayName,
    String? email,
    String? phone,
    String? company,
    String? website,
    String? position,
    String? notes,
    String? instagram,
    String? facebook,
    String? youtube,
    String? linkedin,
    String? pinterest,
    bool? isFavorite,
    bool? isBlocked,
    bool? chamberMember,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      owner: owner ?? this.owner,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      website: website ?? this.website,
      position: position ?? this.position,
      notes: notes ?? this.notes,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      youtube: youtube ?? this.youtube,
      linkedin: linkedin ?? this.linkedin,
      pinterest: pinterest ?? this.pinterest,
      isFavorite: isFavorite ?? this.isFavorite,
      isBlocked: isBlocked ?? this.isBlocked,
      chamberMember: chamberMember ?? this.chamberMember,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
