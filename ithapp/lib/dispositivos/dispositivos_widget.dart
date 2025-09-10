/*  ──────────────────────────────────────────────
    Dispositivos – Edición de sensor
    - Botón para obtener dev_eui
    - Modo automático/manual con umbral ITH
    - PUT para actualizar sensor
    - POST downlink para aplicar cambios en el nodo
    ────────────────────────────────────────────── */

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

/* 🔧 API base */
const String apiBase = 'https://tfg-proyecto-ithapp-production.up.railway.app';

/* Rutas que usamos */
const String getLastDevEuiPathApi  = '/api/dev-eui-ultimo';
const String getLastDevEuiPathRoot = '/dev-eui-ultimo';
const String updateSensorPath      = '/api/sensores/actualizar';
const String downlinkPath          = '/api/downlink';

class DispositivosWidget extends StatefulWidget {
  const DispositivosWidget({super.key});

  static const String routeName = 'dispositivos';
  static const String routePath = '/dispositivos';

  @override
  State<DispositivosWidget> createState() => _DispositivosWidgetState();
}

class _DispositivosWidgetState extends State<DispositivosWidget> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  final _serieCtrl  = TextEditingController();   // dev_eui / nº de serie
  final _modeloCtrl = TextEditingController();
  final _areaCtrl   = TextEditingController();
  final _zonaCtrl   = TextEditingController();
  final _salaCtrl   = TextEditingController();

  bool   _saving = false;
  String _modo   = 'auto';   // 'auto' | 'manual'
  double _umbral = 75;

  @override
  void dispose() {
    _serieCtrl.dispose();
    _modeloCtrl.dispose();
    _areaCtrl.dispose();
    _zonaCtrl.dispose();
    _salaCtrl.dispose();
    super.dispose();
  }

  bool _camposValidos() =>
      _serieCtrl.text.trim().isNotEmpty &&
      _modeloCtrl.text.trim().isNotEmpty;

  /* ───── DEV_EUI (intenta /api/... y luego /...) ───── */
  Future<bool> _tryFetchDevEui(String path) async {
    final uri  = Uri.parse('$apiBase$path');
    final resp = await http.get(uri);
    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final dev  = (data['dev_eui'] ?? '').toString();
      if (dev.isNotEmpty) {
        setState(() => _serieCtrl.text = dev);
        return true;
      }
    }
    return false;
  }

  Future<void> _obtenerDevEui() async {
    try {
      final okApi  = await _tryFetchDevEui(getLastDevEuiPathApi);
      final okRoot = okApi ? true : await _tryFetchDevEui(getLastDevEuiPathRoot);
      if (okApi || okRoot) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ DEV_EUI obtenido.')),
        );
      } else {
        throw 'No se pudo obtener el DEV_EUI. Envía un uplink desde el nodo.';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ $e')),
      );
    }
  }

  /* ───── Downlink genérico (comando ASCII) ───── */
  Future<void> _enviarDownlink(String cmd) async {
    final dev = _serieCtrl.text.trim();
    if (dev.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica primero el DEV_EUI.')),
      );
      return;
    }
    try {
      final uri  = Uri.parse('$apiBase$downlinkPath');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'dev_eui': dev, 'cmd': cmd}),
      );
      if (resp.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('📡 Downlink enviado: $cmd')),
        );
      } else {
        throw 'HTTP ${resp.statusCode}';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Falló el downlink: $e')),
      );
    }
  }

  /* ───── Guardar y aplicar MODE/TH al nodo ───── */
  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();
int? _intOrNull(String s) => s.trim().isEmpty ? null : int.tryParse(s.trim());

