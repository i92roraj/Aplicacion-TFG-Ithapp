import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/flutter_flow/random_data_util.dart' as random_data;
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'registro_model.dart';
export 'registro_model.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // ✅ para formatear fechas
// import 'package:mysql1/mysql1.dart'; // ❌ Quitado (no conexión directa a MySQL)

/// === Configuración de la API (Railway) ===
const String kApiBase =
    String.fromEnvironment('API_BASE_URL',
        defaultValue:
            'https://tfg-proyecto-ithapp-production.up.railway.app');

Uri api(String path) => Uri.parse('$kApiBase$path');

/// Cliente simple para tu backend
class Backend {
  final http.Client _client;
  Backend([http.Client? client]) : _client = client ?? http.Client();

  Future<int> crearGranja({
    required String nombre,
    required String direccion,
  }) async {
    final res = await _client.post(
      api('/granjas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'nombre_granja': nombre, 'direccion': direccion}),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Error creando granja: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['id_granja'] as num).toInt();
  }

  Future<int> crearUsuario({
    required String nombre,
    required String apellidos,
    required String email,
    required DateTime fechaNacimiento,
    required String password,
    required int idGranja,
  }) async {
    final res = await _client.post(
      api('/usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre': nombre,
        'apellidos': apellidos,
        'email': email,
        'fecha_nacimiento': DateFormat('yyyy-MM-dd').format(fechaNacimiento),
        'password': password,
        'id_granja': idGranja,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Error creando usuario: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['id_usuario'] as num).toInt();
  }

  Future<int> crearSensor({
    required String nombreSensor,
    required int idGranja,
  }) async {
    final res = await _client.post(
      api('/sensores'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre_sensor': nombreSensor,
        'id_granja': idGranja,
      }),
    );
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Error creando sensor: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data['id_sensor'] as num).toInt();
  }

  /// Flujo completo: granja → usuario → sensor
  Future<void> registroCompleto({
    required String nombreGranja,
    required String direccionGranja,
    required String nombreUsuario,
    required String apellidos,
    required String email,
    required DateTime fechaNacimiento,
    required String password,
    required String nombreSensor,
  }) async {
    final idGranja = await crearGranja(
      nombre: nombreGranja,
      direccion: direccionGranja,
    );

    await crearUsuario(
      nombre: nombreUsuario,
      apellidos: apellidos,
      email: email,
      fechaNacimiento: fechaNacimiento,
      password: password,
      idGranja: idGranja,
    );

    await crearSensor(
      nombreSensor: nombreSensor,
      idGranja: idGranja,
    );
  }
}

class RegistroWidget extends StatefulWidget {
  const RegistroWidget({super.key});

  static String routeName = 'registro';
  static String routePath = '/registro';

  @override
  State<RegistroWidget> createState() => _RegistroWidgetState();
}

class _RegistroWidgetState extends State<RegistroWidget> {
  late RegistroModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  LatLng? currentUserLocationValue;

  // ✅ instancia del cliente y estado de carga
  final _api = Backend();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegistroModel());

    _model.usuarioTextController ??= TextEditingController();
    _model.usuarioFocusNode ??= FocusNode();

    _model.nombreTextController ??= TextEditingController();
    _model.nombreFocusNode ??= FocusNode();

    _model.claveTextController ??= TextEditingController();
    _model.claveFocusNode ??= FocusNode();

    _model.cpTextController ??= TextEditingController();
    _model.cpFocusNode ??= FocusNode();

    _model.nGranjaTextController ??= TextEditingController();
    _model.nGranjaFocusNode ??= FocusNode();

    _model.ubicacionTextController ??= TextEditingController();
    _model.ubicacionFocusNode ??= FocusNode();

