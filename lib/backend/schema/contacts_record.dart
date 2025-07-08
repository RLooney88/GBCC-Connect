import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ContactsRecord extends FirestoreRecord {
  ContactsRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "full_name" field.
  String? _fullName;
  String get fullName => _fullName ?? '';
  bool hasFullName() => _fullName != null;

  // "Title" field.
  String? _title;
  String get title => _title ?? '';
  bool hasTitle() => _title != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "phone_number" field.
  String? _phoneNumber;
  String get phoneNumber => _phoneNumber ?? '';
  bool hasPhoneNumber() => _phoneNumber != null;

  // "company_name" field.
  String? _companyName;
  String get companyName => _companyName ?? '';
  bool hasCompanyName() => _companyName != null;

  // "notes" field.
  String? _notes;
  String get notes => _notes ?? '';
  bool hasNotes() => _notes != null;

  // "website" field.
  String? _website;
  String get website => _website ?? '';
  bool hasWebsite() => _website != null;

  // "created_at" field.
  DateTime? _createdAt;
  DateTime? get createdAt => _createdAt;
  bool hasCreatedAt() => _createdAt != null;

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

  // "linkedin" field.
  String? _linkedin;
  String get linkedin => _linkedin ?? '';
  bool hasLinkedin() => _linkedin != null;

  // "Facebook" field.
  String? _facebook;
  String get facebook => _facebook ?? '';
  bool hasFacebook() => _facebook != null;

  // "instagram" field.
  String? _instagram;
  String get instagram => _instagram ?? '';
  bool hasInstagram() => _instagram != null;

  // "youtube" field.
  String? _youtube;
  String get youtube => _youtube ?? '';
  bool hasYoutube() => _youtube != null;

  // "pintrest" field.
  String? _pintrest;
  String get pintrest => _pintrest ?? '';
  bool hasPintrest() => _pintrest != null;

  // "chamber_member" field.
  bool? _chamberMember;
  bool get chamberMember => _chamberMember ?? false;
  bool hasChamberMember() => _chamberMember != null;

  // "contactID" field.
  String? _contactID;
  String get contactID => _contactID ?? '';
  bool hasContactID() => _contactID != null;

  // "profile_image" field.
  String? _profileImage;
  String get profileImage => _profileImage ?? '';
  bool hasProfileImage() => _profileImage != null;

  // "imageProfile" field.
  String? _imageProfile;
  String get imageProfile => _imageProfile ?? '';
  bool hasImageProfile() => _imageProfile != null;

  // "search_keywords" field.
  List<String>? _searchKeywords;
  List<String> get searchKeywords => _searchKeywords ?? const [];
  bool hasSearchKeywords() => _searchKeywords != null;

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

  void _initializeFields() {
    _fullName = snapshotData['full_name'] as String?;
    _title = snapshotData['Title'] as String?;
    _email = snapshotData['email'] as String?;
    _phoneNumber = snapshotData['phone_number'] as String?;
    _companyName = snapshotData['company_name'] as String?;
    _notes = snapshotData['notes'] as String?;
    _website = snapshotData['website'] as String?;
    _createdAt = snapshotData['created_at'] as DateTime?;
    _companyPhone = snapshotData['company_phone'] as String?;
    _companyEmail = snapshotData['company_email'] as String?;
    _address = snapshotData['address'] as String?;
    _linkedin = snapshotData['linkedin'] as String?;
    _facebook = snapshotData['Facebook'] as String?;
    _instagram = snapshotData['instagram'] as String?;
    _youtube = snapshotData['youtube'] as String?;
    _pintrest = snapshotData['pintrest'] as String?;
    _chamberMember = snapshotData['chamber_member'] as bool?;
    _contactID = snapshotData['contactID'] as String?;
    _profileImage = snapshotData['profile_image'] as String?;
    _imageProfile = snapshotData['imageProfile'] as String?;
    _searchKeywords = getDataList(snapshotData['search_keywords']);
    _displayName = snapshotData['display_name'] as String?;
    _photoUrl = snapshotData['photo_url'] as String?;
    _uid = snapshotData['uid'] as String?;
    _createdTime = snapshotData['created_time'] as DateTime?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('contacts');

  static Stream<ContactsRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ContactsRecord.fromSnapshot(s));

  static Future<ContactsRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ContactsRecord.fromSnapshot(s));

  static ContactsRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ContactsRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ContactsRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ContactsRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ContactsRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ContactsRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createContactsRecordData({
  String? fullName,
  String? title,
  String? email,
  String? phoneNumber,
  String? companyName,
  String? notes,
  String? website,
  DateTime? createdAt,
  String? companyPhone,
  String? companyEmail,
  String? address,
  String? linkedin,
  String? facebook,
  String? instagram,
  String? youtube,
  String? pintrest,
  bool? chamberMember,
  String? contactID,
  String? profileImage,
  String? imageProfile,
  String? displayName,
  String? photoUrl,
  String? uid,
  DateTime? createdTime,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'full_name': fullName,
      'Title': title,
      'email': email,
      'phone_number': phoneNumber,
      'company_name': companyName,
      'notes': notes,
      'website': website,
      'created_at': createdAt,
      'company_phone': companyPhone,
      'company_email': companyEmail,
      'address': address,
      'linkedin': linkedin,
      'Facebook': facebook,
      'instagram': instagram,
      'youtube': youtube,
      'pintrest': pintrest,
      'chamber_member': chamberMember,
      'contactID': contactID,
      'profile_image': profileImage,
      'imageProfile': imageProfile,
      'display_name': displayName,
      'photo_url': photoUrl,
      'uid': uid,
      'created_time': createdTime,
    }.withoutNulls,
  );

  return firestoreData;
}

