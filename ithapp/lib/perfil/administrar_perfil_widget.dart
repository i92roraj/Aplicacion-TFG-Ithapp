/*  administrar_perfil_widget.dart  */
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ithapp/flutter_flow/flutter_flow_util.dart';
import 'package:ithapp/preferencias/preferencias_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ithapp/modificar/modificar_perfil_widget.dart';


class AdministrarPerfilWidget extends StatefulWidget {
  const AdministrarPerfilWidget({super.key});

  static const String routeName = 'administrarPerfil';
  static const String routePath  = '/administrar-perfil';

  @override
  State<AdministrarPerfilWidget> createState() =>
      _AdministrarPerfilWidgetState();
}

class _AdministrarPerfilWidgetState extends State<AdministrarPerfilWidget> {
  final _user   = FirebaseAuth.instance.currentUser!;
  bool  _saving = false;

  /// ruta local de la foto (persistida en SharedPreferences)
  String? _localPhotoPath;

  @override
  void initState() {
    super.initState();
    _cargarFotoGuardada();
  }

  /* ───────── Cargar la ruta almacenada ───────── */
  Future<void> _cargarFotoGuardada() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _localPhotoPath = prefs.getString('perfil_foto_local'));
  }

  /* ───────── Cambiar foto (local) ───────── */
  Future<void> _cambiarFoto() async {
    final picker      = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => _saving = true);

    try {
      // Copiamos la imagen al directorio de la app
      final dir        = await getApplicationDocumentsDirectory();
      final filename   = 'perfil_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final savedPath  = p.join(dir.path, filename);
      await File(file.path).copy(savedPath);

      // Persistimos la ruta local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('perfil_foto_local', savedPath);

      setState(() => _localPhotoPath = savedPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto actualizada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
  /* ─────────────────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    final ImageProvider avatarProvider;
    if (_localPhotoPath != null) {
      avatarProvider = FileImage(File(_localPhotoPath!));
    } else if (_user.photoURL != null) {
      avatarProvider = NetworkImage(_user.photoURL!);
    } else {
      avatarProvider = const AssetImage('assets/images/favicon.png');
    }

    return Scaffold(
      appBar: AppBar(title: Text(_user.displayName ?? 'Mi perfil')),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(radius: 60, backgroundImage: avatarProvider),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white),
                        onPressed: _saving ? null : _cambiarFoto,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _user.displayName?.isNotEmpty == true
                      ? _user.displayName!
                      : _user.email ?? '',
                  style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 32),

             ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Modificar perfil'),
            onTap: () {
              Navigator.pop(context);
              context.pushNamed(ModificarPerfilWidget.routeName);
            },
          ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Preferencias'),
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed(PreferenciasWidget.routeName);

                }, 
              ),
              ListTile(
                leading: const Icon(Icons.lock_reset),
                title: const Text('Cambiar contraseña'),
                onTap: () => Navigator.pushNamed(context, 'forgotpassword'),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar sesión'),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                        context, 'login', (_) => false);
                  }
                },
              ),
            ],
          ),

          if (_saving)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
