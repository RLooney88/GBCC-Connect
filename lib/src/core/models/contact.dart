import 'user.dart';

class Contact {
  final String id;
  final String ownerId; // ID of the user who owns this contact
  final User owner; // Reference to the owner user object
  final String name;
  final String email;
  final String? phone;
  final String? company;
  final String? position;
  final String? notes;
  final bool isFavorite;
  final bool isBlocked;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    required this.id,
    required this.ownerId,
    required this.owner,
    required this.name,
    required this.email,
    this.phone,
    this.company,
    this.position,
    this.notes,
    this.isFavorite = false,
    this.isBlocked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      owner: User.fromJson(json['owner'] ?? {}),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      company: json['company'],
      position: json['position'],
      notes: json['notes'],
      isFavorite: json['isFavorite'] ?? false,
      isBlocked: json['isBlocked'] ?? false,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'owner': owner.toJson(),
      'name': name,
      'email': email,
      'phone': phone,
      'company': company,
      'position': position,
      'notes': notes,
      'isFavorite': isFavorite,
      'isBlocked': isBlocked,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Contact copyWith({
    String? id,
    String? ownerId,
    User? owner,
    String? name,
    String? email,
    String? phone,
    String? company,
    String? position,
    String? notes,
    bool? isFavorite,
    bool? isBlocked,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      owner: owner ?? this.owner,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      company: company ?? this.company,
      position: position ?? this.position,
      notes: notes ?? this.notes,
      isFavorite: isFavorite ?? this.isFavorite,
      isBlocked: isBlocked ?? this.isBlocked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
