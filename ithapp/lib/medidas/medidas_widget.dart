import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ithapp/main.dart';
import 'package:ithapp/modificar/modificar_perfil_widget.dart';
import 'package:ithapp/perfil/administrar_perfil_widget.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/flutter_flow/random_data_util.dart' as random_data;
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'medidas_model.dart';
export 'medidas_model.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:printing/printing.dart';  // ruta del archivo anterior
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '/services/local_notifications_service.dart';




class MedidasWidget extends StatefulWidget {
  const MedidasWidget({super.key});

  static String routeName = 'medidas';
  static String routePath = '/medidas';

  @override
  State<MedidasWidget> createState() => _MedidasWidgetState();
}

class _MedidasWidgetState extends State<MedidasWidget> {
  late MedidasModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? ultimaFechaMedicion;
  late final Stream<int> _ticker$;  

late final Stream<double?> temperatura$;
late final Stream<int?>     humedad$;
late final Stream<double?>  ith$;
late final Stream<DateTime> ultimaFecha$;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => MedidasModel());

  _ticker$ = Stream.periodic(const Duration(seconds: 1), (i) => i);

  // Cada 10 s llama a la API y emite el resultado
  temperatura$ = Stream.periodic(
    const Duration(seconds: 10),
    (_) => fetchTemperatura(),
  ).asyncMap((fut) => fut);          // Future → Stream<double?>

  humedad$ = Stream.periodic(
    const Duration(seconds: 10),
    (_) => fetchHumedad(),
  ).asyncMap((fut) => fut);

  ith$ = Stream.periodic(
    const Duration(seconds: 10),
    (_) => fetchITH(),
  ).asyncMap((fut) => fut);

  // Momento en que llega cada nueva medición
  ultimaFecha$ = Stream.periodic(
    const Duration(seconds: 10),
    (_) => DateTime.now(),
  );



    _model.switchValue1 = true;
    _model.switchValue2 = true;
    _model.switchValue3 = true;
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  // ===============================
//  API (Railway) + TTN constantes
// ===============================
static const String kApiBase =
    'https://tfg-proyecto-ithapp-production.up.railway.app';

// (Si quieres moverlo a variables seguras, podemos leerlos desde .env)
static const String TTN_APPLICATION_ID = 'tfg-ganadera';
static const String TTN_DEVICE_ID      = 'a8610a3436375f17';
static const String TTN_API_KEY        = 'NNSXS.WQON3QD7L4CIKTSIIJCILESHFTOMKTD5KRQFXYY.ARSFA7JJBD7LBQ3YFGFFFSITNX7TYF3OPPTLPSDYELNDKPXYM5SA';
static const String TTN_BASE_URL       = 'https://eu1.cloud.thethings.network';

// ===================================================================
//  Downlink a TTN (sin cambios funcionales, solo limpieza de logs)
// ===================================================================
Future<bool> enviarDownlinkTTN({
  required String payload,
  int puerto = 80,
  bool confirmado = false,
}) async {
  try {
    final url = Uri.parse(
      '$TTN_BASE_URL/api/v3/as/applications/$TTN_APPLICATION_ID/devices/$TTN_DEVICE_ID/down/push',
    );

    final headers = {
      'Authorization': 'Bearer $TTN_API_KEY',
      'Content-Type': 'application/json',
      'User-Agent': 'Flutter App'
    };

    final payloadBase64 = base64Encode(utf8.encode(payload));
    final body = jsonEncode({
      'downlinks': [
        {
          'f_port': puerto,
          'frm_payload': payloadBase64,
          'confirmed': confirmado,
          'priority': 'NORMAL',
        }
      ]
    });

    debugPrint('🔄 Enviando downlink a TTN: $url');

    final resp = await http.post(url, headers: headers, body: body);
    if (resp.statusCode == 200) {
      debugPrint('✅ Downlink enviado OK: ${resp.body}');
      return true;
    } else {
      debugPrint('❌ Error TTN ${resp.statusCode}: ${resp.body}');
      return false;
    }
  } catch (e) {
    debugPrint('❌ Excepción TTN: $e');
    return false;
  }
}