class ContactsRecordDocumentEquality implements Equality<ContactsRecord> {
  const ContactsRecordDocumentEquality();

  @override
  bool equals(ContactsRecord? e1, ContactsRecord? e2) {
    const listEquality = ListEquality();
    return e1?.fullName == e2?.fullName &&
        e1?.title == e2?.title &&
        e1?.email == e2?.email &&
        e1?.phoneNumber == e2?.phoneNumber &&
        e1?.companyName == e2?.companyName &&
        e1?.notes == e2?.notes &&
        e1?.website == e2?.website &&
        e1?.createdAt == e2?.createdAt &&
        e1?.companyPhone == e2?.companyPhone &&
        e1?.companyEmail == e2?.companyEmail &&
        e1?.address == e2?.address &&
        e1?.linkedin == e2?.linkedin &&
        e1?.facebook == e2?.facebook &&
        e1?.instagram == e2?.instagram &&
        e1?.youtube == e2?.youtube &&
        e1?.pintrest == e2?.pintrest &&
        e1?.chamberMember == e2?.chamberMember &&
        e1?.contactID == e2?.contactID &&
        e1?.profileImage == e2?.profileImage &&
        e1?.imageProfile == e2?.imageProfile &&
        listEquality.equals(e1?.searchKeywords, e2?.searchKeywords) &&
        e1?.displayName == e2?.displayName &&
        e1?.photoUrl == e2?.photoUrl &&
        e1?.uid == e2?.uid &&
        e1?.createdTime == e2?.createdTime;
  }

  @override
  int hash(ContactsRecord? e) => const ListEquality().hash([
        e?.fullName,
        e?.title,
        e?.email,
        e?.phoneNumber,
        e?.companyName,
        e?.notes,
        e?.website,
        e?.createdAt,
        e?.companyPhone,
        e?.companyEmail,
        e?.address,
        e?.linkedin,
        e?.facebook,
        e?.instagram,
        e?.youtube,
        e?.pintrest,
        e?.chamberMember,
        e?.contactID,
        e?.profileImage,
        e?.imageProfile,
        e?.searchKeywords,
        e?.displayName,
        e?.photoUrl,
        e?.uid,
        e?.createdTime
      ]);

  @override
  bool isValidKey(Object? o) => o is ContactsRecord;
}
