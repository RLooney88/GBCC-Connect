class Contact {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String? company;
  final String? position;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.company,
    this.position,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      company: json['company'],
      position: json['position'],
      notes: json['notes'],
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar': avatar,
      'company': company,
      'position': position,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Contact copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    String? company,
    String? position,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      company: company ?? this.company,
      position: position ?? this.position,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