// ==========================================================
//  Auxiliar: lee /mediciones una sola vez y cachea la fecha
// ==========================================================
Future<Map<String, dynamic>?> _getUltimaMedicion() async {
  try {
    final res = await http.get(
      Uri.parse('$kApiBase/mediciones'),
      headers: {'Accept': 'application/json'},
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data is Map<String, dynamic>) {
        // actualizar la marca temporal con la fecha del servidor si viene
        final fechaRaw = data['fecha'];
        if (fechaRaw is String) {
          try {
            final parsed = DateTime.parse(fechaRaw).toLocal();
            if (mounted) setState(() => ultimaFechaMedicion = parsed);
          } catch (_) {
            if (mounted) setState(() => ultimaFechaMedicion = DateTime.now());
          }
        } else {
          if (mounted) setState(() => ultimaFechaMedicion = DateTime.now());
        }
        return data;
      }
    } else if (res.statusCode == 404) {
      // No hay datos aún
      debugPrint('ℹ️ No hay datos disponibles');
    } else {
      debugPrint('❌ HTTP ${res.statusCode}: ${res.body}');
    }
  } catch (e) {
    debugPrint('❌ Error _getUltimaMedicion: $e');
  }
  return null;
}

// ============================================
//  Lecturas (usan la auxiliar para no duplicar)
// ============================================
Future<double?> fetchTemperatura() async {
  final data = await _getUltimaMedicion();
  if (data == null) return null;
  final temp = data['temperatura'];
  return temp is num ? temp.toDouble() : null;
}

Future<int?> fetchHumedad() async {
  final data = await _getUltimaMedicion();
  if (data == null) return null;
  final hum = data['humedad'];
  // tu backend devuelve float; lo normalizamos a int para tu UI
  return hum is num ? hum.round() : null;
}

Future<void> mostrarNotificacionITHAlto(double ith) async {
  const android = AndroidNotificationDetails(
    'ith_channel_id',
    'ITH Alertas',
    channelDescription: 'Notificaciones por ITH alto',
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
  );
  await flutterLocalNotificationsPlugin.show(
    0,
    '⚠️ Estrés térmico alto',
    'El ITH es $ith. Toma medidas preventivas.',
    const NotificationDetails(android: android),
  );
}

Future<double?> fetchITH() async {
  final data = await _getUltimaMedicion();
  if (data == null) return null;

  final ithNum = data['ith'];
  if (ithNum is num) {
    final ith = ithNum.toDouble();
    if (ith >= 75) {
      await mostrarNotificacionITHAlto(ith);
    }
    return ith;
  }
  return null;
}

// =====================================================
//  Generación de PDF (sin cambios funcionales de estilo)
// =====================================================
Future<void> _generarYDescargarPdf({
  required double temperatura,
  required int humedad,
  required double ith,
  required DateTime fecha,
}) async {
  final pdf = pw.Document();

  const kPrimary   = PdfColor.fromInt(0xFF3A86FF);
  const kSecondary = PdfColor.fromInt(0xFF00B4D8);
  const kGrey      = PdfColor.fromInt(0xFF777777);

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [kPrimary, kSecondary],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                'Informe de condiciones ambientales',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 24),
            pw.Text(
              'Generado: ${DateFormat('dd/MM/yyyy  –  HH:mm').format(fecha)}',
              style: pw.TextStyle(color: kGrey, fontSize: 12),
            ),
            pw.Divider(),
            pw.SizedBox(height: 12),
            pw.Table(
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(1),
              },
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              children: [
                _dataRow('Temperatura', '${temperatura.toStringAsFixed(1)} °C'),
                _dataRow('Humedad',     '$humedad %'),
                _dataRow('Índice TH',   ith.toStringAsFixed(1)),
              ],
            ),
            pw.Spacer(),
            pw.Divider(),
            pw.Text(
              'Generado automáticamente por la app IthApp.',
              style: pw.TextStyle(fontSize: 10, color: kGrey),
            ),
          ],
        );
      },
    ),
  );

  final bytes = await pdf.save();
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}/informe_ith_${DateTime.now().millisecondsSinceEpoch}.pdf',
  );
  await file.writeAsBytes(bytes);
  await OpenFilex.open(file.path);
}

