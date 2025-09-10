import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'dispositivos_widget.dart' show DispositivosWidget;

/// Modelo simplificado acorde a la nueva pantalla:
/// - Nº de serie (DEV_EUI), Modelo, Área, Zona, Sala
/// - Modo de operación (auto/manual) y Umbral ITH
class DispositivosModel extends FlutterFlowModel<DispositivosWidget> {
  // FocusNodes y Controllers
  FocusNode? serieFocusNode;
  TextEditingController? serieController;

  FocusNode? modeloFocusNode;
  TextEditingController? modeloController;

  FocusNode? areaFocusNode;
  TextEditingController? areaController;

  FocusNode? zonaFocusNode;
  TextEditingController? zonaController;

  FocusNode? salaFocusNode;
  TextEditingController? salaController;

  // Estado de UI
  String modo = 'auto';   // 'auto' | 'manual'
  double umbral = 75;     // 60..90

  bool saving = false;

  // Validadores opcionales (si los usas)
  String? Function(BuildContext, String?)? serieValidator;
  String? Function(BuildContext, String?)? modeloValidator;

  @override
  void initState(BuildContext context) {
    serieController  ??= TextEditingController();
    modeloController ??= TextEditingController();
    areaController   ??= TextEditingController();
    zonaController   ??= TextEditingController();
    salaController   ??= TextEditingController();
  }

  @override
  void dispose() {
    serieFocusNode?.dispose();
    serieController?.dispose();

    modeloFocusNode?.dispose();
    modeloController?.dispose();

    areaFocusNode?.dispose();
    areaController?.dispose();

    zonaFocusNode?.dispose();
    zonaController?.dispose();

    salaFocusNode?.dispose();
    salaController?.dispose();
  }

  bool get camposValidos =>
      (serieController?.text.trim().isNotEmpty ?? false) &&
      (modeloController?.text.trim().isNotEmpty ?? false);
}