Future<void> _guardarCambios() async {
  if (!_camposValidos()) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Completa, al menos, Nº de serie y Modelo.')),
    );
    return;
  }

  setState(() => _saving = true);

  final payload = {
    'dev_eui'    : _serieCtrl.text.trim().toUpperCase(),
    'modelo'     : _nullIfEmpty(_modeloCtrl.text),
    'area'       : _nullIfEmpty(_areaCtrl.text),
    'zona'       : _intOrNull(_zonaCtrl.text),       // null si vacío
    'sala'       : _nullIfEmpty(_salaCtrl.text),
    'modo'       : _modo,
    'umbral_ith' : _modo == 'auto' ? _umbral.round() : null,
  };

  try {
    final uri  = Uri.parse('$apiBase$updateSensorPath');
    final resp = await http.put(
      uri, headers: {'Content-Type':'application/json'}, body: jsonEncode(payload),
    );
    if (resp.statusCode != 200) throw 'HTTP ${resp.statusCode}';

    // Downlink opcional
    if (_modo == 'auto') {
      await _enviarDownlink('MODE=AUTO;TH=${_umbral.round()}');
    } else {
      await _enviarDownlink('MODE=MANUAL');
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Cambios guardados')),
    );
    Navigator.pop(context);
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error al guardar: $e')),
      );
    }
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    InputDecoration deco(String label, {Widget? suffix}) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: theme.primaryBackground,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.tertiary),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: theme.primary),
        borderRadius: BorderRadius.circular(8),
      ),
      suffixIcon: suffix,
    );

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.primaryBackground,

        appBar: AppBar(
          backgroundColor: theme.primary,
          elevation: 2,
          leading: FlutterFlowIconButton(
            borderRadius: 8,
            buttonSize: 40,
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('Editar sensor',
              style: TextStyle(color: Colors.white, fontSize: 22)),
        ),

        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  // ── Información del dispositivo
                  _Panel(
                    title: 'Información del dispositivo',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _serieCtrl,
                          decoration: deco(
                            'Número de serie (DEV_EUI)',
                            suffix: IconButton(
                              tooltip: 'Obtener automáticamente',
                              icon: const Icon(Icons.qr_code_2_outlined),
                              onPressed: _obtenerDevEui,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _modeloCtrl,
                          decoration: deco('Modelo'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Ubicación
                  _Panel(
                    title: 'Ubicación',
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _areaCtrl,
                          decoration: deco('Granja'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              width: 110,
                              child: TextFormField(
                                controller: _zonaCtrl,
                                keyboardType: TextInputType.text,
                                decoration: deco('Zona'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _salaCtrl,
                                decoration: deco('Sala / Habitación'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Modo de operación
                  _Panel(
                    title: 'Modo de operación',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RadioListTile<String>(
                          value: 'auto',
                          groupValue: _modo,
                          title: const Text('Automático (activa ventilador por ITH)'),
                          subtitle: const Text('Se encenderá cuando el ITH sea ≥ umbral.'),
                          onChanged: (v) => setState(() => _modo = v!),
                        ),
                        if (_modo == 'auto') ...[
                          const SizedBox(height: 8),
                          Text('Umbral ITH: ${_umbral.round()}',
                              style: GoogleFonts.inter(fontSize: 14)),
                          Slider(
                            value: _umbral,
                            onChanged: (v) => setState(() => _umbral = v),
                            min: 60, max: 90, divisions: 30,
                          ),
                        ],
                        const Divider(height: 24),
                        RadioListTile<String>(
                          value: 'manual',
                          groupValue: _modo,
                          title: const Text('Manual'),
                          subtitle: const Text('Control inmediato desde la app.'),
                          onChanged: (v) => setState(() => _modo = v!),
                        ),
                        if (_modo == 'manual') ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.power_settings_new),
                                  label: const Text('Encender'),
                                  onPressed: () => _enviarDownlink('ACTIVATE'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.power_off),
                                  label: const Text('Apagar'),
                                  onPressed: () => _enviarDownlink('DEACTIVATE'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_saving)
              Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),

        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FFButtonWidget(
                text: 'Guardar cambios',
                onPressed: _guardarCambios,
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 50,
                  color: theme.success,
                  textStyle: theme.titleSmall.override(
                    fontFamily: 'InterTight',
                    color: Colors.white,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              const SizedBox(height: 12),
              FFButtonWidget(
                text: 'Cancelar',
                onPressed: () => Navigator.pop(context),
                options: FFButtonOptions(
                  width: double.infinity,
                  height: 50,
                  color: theme.alternate,
                  textStyle: theme.titleSmall,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        boxShadow: const [
          BoxShadow(blurRadius: 4, color: Color(0x20000000), offset: Offset(0, 2))
        ],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.titleMedium.override(
                fontFamily: 'InterTight',
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
