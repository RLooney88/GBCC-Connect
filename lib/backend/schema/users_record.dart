import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// App User Data
class UsersRecord extends FirestoreRecord {
  UsersRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "display_name" field.
  String? _displayName;
  String get displayName => _displayName ?? '';
  bool hasDisplayName() => _displayName != null;

  // "photo_url" field.
  String? _photoUrl;
  String get photoUrl => _photoUrl ?? '';
  bool hasPhotoUrl() => _photoUrl != null;

  // "uid" field.
  String? _uid;
  String get uid => _uid ?? '';
  bool hasUid() => _uid != null;

  // "created_time" field.
  DateTime? _createdTime;
  DateTime? get createdTime => _createdTime;
  bool hasCreatedTime() => _createdTime != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "company" field.
  String? _company;
  String get company => _company ?? '';
  bool hasCompany() => _company != null;

  // "title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "website" field.
  String? _website;
  String get website => _website ?? '';
  bool hasWebsite() => _website != null;

  // "instagram" field.
  String? _instagram;
  String get instagram => _instagram ?? '';
  bool hasInstagram() => _instagram != null;

  // "facebook" field.
  String? _facebook;
  String get facebook => _facebook ?? '';
  bool hasFacebook() => _facebook != null;

  // "youtube" field.
  String? _youtube;
  String get youtube => _youtube ?? '';
  bool hasYoutube() => _youtube != null;

  // "linkedin" field.
  String? _linkedin;
  String get linkedin => _linkedin ?? '';
  bool hasLinkedin() => _linkedin != null;

  // "pinterest" field.
  String? _pinterest;
  String get pinterest => _pinterest ?? '';
  bool hasPinterest() => _pinterest != null;

  // "chambermember" field.
  bool? _chambermember;
  bool get chambermember => _chambermember ?? false;
  bool hasChambermember() => _chambermember != null;

  // "company_phone" field.
  String? _companyPhone;
  String get companyPhone => _companyPhone ?? '';
  bool hasCompanyPhone() => _companyPhone != null;

  // "company_email" field.
  String? _companyEmail;
  String get companyEmail => _companyEmail ?? '';
  bool hasCompanyEmail() => _companyEmail != null;

  // "address" field.
  String? _address;
  String get address => _address ?? '';
  bool hasAddress() => _address != null;

  void _initializeFields() {
    _email = snapshotData['email'] as String?;
    _displayName = snapshotData['display_name'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _company = snapshotData['company'] as String?;
    _title = snapshotData['title'] as String?;
    _website = snapshotData['website'] as String?;
    _instagram = snapshotData['instagram'] as String?;
    _facebook = snapshotData['facebook'] as String?;
    _youtube = snapshotData['youtube'] as String?;
    _linkedin = snapshotData['linkedin'] as String?;
    _pinterest = snapshotData['pinterest'] as String?;
    _chambermember = snapshotData['chambermember'] as bool?;
    _companyPhone = snapshotData['company_phone'] as String?;
    _companyEmail = snapshotData['company_email'] as String?;
    _address = snapshotData['address'] as String?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('Users');

  static Stream<UsersRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UsersRecord.fromSnapshot(s));

  static Future<UsersRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UsersRecord.fromSnapshot(s));

  static UsersRecord fromSnapshot(DocumentSnapshot snapshot) => UsersRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UsersRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UsersRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UsersRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UsersRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUsersRecordData({
  String? email,
  String? displayName,
  String? photoUrl,
  String? uid,
  DateTime? createdTime,
  String? phoneNumber,
  String? company,
  String? title,
  String? website,
  String? instagram,
  String? facebook,
  String? youtube,
  String? linkedin,
  String? pinterest,
  bool? chambermember,
  String? companyPhone,
  String? companyEmail,
  String? address,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'uid': uid,
      'created_time': createdTime,
      'phone_number': phoneNumber,
      'company': company,
      'title': title,
      'website': website,
      'instagram': instagram,
      'facebook': facebook,
      'youtube': youtube,
      'linkedin': linkedin,
      'pinterest': pinterest,
      'chambermember': chambermember,
      'company_phone': companyPhone,
      'company_email': companyEmail,
      'address': address,
    }.withoutNulls,
  );

  return firestoreData;
}

class UsersRecordDocumentEquality implements Equality<UsersRecord> {
  const UsersRecordDocumentEquality();

  @override
  bool equals(UsersRecord? e1, UsersRecord? e2) {
    return e1?.email == e2?.email &&
        e1?.displayName == e2?.displayName &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.uid == e2?.uid &&
        e1?.createdTime == e2?.createdTime &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.company == e2?.company &&
        e1?.title == e2?.title &&
        e1?.website == e2?.website &&
        e1?.instagram == e2?.instagram &&
        e1?.facebook == e2?.facebook &&
        e1?.youtube == e2?.youtube &&
        e1?.linkedin == e2?.linkedin &&
        e1?.pinterest == e2?.pinterest &&
        e1?.chambermember == e2?.chambermember &&
        e1?.companyPhone == e2?.companyPhone &&
        e1?.companyEmail == e2?.companyEmail &&
        e1?.address == e2?.address;
  }

  @override
  int hash(UsersRecord? e) => const ListEquality().hash([
        e?.email,
        e?.displayName,
        e?.photoUrl,
        e?.uid,
        e?.createdTime,
        e?.phoneNumber,
        e?.company,
        e?.title,
        e?.website,
        e?.instagram,
        e?.facebook,
        e?.youtube,
        e?.linkedin,
        e?.pinterest,
        e?.chambermember,
        e?.companyPhone,
        e?.companyEmail,
        e?.address
      ]);

  @override
  bool isValidKey(Object? o) => o is UsersRecord;
}
