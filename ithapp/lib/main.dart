import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ithapp/services/push_notifications_service.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import '/auth/firebase_auth/firebase_user_provider.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';

import 'package:provider/provider.dart';

/* ─────────── Notificaciones locales ─────────── */
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _initLocalNotifications() async {
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);
}

/* ─────────── MAIN ─────────── */
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PushNotificationService.initializeApp();
  /*await _initLocalNotifications();

  // Android 13+ permiso runtime
  if (Platform.isAndroid) {
    final status = await Permission.notification.status;
    if (!status.isGranted) await Permission.notification.request();
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
*/
  await initFirebase();
  await FlutterFlowTheme.initialize();

  final appState = FFAppState();
  await appState.initializePersistedState();

  runApp(ChangeNotifierProvider(
    create: (_) => appState,
    child: const MyApp(),
  ));
}

/* ─────────── APP ROOT ─────────── */
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late final AppStateNotifier _appStateNotifier;
  late final GoRouter _router;

  // Métodos que usa flutter_flow_util.dart
  String getRoute([RouteMatch? match]) {
    final RouteMatch last =
        match ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList list = last is ImperativeRouteMatch
        ? last.matches
        : _router.routerDelegate.currentConfiguration;
    return list.uri.toString();
  }

  List<String> getRouteStack() => _router
      .routerDelegate.currentConfiguration.matches
      .map((m) => getRoute(m))
      .toList();

  @override
  void initState() {
    super.initState();

    PushNotificationService.messagesStream.listen((message) {

      print('Myapp: $message');

    });

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);

    ithappFirebaseUserStream().listen(_appStateNotifier.update);
    jwtTokenStream.listen((_) {});

    Future.delayed(
      const Duration(milliseconds: 1000),
      _appStateNotifier.stopShowingSplashImage,
    );
  }

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
    FlutterFlowTheme.saveThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'ithapp',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(brightness: Brightness.light, useMaterial3: false),
      darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: false),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