pw.TableRow _dataRow(String label, String value) => pw.TableRow(
  children: [
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Text(
        label,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
      ),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Text(value, style: const pw.TextStyle(fontSize: 14)),
    ),
  ],
);

// =====================================================
//  Menú lateral (sin cambios, limpieza mínima de código)
// =====================================================
Widget _buildMenuLateral(BuildContext context) {
  final nombre = currentUserDisplayName;
  final correo = currentUserEmail ?? '';

  return Drawer(
    child: SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF3A86FF)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.account_circle, size: 64, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  nombre.isNotEmpty ? nombre : correo,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                if (nombre.isNotEmpty)
                  Text(correo,
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Administrar perfil'),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(AdministrarPerfilWidget.routeName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modificar perfil'),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(ModificarPerfilWidget.routeName);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
            onTap: () async {
              Navigator.pop(context);
              await authManager.signOut();
              context.goNamed(LoginWidget.routeName);
            },
          ),
        ],
      ),
    ),
  );
}





  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        endDrawer: _buildMenuLateral(context),
        appBar: AppBar(
          backgroundColor: Color(0xFF3A86FF),
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderRadius: 8.0,
            buttonSize: 40.0,
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
            'Monitor ambiental',
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
          actions: [
            IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
          ),
          
          ],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    width: double.infinity,
                    height: 200.0,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8.0,
                          color: Color(0x40000000),
                          offset: Offset(
                            0.0,
                            4.0,
                          ),
                        )
                      ],
                      gradient: LinearGradient(
                        colors: [Color(0xFF3A86FF), Color(0xFF4361EE)],
                        stops: [0.0, 1.0],
                        begin: AlignmentDirectional(1.0, -1.0),
                        end: AlignmentDirectional(-1.0, 1.0),
                      ),
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Condiciones Actuales',
                          style:
                              FlutterFlowTheme.of(context).titleLarge.override(
                                    font: GoogleFonts.outfit(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleLarge
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    fontSize: 22.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleLarge
                                        .fontStyle,
                                  ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            /// ───────── Temperatura ─────────
Column(
  mainAxisSize: MainAxisSize.max,
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    const Icon(Icons.thermostat, color: Colors.white, size: 40),
    StreamBuilder<double?>(
      stream: temperatura$,
      builder: (context, snapshot) {
        // Mientras espera la primera lectura
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: Colors.white);
        }

        // Si vino con error (por ejemplo, caída del server)
        if (snapshot.hasError) {
          return const Text('N/A',
              style: TextStyle(color: Colors.white, fontSize: 32));
        }

        final double temp = snapshot.data!;
        return Text(
          '${temp.toStringAsFixed(1)}°C',
          style: FlutterFlowTheme.of(context).headlineLarge.override(
                font: GoogleFonts.outfit(),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        );
      },
    ),
    Text(
      'Temperatura',
      style: FlutterFlowTheme.of(context).bodyMedium.override(
            font: GoogleFonts.manrope(),
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
    ),
  ],
),

                           Column(
  mainAxisSize: MainAxisSize.max,
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    const Icon(Icons.water_drop, color: Colors.white, size: 40),
    StreamBuilder<int?>(
      stream: humedad$,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: Colors.white);
        }

        if (snapshot.hasError) {
          return const Text('N/A',
              style: TextStyle(color: Colors.white, fontSize: 32));
        }

        final int hum = snapshot.data!;
        return Text(
          '$hum%',
          style: FlutterFlowTheme.of(context).headlineLarge.override(
                font: GoogleFonts.outfit(),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
        );
      },
    ),
    Text(
      'Humedad',
      style: FlutterFlowTheme.of(context).bodyMedium.override(
            font: GoogleFonts.manrope(),
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
    ),
  ],
),
                            Column(
  mainAxisSize: MainAxisSize.max,
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    const Icon(Icons.speed, color: Colors.white, size: 40),
    StreamBuilder<double?>(
      stream: ith$,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator(color: Colors.white);
        }

        if (snapshot.hasError) {
          return const Text(
            'N/A',
            style: TextStyle(color: Colors.white, fontSize: 32),
          );
        }

        final double ith = snapshot.data!;

        // Decidir color según el rango
        Color ithColor;
        if (ith <= 70) {
          ithColor = Colors.green;
        } else if (ith <= 75) {
          ithColor = Colors.amberAccent;
        } else {
          ithColor = Colors.redAccent;
        }

        return Text(
          ith.toStringAsFixed(1),
          style: FlutterFlowTheme.of(context).headlineLarge.override(
                font: GoogleFonts.outfit(),
                fontWeight: FontWeight.bold,
                color: ithColor,
              ),
        );
      },
    ),
    Text(
      'ITH',
      style: FlutterFlowTheme.of(context).bodyMedium.override(
            font: GoogleFonts.manrope(),
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
    ),
  ],
),
                          ].divide(SizedBox(width: 16.0)),
                        ),
                      ].divide(SizedBox(height: 16.0)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFF0F5F9),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4.0,
                            color: Color(0x20000000),
                            offset: Offset(
                              0.0,
                              2.0,
                            ),
                          )
                        ],
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estado del Sistema',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: Colors.black,
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Estado del dispositivo:',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF161C24),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Text(
                                  'Conectado',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF27AE52),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                            Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    const Text(
      'Última actualización:',
      style: TextStyle(
        color: Color(0xFF161C24),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    ),

    /// ───────── Tiempo transcurrido ─────────
    StreamBuilder<int>(
      stream: _ticker$,                // se actualiza cada 1 s
      builder: (context, _) {
        // Si aún no hay datos recibidos
        if (ultimaFechaMedicion == null) {
          return const Text(
            '—',
            style: TextStyle(
              color: Color(0xFF161C24),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          );
        }

        final diff = DateTime.now().difference(ultimaFechaMedicion!);

        String tiempo;
        if (diff.inSeconds < 60) {
          tiempo = 'hace ${diff.inSeconds}s';
        } else if (diff.inMinutes < 60) {
          tiempo = 'hace ${diff.inMinutes} min';
        } else if (diff.inHours < 24) {
          tiempo = 'hace ${diff.inHours} h';
        } else {
          tiempo = 'hace ${diff.inDays} d';
        }

        return Text(
          tiempo,
          style: const TextStyle(
            color: Color(0xFF161C24),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    ),
  ],
),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Estado de alertas:',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF161C24),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Text(
                                  'Activas',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF27AE52),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFF0F5F9),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4.0,
                            color: Color(0x20000000),
                            offset: Offset(
                              0.0,
                              2.0,
                            ),
                          )
                        ],
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Acciones',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: Colors.black,
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                            ),
                            // ───────────────────  ACCIONES  ───────────────────
