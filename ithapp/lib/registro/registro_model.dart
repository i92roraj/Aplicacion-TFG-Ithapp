import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/flutter_flow/random_data_util.dart' as random_data;
import '/index.dart';
import 'registro_widget.dart' show RegistroWidget;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class RegistroModel extends FlutterFlowModel<RegistroWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for Usuario widget.
  FocusNode? usuarioFocusNode;
  TextEditingController? usuarioTextController;
  String? Function(BuildContext, String?)? usuarioTextControllerValidator;
  // State field(s) for Nombre widget.
  FocusNode? nombreFocusNode;
  TextEditingController? nombreTextController;
  String? Function(BuildContext, String?)? nombreTextControllerValidator;
  // State field(s) for clave widget.
  FocusNode? claveFocusNode;
  TextEditingController? claveTextController;
  late bool claveVisibility;
  String? Function(BuildContext, String?)? claveTextControllerValidator;
  DateTime? datePicked;
  // State field(s) for sexo widget.
  String? sexoValue;
  FormFieldController<String>? sexoValueController;
  // State field(s) for cp widget.
  FocusNode? cpFocusNode;
  TextEditingController? cpTextController;
  String? Function(BuildContext, String?)? cpTextControllerValidator;
  // State field(s) for n-granja widget.
  FocusNode? nGranjaFocusNode;
  TextEditingController? nGranjaTextController;
  String? Function(BuildContext, String?)? nGranjaTextControllerValidator;

  FocusNode? nSensorFocusNode;
  TextEditingController? nSensorTextController;
  String? Function(BuildContext, String?)? nSensorTextControllerValidator;
  // State field(s) for ubicacion widget.
  FocusNode? ubicacionFocusNode;
  TextEditingController? ubicacionTextController;
  String? Function(BuildContext, String?)? ubicacionTextControllerValidator;

  @override
  void initState(BuildContext context) {
    claveVisibility = false;
  }

  @override
  void dispose() {
    usuarioFocusNode?.dispose();
    usuarioTextController?.dispose();

    nombreFocusNode?.dispose();
    nombreTextController?.dispose();

    claveFocusNode?.dispose();
    claveTextController?.dispose();

    cpFocusNode?.dispose();
    cpTextController?.dispose();

    nGranjaFocusNode?.dispose();
    nGranjaTextController?.dispose();

    nSensorFocusNode?.dispose();
    nSensorTextController?.dispose();

    ubicacionFocusNode?.dispose();
    ubicacionTextController?.dispose();
  }
}
