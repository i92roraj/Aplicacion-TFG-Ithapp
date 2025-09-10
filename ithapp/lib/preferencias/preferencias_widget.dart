import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class PreferenciasWidget extends StatefulWidget {
  const PreferenciasWidget({super.key});

  static const String routeName = 'preferencias';
  static const String routePath = '/preferencias';

  @override
  State<PreferenciasWidget> createState() => _PreferenciasWidgetState();
}

class _PreferenciasWidgetState extends State<PreferenciasWidget> {
  // Claves de preferencias
  static const _kTheme = 'pref_theme'; // system | light | dark
  static const _kUnits = 'pref_units'; // C | F
  static const _kPush  = 'pref_push';  // bool
  static const _kAnalytics = 'pref_analytics'; // bool
  static const _kLocale = 'pref_locale'; // es | en (placeholder)

  // Estado en memoria
  String _theme = 'system';
  String _units = 'C';
  bool _pushEnabled = false;
  bool _analytics = false;
  String _locale = 'es';

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _theme = p.getString(_kTheme) ?? 'system';
      _units = p.getString(_kUnits) ?? 'C';
      _pushEnabled = p.getBool(_kPush) ?? false;
      _analytics = p.getBool(_kAnalytics) ?? false;
      _locale = p.getString(_kLocale) ?? 'es';
      _loading = false;
    });
  }

  Future<void> _save<T>(String key, T value) async {
    final p = await SharedPreferences.getInstance();
    if (value is String) await p.setString(key, value);
    if (value is bool) await p.setBool(key, value);
  }

  Future<void> _applyTheme(String v) async {
    setState(() => _theme = v);
    await _save(_kTheme, v);
    switch (v) {
      case 'light':
        setDarkModeSetting(context, ThemeMode.light);
        break;
      case 'dark':
        setDarkModeSetting(context, ThemeMode.dark);
        break;
      default:
        setDarkModeSetting(context, ThemeMode.system);
    }
  }

  Future<void> _togglePush(bool value) async {
    // Pedir permiso solo al activar
    if (value && Platform.isAndroid) {
      final status = await Permission.notification.status;
      if (!status.isGranted) {
        final req = await Permission.notification.request();
        if (!req.isGranted) {
          // No concedido → revertimos y avisamos
          showSnackbar(context, 'Permiso de notificaciones denegado.');
          setState(() => _pushEnabled = false);
          await _save(_kPush, false);
          return;
        }
      }
    }
    setState(() => _pushEnabled = value);
    await _save(_kPush, value);
    // Aquí, si usas tu servicio de FCM, suscríbete/desuscríbete:
    // if (value) await PushNotificationService.enable();
    // else await PushNotificationService.disable();
  }

  Future<void> _clearCache() async {
    await DefaultCacheManager().emptyCache();
    showSnackbar(context, 'Caché vaciada.');
  }

  Future<void> _resetAll() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kTheme);
    await p.remove(_kUnits);
    await p.remove(_kPush);
    await p.remove(_kAnalytics);
    await p.remove(_kLocale);
    await _loadPrefs();
    await _applyTheme('system');
    showSnackbar(context, 'Preferencias restablecidas.');
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.primaryText.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.titleMedium.copyWith(
                color: theme.primaryText,
                fontWeight: FontWeight.w700,
              )),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle, style: theme.bodySmall),
          ],
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferencias'),
        backgroundColor: theme.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: theme.primaryBackground,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                // Apariencia
                _sectionCard(
                  title: 'Apariencia',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.color_lens_outlined),
                      title: const Text('Tema'),
                      subtitle: Text(
                        _theme == 'system'
                            ? 'Sistema'
                            : _theme == 'light'
                                ? 'Claro'
                                : 'Oscuro',
                      ),
                      trailing: DropdownButton<String>(
                        value: _theme,
                        onChanged: (v) => _applyTheme(v!),
                        items: const [
                          DropdownMenuItem(
                              value: 'system', child: Text('Sistema')),
                          DropdownMenuItem(
                              value: 'light', child: Text('Claro')),
                          DropdownMenuItem(
                              value: 'dark', child: Text('Oscuro')),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.thermostat_outlined),
                      title: const Text('Unidades de temperatura'),
                      subtitle: Text(_units == 'C' ? 'Celsius (°C)' : 'Fahrenheit (°F)'),
                      trailing: DropdownButton<String>(
                        value: _units,
                        onChanged: (v) async {
                          setState(() => _units = v!);
                          await _save(_kUnits, _units);
                        },
                        items: const [
                          DropdownMenuItem(value: 'C', child: Text('°C')),
                          DropdownMenuItem(value: 'F', child: Text('°F')),
                        ],
                      ),
                    ),
                  ],
                ),

                // Notificaciones
                _sectionCard(
                  title: 'Notificaciones',
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.notifications_active_outlined),
                      title: const Text('Notificaciones push'),
                      subtitle: const Text('Permite recibir avisos en segundo plano'),
                      value: _pushEnabled,
                      onChanged: _togglePush,
                    ),
                  ],
                ),

                // Privacidad
                _sectionCard(
                  title: 'Privacidad',
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.insights_outlined),
                      title: const Text('Analíticas de uso'),
                      subtitle: const Text('Ayuda a mejorar la app enviando métricas anónimas'),
                      value: _analytics,
                      onChanged: (v) async {
                        setState(() => _analytics = v);
                        await _save(_kAnalytics, v);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.lock_open_outlined),
                      title: const Text('Abrir ajustes del sistema'),
                      subtitle: const Text('Gestiona permisos como notificaciones o ubicación'),
                      onTap: openAppSettings,
                    ),
                  ],
                ),

                // Idioma
                _sectionCard(
                  title: 'Idioma',
                  subtitle:
                      'Actualmente la app está en español. Puedes dejarlo configurado para futuras ampliaciones.',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.language_outlined),
                      title: const Text('Idioma de la app'),
                      trailing: DropdownButton<String>(
                        value: _locale,
                        onChanged: (v) async {
                          setState(() => _locale = v!);
                          await _save(_kLocale, _locale);
                          showSnackbar(context, 'Idioma guardado (placeholder).');
                        },
                        items: const [
                          DropdownMenuItem(value: 'es', child: Text('Español')),
                          DropdownMenuItem(value: 'en', child: Text('Inglés')),
                        ],
                      ),
                    ),
                  ],
                ),

                // Sistema
                _sectionCard(
                  title: 'Sistema',
                  children: [
                    ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: const Text('Vaciar caché'),
                      onTap: _clearCache,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore_outlined),
                      title: const Text('Restablecer ajustes'),
                      onTap: _resetAll,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info_outline),
                      title: const Text('Sobre la app'),
                      subtitle: const Text('ithapp — compilación local'),
                      onTap: () {
                        showAboutDialog(
                          context: context,
                          applicationName: 'ithapp',
                          applicationVersion: '1.0.0',
                          applicationIcon: const FlutterLogo(size: 36),
                          children: const [
                            SizedBox(height: 8),
                            Text('Aplicación de monitorización (demo).'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