// ───────── Acciones ─────────
Column(
  children: [
    // Fila 1 : Generar Informe + Activar Dispositivo
    Row(
      children: [
        Expanded(
          child: FFButtonWidget(
            onPressed: () async {
              final t = await fetchTemperatura() ?? 0;
          final h = await fetchHumedad() ?? 0;
          final i = await fetchITH() ?? 0;
          await _generarYDescargarPdf(
            temperatura: t,
            humedad: h,
            ith: i,
            fecha: DateTime.now(),
          );
            },
            text: 'Generar Informe',
            options: FFButtonOptions(
              height: 50,
              color: const Color(0xFF2797FF),
              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                    font: GoogleFonts.manrope(),
                    color: Colors.white,
                  ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(width: 12),          // separación
        Expanded(
          child: FFButtonWidget(
            onPressed: () async {
               await enviarDownlinkTTN(payload: 'ACTIVATE', puerto: 80, confirmado: false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dispositivo activado')),
          );
            },
            text: 'Activar Dispositivo',
            options: FFButtonOptions(
              height: 50,
              color: const Color(0x4C2797FF),
              textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                    font: GoogleFonts.manrope(),
                    color: Colors.white,
                  ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    ),

    const SizedBox(height: 12),

    // Fila 2 : Desactivar Dispositivo (centrado)
    Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6, // 60 % del ancho
        child: FFButtonWidget(
          onPressed: () async {
            await enviarDownlinkTTN(payload: 'DEACTIVATE', puerto: 80, confirmado: false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dispositivo desactivado')),
          );
          },
          text: 'Desactivar Dispositivo',
          options: FFButtonOptions(
            height: 50,
            color: Colors.red.shade700,
            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                  font: GoogleFonts.manrope(),
                  color: Colors.white,
                ),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    ),
  ],
),

// ───────────────────────────────────────────────────

                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xFFF0F5F9),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 4.0,
                            color: Color(0x20000000),
                            offset: Offset(
                              0.0,
                              2.0,
                            ),
                          )
                        ],
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configuración de Alertas',
                              style: FlutterFlowTheme.of(context)
                                  .titleMedium
                                  .override(
                                    font: GoogleFonts.manrope(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleMedium
                                          .fontStyle,
                                    ),
                                    color: Colors.black,
                                    fontSize: 16.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Alertas de temperatura',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF161C24),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Switch(
                                  value: _model.switchValue1!,
                                  onChanged: (newValue) async {
                                    safeSetState(
                                        () => _model.switchValue1 = newValue!);
                                  },
                                  activeColor: Color(0xFF2797FF),
                                  activeTrackColor: Color(0x4C2797FF),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Umbral de temperatura:',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF161C24),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Text(
                                  '30°C',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF161C24),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Alertas de humedad',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF161C24),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Switch(
                                  value: _model.switchValue2!,
                                  onChanged: (newValue) async {
                                    safeSetState(
                                        () => _model.switchValue2 = newValue!);
                                  },
                                  activeColor: Color(0xFF2797FF),
                                  activeTrackColor: Color(0x4C2797FF),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Umbral de humedad:',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF161C24),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Text(
                                  '80%',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF161C24),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Alertas de ITH',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF161C24),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Switch(
                                  value: _model.switchValue3!,
                                  onChanged: (newValue) async {
                                    safeSetState(
                                        () => _model.switchValue3 = newValue!);
                                  },
                                  activeColor: Color(0xFF2797FF),
                                  activeTrackColor: Color(0x4C2797FF),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Umbral de ITH:',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w500,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF161C24),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                                Text(
                                  '75',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                        color: Color(0xFF161C24),
                                        fontSize: 14.0,
                                        letterSpacing: 0.0,
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                ),
                              ],
                            ),
                            FFButtonWidget(
                              onPressed: () async {

                                 context.pushNamed(DispositivosWidget.routeName);



                                await MedicionesRecord.collection
                                    .doc()
                                    .set(createMedicionesRecordData(
                                      id: random_data.randomInteger(0, 100),
                                      temperatura: FFAppState().cp.toDouble(),
                                      humedad: FFAppState().cp.toDouble(),
                                      ith: FFAppState().cp.toDouble(),
                                      idGranja:
                                          random_data.randomInteger(0, 10),
                                    ));
                              },
                              text: 'Configuración del sensor',
                              options: FFButtonOptions(
                                width: double.infinity,
                                height: 50.0,
                                padding: EdgeInsets.all(8.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: Color(0xFF27AE52),
                                textStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .override(
                                      font: GoogleFonts.manrope(
                                        fontWeight: FontWeight.w500,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .titleSmall
                                            .fontStyle,
                                      ),
                                      color: Colors.white,
                                      fontSize: 14.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                elevation: 2.0,
                                borderSide: BorderSide(
                                  color: Colors.transparent,
                                ),
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                          ].divide(SizedBox(height: 16.0)),
                        ),
                      ),
                    ),
                  ),
                ].divide(SizedBox(height: 24.0)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