    _model.nSensorTextController ??= TextEditingController();
    _model.nSensorFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  /// ✅ Acción del botón "Registrar"
  Future<void> _onRegistrar() async {
    try {
      setState(() => _saving = true);

      final nombreGranja    = _model.nGranjaTextController?.text.trim() ?? '';
      final direccionGranja = _model.ubicacionTextController?.text.trim() ?? '';
      final nombreUsuario   = _model.nombreTextController?.text.trim() ?? '';
      final apellidos       = ''; // si tienes campo de apellidos, úsalo aquí
      final email           = _model.usuarioTextController?.text.trim() ?? '';
      final password        = _model.claveTextController?.text.trim() ?? '';
      final nombreSensor    = _model.nSensorTextController?.text.trim() ?? '';

      // TODO: sustituye por tu selector real de fecha si lo tienes
      final DateTime fechaNacimiento = DateTime(2000, 1, 1);

      if ([nombreGranja, direccionGranja, nombreUsuario, email, password, nombreSensor]
          .any((s) => s.isEmpty)) {
        showSnackbar(context, 'Completa todos los campos obligatorios');
        return;
      }

      await _api.registroCompleto(
        nombreGranja: nombreGranja,
        direccionGranja: direccionGranja,
        nombreUsuario: nombreUsuario,
        apellidos: apellidos,
        email: email,
        fechaNacimiento: fechaNacimiento,
        password: password,
        nombreSensor: nombreSensor,
      );

      showSnackbar(context, 'Registro completado con éxito');
      context.pushNamed(LoginWidget.routeName);
    } catch (e) {
      showSnackbar(context, 'Error registrando: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderRadius: 8.0,
            buttonSize: 40.0,
            fillColor: FlutterFlowTheme.of(context).primary,
            icon: Icon(
              Icons.arrow_back,
              color: FlutterFlowTheme.of(context).info,
              size: 24.0,
            ),
            onPressed: () async {
              context.pushNamed(LoginWidget.routeName);
            },
          ),
          title: Text(
            'Registrarse',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight:
                        FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight:
                      FlutterFlowTheme.of(context).headlineMedium.fontWeight,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: [],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(20.0, 10.0, 0.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Rellena los siguientes campos:',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w900,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w900,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 30.0, 70.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _model.usuarioTextController,
                          focusNode: _model.usuarioFocusNode,
                          onChanged: (_) => EasyDebounce.debounce(
                            '_model.usuarioTextController',
                            Duration(milliseconds: 2000),
                            () async {
                              FFAppState().email = valueOrDefault<String>(
                                currentUserEmail,
                                'r',
                              );
                              safeSetState(() {});
                            },
                          ),
                          autofocus: true,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Email',
                            hintStyle:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                          ),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                          keyboardType: TextInputType.emailAddress,
                          validator: _model.usuarioTextControllerValidator
                              .asValidator(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 30.0, 70.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _model.nombreTextController,
                          focusNode: _model.nombreFocusNode,
                          onChanged: (_) => EasyDebounce.debounce(
                            '_model.nombreTextController',
                            Duration(milliseconds: 2000),
                            () async {
                              FFAppState().nombre = currentUserDisplayName;
                              safeSetState(() {});
                            },
                          ),
                          autofocus: true,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Nombre',
                            hintText: 'Nombre y apellidos',
                            hintStyle:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0x00000000),
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0x00000000),
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0x00000000),
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                          ),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                          validator: _model.nombreTextControllerValidator
                              .asValidator(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 30.0, 70.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _model.claveTextController,
                          focusNode: _model.claveFocusNode,
                          autofocus: true,
                          obscureText: !_model.claveVisibility,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            hintText: 'Introduzca la contraseña...',
                            hintStyle:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0x00000000),
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0x00000000),
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0x00000000),
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            suffixIcon: InkWell(
                              onTap: () => safeSetState(
                                () => _model.claveVisibility =
                                    !_model.claveVisibility,
                              ),
                              focusNode: FocusNode(skipTraversal: true),
                              child: Icon(
                                _model.claveVisibility
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 24.0,
                              ),
                            ),
                          ),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                          validator: _model.claveTextControllerValidator
                              .asValidator(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 30.0, 100.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text(
                        dateTimeFormat("d/M/y", _model.datePicked),
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(
                                fontWeight: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontWeight,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .fontStyle,
                              ),
                              fontSize: 20.0,
                              letterSpacing: 0.0,
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                      ),
                      Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(10.0, 0.0, 0.0, 0.0),
                        child: FFButtonWidget(
                          onPressed: () async {
                            final _datePickedDate = await showDatePicker(
                              context: context,
                              initialDate: getCurrentTimestamp,
                              firstDate: DateTime(1900),
                              lastDate: getCurrentTimestamp,
                            );

                            if (_datePickedDate != null) {
                              safeSetState(() {
                                _model.datePicked = DateTime(
                                  _datePickedDate.year,
                                  _datePickedDate.month,
                                  _datePickedDate.day,
                                );
                              });
                            } else if (_model.datePicked != null) {
                              safeSetState(() {
                                _model.datePicked = getCurrentTimestamp;
                              });
                            }
                            FFAppState().fechanacimiento = _model.datePicked;
                            safeSetState(() {});
                          },
                          text: '',
                          icon: Icon(
                            Icons.date_range_rounded,
                            size: 30.0,
                          ),
                          options: FFButtonOptions(
                            width: 76.0,
                            height: 40.0,
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            iconPadding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 0.0, 0.0, 0.0),
                            color: FlutterFlowTheme.of(context).primary,
                            textStyle: FlutterFlowTheme.of(context)
                                .titleSmall
                                .override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                                  color: Colors.white,
                                  letterSpacing: 0.0,
                                  fontWeight: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontWeight,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                            borderSide: BorderSide(
                              color: Colors.transparent,
                              width: 1.0,
                            ),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 30.0, 70.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _model.nSensorTextController,
                          focusNode: _model.nSensorFocusNode,
                          onChanged: (_) => EasyDebounce.debounce(
                            '_model.nSeTextController',
                            Duration(milliseconds: 2000),
                            () async {
                              FFAppState().nombresensor =
                                  _model.nSensorTextController.text;
                              safeSetState(() {});
                            },
                          ),
                          autofocus: true,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Nombre sensor',
                            hintText: 'Nombre sensor',
                            hintStyle:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                          ),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                          keyboardType: TextInputType.text,
                          validator: _model.nSensorTextControllerValidator
                              .asValidator(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 30.0, 70.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _model.nGranjaTextController,
                          focusNode: _model.nGranjaFocusNode,
                          onChanged: (_) => EasyDebounce.debounce(
                            '_model.nGranjaTextController',
                            Duration(milliseconds: 2000),
                            () async {
                              FFAppState().nombregranja =
                                  _model.nGranjaTextController.text;
                              safeSetState(() {});
                            },
                          ),
                          autofocus: true,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Nombre granja',
                            hintText: 'Nombre granja',
                            hintStyle:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                          ),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                          keyboardType: TextInputType.text,
                          validator: _model.nGranjaTextControllerValidator
                              .asValidator(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(20.0, 30.0, 70.0, 0.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _model.ubicacionTextController,
                          focusNode: _model.ubicacionFocusNode,
                          onChanged: (_) => EasyDebounce.debounce(
                            '_model.ubicacionTextController',
                            Duration(milliseconds: 2000),
                            () async {
                              currentUserLocationValue =
                                  await getCurrentUserLocation(
                                      defaultLocation: LatLng(0.0, 0.0));
                              FFAppState().ubicacion =
                                  currentUserLocationValue!.toString();
                              safeSetState(() {});
                            },
                          ),
                          autofocus: true,
                          obscureText: false,
                          decoration: InputDecoration(
                            labelText: 'Direccion granja',
                            hintText: 'Direccion granja',
                            hintStyle:
                                FlutterFlowTheme.of(context).bodySmall.override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodySmall
                                            .fontStyle,
                                      ),
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .fontStyle,
                                    ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context).primary,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: FlutterFlowTheme.of(context)
                                    .primaryBackground,
                                width: 1.0,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4.0),
                                topRight: Radius.circular(4.0),
                              ),
                            ),
                          ),
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                          keyboardType: TextInputType.text,
                          validator: _model.ubicacionTextControllerValidator
                              .asValidator(context),
                        ),
                      ),
                    ],
                  ),
                ),
                // Replace your complete button widget with this enhanced version:
