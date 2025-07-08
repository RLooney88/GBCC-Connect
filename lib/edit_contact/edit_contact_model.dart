import '/flutter_flow/flutter_flow_util.dart';
import 'edit_contact_widget.dart' show EditContactWidget;
import 'package:flutter/material.dart';

class EditContactModel extends FlutterFlowModel<EditContactWidget> {
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

  String? profileImage;

  ///  State fields for stateful widgets in this page.

  // State field(s) for NameField widget.
  FocusNode? nameFieldFocusNode;
  TextEditingController? nameFieldTextController;
  String? Function(BuildContext, String?)? nameFieldTextControllerValidator;
  // State field(s) for PositionTitle widget.
  FocusNode? positionTitleFocusNode;
  TextEditingController? positionTitleTextController;
  String? Function(BuildContext, String?)? positionTitleTextControllerValidator;
  // State field(s) for Email widget.
  FocusNode? emailFocusNode;
  TextEditingController? emailTextController;
  String? Function(BuildContext, String?)? emailTextControllerValidator;
  // State field(s) for PhoneNumber widget.
  FocusNode? phoneNumberFocusNode;
  TextEditingController? phoneNumberTextController;
  String? Function(BuildContext, String?)? phoneNumberTextControllerValidator;
  // State field(s) for Company widget.
  FocusNode? companyFocusNode;
  TextEditingController? companyTextController;
  String? Function(BuildContext, String?)? companyTextControllerValidator;
  // State field(s) for Website widget.
  FocusNode? websiteFocusNode;
  TextEditingController? websiteTextController;
  String? Function(BuildContext, String?)? websiteTextControllerValidator;
  // State field(s) for Company-Email widget.
  FocusNode? companyEmailFocusNode;
  TextEditingController? companyEmailTextController;
  String? Function(BuildContext, String?)? companyEmailTextControllerValidator;
  // State field(s) for Company-Phone widget.
  FocusNode? companyPhoneFocusNode;
  TextEditingController? companyPhoneTextController;
  String? Function(BuildContext, String?)? companyPhoneTextControllerValidator;
  // State field(s) for Address widget.
  FocusNode? addressFocusNode;
  TextEditingController? addressTextController;
  String? Function(BuildContext, String?)? addressTextControllerValidator;
  // State field(s) for Facebook widget.
  FocusNode? facebookFocusNode;
  TextEditingController? facebookTextController;
  String? Function(BuildContext, String?)? facebookTextControllerValidator;
  // State field(s) for Instagram widget.
  FocusNode? instagramFocusNode;
  TextEditingController? instagramTextController;
  String? Function(BuildContext, String?)? instagramTextControllerValidator;
  // State field(s) for LinkedIn widget.
  FocusNode? linkedInFocusNode;
  TextEditingController? linkedInTextController;
  String? Function(BuildContext, String?)? linkedInTextControllerValidator;
  // State field(s) for YouTube widget.
  FocusNode? youTubeFocusNode;
  TextEditingController? youTubeTextController;
  String? Function(BuildContext, String?)? youTubeTextControllerValidator;
  // State field(s) for Pinterest widget.
  FocusNode? pinterestFocusNode;
  TextEditingController? pinterestTextController;
  String? Function(BuildContext, String?)? pinterestTextControllerValidator;
  // State field(s) for Notes widget.
  FocusNode? notesFocusNode;
  TextEditingController? notesTextController;
  String? Function(BuildContext, String?)? notesTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    nameFieldFocusNode?.dispose();
    nameFieldTextController?.dispose();

    positionTitleFocusNode?.dispose();
    positionTitleTextController?.dispose();

    emailFocusNode?.dispose();
    emailTextController?.dispose();

    phoneNumberFocusNode?.dispose();
    phoneNumberTextController?.dispose();

    companyFocusNode?.dispose();
    companyTextController?.dispose();

    websiteFocusNode?.dispose();
    websiteTextController?.dispose();

    companyEmailFocusNode?.dispose();
    companyEmailTextController?.dispose();

    companyPhoneFocusNode?.dispose();
    companyPhoneTextController?.dispose();

    addressFocusNode?.dispose();
    addressTextController?.dispose();

    facebookFocusNode?.dispose();
    facebookTextController?.dispose();

    instagramFocusNode?.dispose();
    instagramTextController?.dispose();

    linkedInFocusNode?.dispose();
    linkedInTextController?.dispose();

    youTubeFocusNode?.dispose();
    youTubeTextController?.dispose();

    pinterestFocusNode?.dispose();
    pinterestTextController?.dispose();

    notesFocusNode?.dispose();
    notesTextController?.dispose();
  }
}
