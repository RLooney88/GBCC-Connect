import 'package:gbcc_connect_app/src/core/utils/functions.dart';

class User {
  final String id;
  final String? name;
  final String email;
  final String? displayName;
  final String? phone;
  final String? address;
  final String? title;
  final String? website;
  final String? notes;
  final String? instagram;
  final String? facebook;
  final String? youtube;
  final String? linkedin;
  final String? pinterest;
  final bool chamberMember;
  final bool isOwner;
  final String? company;
  final String? companyPhone;
  final String? companyEmail;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.displayName,
    this.phone,
    this.address,
    this.title,
    this.website,
    this.notes,
    this.instagram,
    this.facebook,
    this.youtube,
    this.linkedin,
    this.pinterest,
    this.chamberMember = false,
    this.isOwner = true,
    this.company,
    this.companyPhone,
    this.companyEmail,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'],
      phone: json['phone'],
      address: json['address'],
      title: json['title'],
      website: json['website'],
      notes: json['notes'],
      instagram: json['instagram'],
      facebook: json['facebook'],
      youtube: json['youtube'],
      linkedin: json['linkedin'],
      pinterest: json['pinterest'],
      chamberMember: json['chamberMember'] ?? false,
      isOwner: json['isOwner'] ?? true,
      company: json['company'],
      companyPhone: json['companyPhone'],
      companyEmail: json['companyEmail'],
      status: json['status'] ?? 'active',
      createdAt: parseDateTime(json['createdAt']),
      updatedAt: parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'displayName': displayName,
      'phone': phone,
      'address': address,
      'title': title,
      'website': website,
      'notes': notes,
      'instagram': instagram,
      'facebook': facebook,
      'youtube': youtube,
      'linkedin': linkedin,
      'pinterest': pinterest,
      'chamberMember': chamberMember,
      'isOwner': isOwner,
      'company': company,
      'companyPhone': companyPhone,
      'companyEmail': companyEmail,
      'status': status,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? displayName,
    String? phone,
    String? address,
    String? title,
    String? website,
    String? notes,
    String? instagram,
    String? facebook,
    String? youtube,
    String? linkedin,
    String? pinterest,
    bool? chamberMember,
    bool? isOwner,
    String? company,
    String? companyPhone,
    String? companyEmail,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      title: title ?? this.title,
      website: website ?? this.website,
      notes: notes ?? this.notes,
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      youtube: youtube ?? this.youtube,
      linkedin: linkedin ?? this.linkedin,
      pinterest: pinterest ?? this.pinterest,
      chamberMember: chamberMember ?? this.chamberMember,
      isOwner: isOwner ?? this.isOwner,
      company: company ?? this.company,
      companyPhone: companyPhone ?? this.companyPhone,
      companyEmail: companyEmail ?? this.companyEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