Padding(
  padding: EdgeInsetsDirectional.fromSTEB(0.0, 30.0, 0.0, 20.0),
  child: FFButtonWidget(
  onPressed: () async {
  GoRouter.of(context).prepareAuthEvent();

  // 👉 Cambia esto si quieres inyectarlo por env var
  const String baseUrl = 'https://tfg-proyecto-ithapp-production.up.railway.app';

  try {
    // 1) Recoger valores del formulario
    final email           = _model.usuarioTextController.text.trim();
    final password        = _model.claveTextController.text.trim();
    final nombre          = _model.nombreTextController.text.trim();
    final nombreGranja    = _model.nGranjaTextController.text.trim();
    final direccionGranja = _model.ubicacionTextController.text.trim();
    final nombreSensor    = _model.nSensorTextController.text.trim();
    final fechaPick       = _model.datePicked;

    // 2) Validaciones
    final List<String> missing = [];
    if (email.isEmpty)            missing.add('Email');
    if (password.isEmpty)         missing.add('Contraseña');
    if (nombre.isEmpty)           missing.add('Nombre');
    if (nombreGranja.isEmpty)     missing.add('Nombre de granja');
    if (direccionGranja.isEmpty)  missing.add('Dirección de granja');
    if (fechaPick == null)        missing.add('Fecha de nacimiento');
    if (nombreSensor.isEmpty)     missing.add('Nombre de sensor');

    if (missing.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Campos obligatorios faltantes: ${missing.join(', ')}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final emailOk = RegExp(r'^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
    if (!emailOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, introduce un email válido'), backgroundColor: Colors.red),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres'), backgroundColor: Colors.red),
      );
      return;
    }

    // 3) Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Registrando usuario...'),
          ],
        ),
      ),
    );

    final fechaNacimientoISO = DateFormat('yyyy-MM-dd').format(fechaPick!);

    // Logs de depuración
    debugPrint('📧 $email');
    debugPrint('👤 $nombre');
    debugPrint('🏡 $nombreGranja');
    debugPrint('📍 $direccionGranja');
    debugPrint('🎂 $fechaNacimientoISO');
    debugPrint('📡 $nombreSensor');

    // 4) Crear granja
    final granjaRes = await http.post(
      Uri.parse('$baseUrl/granjas'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre_granja': nombreGranja,
        'direccion'    : direccionGranja,
      }),
    );

    if (granjaRes.statusCode != 200 && granjaRes.statusCode != 201) {
      Navigator.pop(context);
      throw Exception('Error creando granja: ${granjaRes.statusCode} - ${granjaRes.body}');
    }

    final granjaJson = jsonDecode(granjaRes.body) as Map<String, dynamic>;
    final int idGranja = (granjaJson['id_granja'] as num?)?.toInt() ?? -1;
    if (idGranja <= 0) {
      Navigator.pop(context);
      throw Exception('No se pudo obtener el ID de la granja creada');
    }
    debugPrint('✅ Granja ID: $idGranja');

    // 5) Crear usuario (requiere id_granja)
    final usuarioRes = await http.post(
      Uri.parse('$baseUrl/usuarios'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre'          : nombre,
        'apellidos'       : '',                 // ajusta si tienes el campo
        'email'           : email,
        'fecha_nacimiento': fechaNacimientoISO, // yyyy-MM-dd
        'password'        : password,
        'id_granja'       : idGranja,
      }),
    );

    if (usuarioRes.statusCode != 200 && usuarioRes.statusCode != 201) {
      Navigator.pop(context);
      throw Exception('Error creando usuario: ${usuarioRes.statusCode} - ${usuarioRes.body}');
    }
    debugPrint('✅ Usuario creado: ${usuarioRes.body}');

    // 6) Crear sensor
    final sensorRes = await http.post(
      Uri.parse('$baseUrl/sensores'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nombre_sensor': nombreSensor,
        'id_granja'    : idGranja,
      }),
    );

    if (sensorRes.statusCode != 200 && sensorRes.statusCode != 201) {
      Navigator.pop(context);
      throw Exception('Error creando sensor: ${sensorRes.statusCode} - ${sensorRes.body}');
    }
    debugPrint('✅ Sensor creado: ${sensorRes.body}');

    // 7) Guardar en estado global (lo que ya usabas)
    FFAppState().email          = email;
    FFAppState().nombre         = nombre;
    FFAppState().fechanacimiento= fechaPick;
    FFAppState().nombregranja   = nombreGranja;
    FFAppState().ubicacion      = direccionGranja;
    safeSetState(() {});

    // 8) Cerrar loading
    Navigator.pop(context);

    // 9) Mensaje de éxito
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('¡Registro Exitoso!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Se ha registrado correctamente:'),
            const SizedBox(height: 10),
            Text('• Usuario: $nombre'),
            Text('• Email: $email'),
            Text('• Granja: $nombreGranja (ID: $idGranja)'),
            Text('• Sensor: $nombreSensor'),
          ],
        ),
        actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Continuar')),
        ],
      ),
    );

    // 10) Navegar
    context.pushNamedAuth(MedidasWidget.routeName, context.mounted);
  } catch (e) {
    if (Navigator.canPop(context)) Navigator.pop(context);
    debugPrint('❌ Error durante el registro: $e');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 10),
            Text('Error de Registro'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ha ocurrido un error durante el registro:'),
            const SizedBox(height: 10),
            Text(e.toString(), style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
            const SizedBox(height: 10),
            const Text('Por favor, verifica tu conexión a internet e inténtalo nuevamente.'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido')),
        ],
      ),
    );
  }
},
  text: 'Guardar',
  options: FFButtonOptions(
    width: 130.0,
    height: 40.0,
    padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
    iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
    color: FlutterFlowTheme.of(context).primary,
    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
      font: GoogleFonts.interTight(
        fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
        fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
      ),
      color: Colors.white,
      letterSpacing: 0.0,
      fontWeight: FlutterFlowTheme.of(context).titleSmall.fontWeight,
      fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
    ),
    borderSide: BorderSide(
      color: Colors.transparent,
      width: 1.0,
    ),
    borderRadius: BorderRadius.circular(8.0),
  ),
),
),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
