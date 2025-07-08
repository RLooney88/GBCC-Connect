import '/flutter_flow/flutter_flow_util.dart';
import 'add_contact_widget.dart' show AddContactWidget;
import 'package:flutter/material.dart';

class AddContactModel extends FlutterFlowModel<AddContactWidget> {
  ///  Local state fields for this page.
  /// Stores the user's full name input
  ///
  String? fullName;

  /// Stores the contact’s email address
  String? email;

  /// Stores the contact’s phone number
  String? phone;

  /// Stores the contact’s company name
  String? company;

  /// Stores the contact’s job title
  String? jobTitle;

  /// Stores the contact’s website URL
  String? website;

  /// Stores any notes about the contact
  String? notes;

  /// Scanned/Uploaded Business Card
  String? cardImage;

  List<String> searchKeywords = [];
  void addToSearchKeywords(String item) => searchKeywords.add(item);
  void removeFromSearchKeywords(String item) => searchKeywords.remove(item);
  void removeAtIndexFromSearchKeywords(int index) =>
      searchKeywords.removeAt(index);
  void insertAtIndexInSearchKeywords(int index, String item) =>
      searchKeywords.insert(index, item);
  void updateSearchKeywordsAtIndex(int index, Function(String) updateFn) =>
      searchKeywords[index] = updateFn(searchKeywords[index]);

  ///  State fields for stateful widgets in this page.

  // State field(s) for NameField widget.
  FocusNode? nameFieldFocusNode;
  TextEditingController? nameFieldTextController;
  String? Function(BuildContext, String?)? nameFieldTextControllerValidator;
  // State field(s) for PositionTitle widget.
  FocusNode? positionTitleFocusNode;
  TextEditingController? positionTitleTextController;
  String? Function(BuildContext, String?)? positionTitleTextControllerValidator;
  // State field(s) for Company widget.
  FocusNode? companyFocusNode;
  TextEditingController? companyTextController;
  String? Function(BuildContext, String?)? companyTextControllerValidator;
  // State field(s) for Email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for PhoneNumber widget.
  FocusNode? phoneNumberFocusNode;
  TextEditingController? phoneNumberTextController;
  String? Function(BuildContext, String?)? phoneNumberTextControllerValidator;
  // State field(s) for Website widget.
  FocusNode? websiteFocusNode;
  TextEditingController? websiteTextController;
  String? Function(BuildContext, String?)? websiteTextControllerValidator;
  // State field(s) for Notes widget.
  FocusNode? notesFocusNode;
  TextEditingController? notesTextController;
  String? Function(BuildContext, String?)? notesTextControllerValidator;
  bool isDataUploading_uploadDataRfm = false;
  FFUploadedFile uploadedLocalFile_uploadDataRfm =
      FFUploadedFile(bytes: Uint8List.fromList([]));

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFieldFocusNode?.dispose();
    nameFieldTextController?.dispose();

    positionTitleFocusNode?.dispose();
    positionTitleTextController?.dispose();

    companyFocusNode?.dispose();
    companyTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    phoneNumberFocusNode?.dispose();
    phoneNumberTextController?.dispose();

    websiteFocusNode?.dispose();
    websiteTextController?.dispose();

    notesFocusNode?.dispose();
    notesTextController?.dispose();
  }
}
