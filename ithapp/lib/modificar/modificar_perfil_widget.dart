// modificar_perfil_widget.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'modificar_perfil_model.dart';

class ModificarPerfilWidget extends StatefulWidget {
  const ModificarPerfilWidget({super.key});

  static const routeName = 'modificarPerfil';
  static const routePath = '/modificarPerfil';

  @override
  State<ModificarPerfilWidget> createState() => _ModificarPerfilWidgetState();
}

class _ModificarPerfilWidgetState extends State<ModificarPerfilWidget> {
  late ModificarPerfilModel _model;

  // Controladores
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final _farmNameCtrl = TextEditingController();
  final _farmAddrCtrl = TextEditingController();
  final _sensorNameCtrl = TextEditingController();

  final _currentPwdCtrl = TextEditingController();
  final _newPwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();

  DateTime? _birthDate;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ModificarPerfilModel());

    // Precargar datos
    _nameCtrl.text = currentUserDisplayName;
    _emailCtrl.text = currentUserEmail ?? '';

    _farmNameCtrl.text = FFAppState().nombregranja ?? '';
    _farmAddrCtrl.text = FFAppState().ubicacion ?? '';
    _sensorNameCtrl.text = FFAppState().nombresensor ?? '';

    _birthDate = FFAppState().fechanacimiento;
  }

  @override
  void dispose() {
    _model.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _farmNameCtrl.dispose();
    _farmAddrCtrl.dispose();
    _sensorNameCtrl.dispose();
    _currentPwdCtrl.dispose();
    _newPwdCtrl.dispose();
    _confirmPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickBirthDate() async {
    final initial = _birthDate ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      initialDate: initial,
    );
    if (picked != null) {
      setState(() => _birthDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  bool get _emailChanged =>
      (_emailCtrl.text.trim() != (currentUserEmail ?? '').trim());
  bool get _wantsPasswordChange =>
      _newPwdCtrl.text.isNotEmpty || _confirmPwdCtrl.text.isNotEmpty;

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      showSnackbar(context, 'Sesion no valida. Inicie sesion de nuevo.');
      return;
    }

    setState(() => _saving = true);

    try {
      // Reautenticacion si cambia email/clave
      if (_emailChanged || _wantsPasswordChange) {
        if (_currentPwdCtrl.text.isEmpty) {
          showSnackbar(context,
              'Para cambiar email/clave, introduce tu clave actual.');
          setState(() => _saving = false);
          return;
        }
        final cred = EmailAuthProvider.credential(
          email: currentUserEmail ?? _emailCtrl.text.trim(),
          password: _currentPwdCtrl.text,
        );
        await user.reauthenticateWithCredential(cred);
      }

      // Nombre visible
      final newDisplayName = _nameCtrl.text.trim();
      if (newDisplayName.isNotEmpty &&
          newDisplayName != currentUserDisplayName) {
        await user.updateDisplayName(newDisplayName);
      }

      // Email
      if (_emailChanged) {
        await user.updateEmail(_emailCtrl.text.trim());
      }

      // Clave
      if (_wantsPasswordChange) {
        if (_newPwdCtrl.text.length < 6) {
          throw FirebaseAuthException(
            code: 'weak-password',
            message: 'La nueva clave debe tener al menos 6 caracteres',
          );
        }
        if (_newPwdCtrl.text != _confirmPwdCtrl.text) {
          throw FirebaseAuthException(
            code: 'mismatch',
            message: 'La confirmacion de clave no coincide',
          );
        }
        await user.updatePassword(_newPwdCtrl.text);
      }

      // App state
      FFAppState().email = _emailCtrl.text.trim();
      FFAppState().nombre = _nameCtrl.text.trim();
      FFAppState().fechanacimiento = _birthDate;
      FFAppState().nombregranja = _farmNameCtrl.text.trim();
      FFAppState().ubicacion = _farmAddrCtrl.text.trim();
      FFAppState().nombresensor = _sensorNameCtrl.text.trim();
      setState(() {});

      showSnackbar(context, 'Perfil actualizado correctamente');
      if (mounted) Navigator.of(context).maybePop();
    } on FirebaseAuthException catch (e) {
      String msg = 'No se pudieron guardar los cambios';
      if (e.code == 'requires-recent-login') {
        msg = 'Por seguridad, vuelve a iniciar sesion y reintentalo.';
      } else if (e.code == 'email-already-in-use') {
        msg = 'El email ya esta en uso por otra cuenta.';
      } else if (e.code == 'invalid-email') {
        msg = 'El email no es valido.';
      } else if (e.code == 'wrong-password') {
        msg = 'La clave actual no es correcta.';
      } else if (e.code == 'weak-password') {
        msg = e.message ?? msg;
      }
      showSnackbar(context, msg);
    } catch (e) {
      showSnackbar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _dec(String label, {String? hint, Widget? suffixIcon}) {
    final t = FlutterFlowTheme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hint,
      // >>> Colores visibles en claro/oscuro
      labelStyle: t.bodySmall.copyWith(color: t.secondaryText),
      floatingLabelStyle: t.bodySmall.copyWith(color: t.primaryText),
      hintStyle: t.bodySmall.copyWith(color: t.secondaryText),
      filled: true,
      fillColor: t.secondaryBackground,
      enabledBorder: OutlineInputBorder(
        borderSide:
            BorderSide(color: t.primaryBackground, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0x00000000), width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          centerTitle: true,
          title: Text(
            'Modificar perfil',
            style: theme.headlineMedium.copyWith(color: Colors.white),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ----- Datos personales -----
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5F9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 6,
                              offset: Offset(0, 3))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Datos personales',
                            style: theme.titleMedium.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: _dec('Nombre completo',
                                hint: 'Tu nombre visible'),
                            style: theme.bodyMedium
                                .copyWith(color: theme.primaryText),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Introduce un nombre'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _dec('Email',
                                hint: 'usuario@dominio.com'),
                            style: theme.bodyMedium
                                .copyWith(color: theme.primaryText),
                            validator: (v) {
                              final val = v?.trim() ?? '';
                              if (val.isEmpty) return 'Introduce un email';
                              final re = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
                              if (!re.hasMatch(val)) return 'Email no valido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          InkWell(
                            onTap: _pickBirthDate,
                            child: IgnorePointer(
                              child: TextFormField(
                                decoration: _dec(
                                  'Fecha de nacimiento',
                                  hint: 'Selecciona una fecha',
                                  suffixIcon: const Icon(Icons.date_range),
                                ),
                                style: theme.bodyMedium
                                    .copyWith(color: theme.primaryText),
                                controller: TextEditingController(
                                  text: _birthDate == null
                                      ? ''
                                      : dateTimeFormat('d/M/y', _birthDate),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ----- Granja y sensor -----
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5F9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 6,
                              offset: Offset(0, 3))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Granja y sensor',
                            style: theme.titleMedium.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _farmNameCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: _dec('Nombre de la granja'),
                            style: theme.bodyMedium
                                .copyWith(color: theme.primaryText),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _farmAddrCtrl,
                            textInputAction: TextInputAction.next,
                            decoration: _dec('Direccion de la granja'),
                            style: theme.bodyMedium
                                .copyWith(color: theme.primaryText),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _sensorNameCtrl,
                            textInputAction: TextInputAction.done,
                            decoration: _dec('Nombre del sensor'),
                            style: theme.bodyMedium
                                .copyWith(color: theme.primaryText),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ----- Seguridad -----
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5F9),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x1A000000),
                              blurRadius: 6,
                              offset: Offset(0, 3))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seguridad',
                            style: theme.titleMedium.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Para cambiar email o clave es necesario introducir tu clave actual.',
                            style: theme.bodySmall
                                .copyWith(color: Colors.black),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _currentPwdCtrl,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            decoration: _dec('Clave actual'),
                            style: theme.bodyMedium
                                .copyWith(color: theme.primaryText),
                            validator: (v) {
                              if ((_emailChanged || _wantsPasswordChange) &&
                                  (v == null || v.isEmpty)) {
                                return 'Introduce tu clave actual para confirmar los cambios';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _newPwdCtrl,
                            obscureText: true,
                            textInputAction: TextInputAction.next,
                            decoration: _dec('Nueva clave (opcional)'),
                            style: theme.bodyMedium
                                .copyWith(color: theme.primaryText),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _confirmPwdCtrl,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: _dec('Repite la nueva clave'),
                            style: theme.bodyMedium
                                .copyWith(color: theme.primaryText),
                            validator: (v) {
                              if (_wantsPasswordChange &&
                                  v != _newPwdCtrl.text) {
                                return 'La confirmacion no coincide';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: FFButtonWidget(
                            onPressed: _saving ? null : () => Navigator.of(context).maybePop(),
                            text: 'Cancelar',
                            options: FFButtonOptions(
                              height: 48,
                              color: const Color(0x4C2797FF),
                              textStyle: theme.titleSmall.copyWith(color: Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FFButtonWidget(
                            onPressed: _saving ? null : _save,
                            text: 'Guardar cambios',
                            options: FFButtonOptions(
                              height: 48,
                              color: const Color(0xFF2797FF),
                              textStyle: theme.titleSmall.copyWith(color: Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            if (_saving)
              Container(
                color: Colors.black38,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
