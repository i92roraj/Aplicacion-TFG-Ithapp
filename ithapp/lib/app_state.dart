import 'package:flutter/material.dart';
import '/backend/backend.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  String _nombre = '';
  String get nombre => _nombre;
  set nombre(String value) {
    _nombre = value;
  }

  String _email = '';
  String get email => _email;
  set email(String value) {
    _email = value;
  }

  String _nombregranja = '';
  String get nombregranja => _nombregranja;
  set nombregranja(String value) {
    _nombregranja = value;
  }

  String _nombresensor = '';
  String get nombresensor => _nombresensor;
  set nombresensor(String value) {
    _nombresensor = value;
  }

  String _sexo = '';
  String get sexo => _sexo;
  set sexo(String value) {
    _sexo = value;
  }

  DateTime? _fechanacimiento;
  DateTime? get fechanacimiento => _fechanacimiento;
  set fechanacimiento(DateTime? value) {
    _fechanacimiento = value;
  }

  String _ubicacion = '';
  String get ubicacion => _ubicacion;
  set ubicacion(String value) {
    _ubicacion = value;
  }

  int _cp = 0;
  int get cp => _cp;
  set cp(int value) {
    _cp = value;
  }
}
