import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'contact_library_widget.dart' show ContactLibraryWidget;
import 'package:flutter/material.dart';

class ContactLibraryModel extends FlutterFlowModel<ContactLibraryWidget> {
  ///  Local state fields for this page.

  String? searchQuery;

  ///  State fields for stateful widgets in this page.

  // State field(s) for searchQuery widget.
  FocusNode? searchQueryFocusNode;
  TextEditingController? searchQueryTextController;
  String? Function(BuildContext, String?)? searchQueryTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    searchQueryFocusNode?.dispose();
    searchQueryTextController?.dispose();
  }
}
