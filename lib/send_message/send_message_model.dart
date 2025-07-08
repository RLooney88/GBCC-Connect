import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'send_message_widget.dart' show SendMessageWidget;
import 'package:flutter/material.dart';

class SendMessageModel extends FlutterFlowModel<SendMessageWidget> {
  ///  Local state fields for this page.

  String? messageText;

  DocumentReference? conversationRef;

  ///  State fields for stateful widgets in this page.

  // State field(s) for messageText widget.
  FocusNode? messageTextFocusNode;
  TextEditingController? messageTextTextController;
  String? Function(BuildContext, String?)? messageTextTextControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    messageTextFocusNode?.dispose();
    messageTextTextController?.dispose();
  }
}
