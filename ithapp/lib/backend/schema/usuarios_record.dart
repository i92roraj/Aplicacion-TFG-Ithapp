import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class UsuariosRecord extends FirestoreRecord {
  UsuariosRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "nombre" field.
  String? _nombre;
  String get nombre => _nombre ?? '';
  bool hasNombre() => _nombre != null;

  // "email" field.
  String? _email;
  String get email => _email ?? '';
  bool hasEmail() => _email != null;

  // "password" field.
  String? _password;
  String get password => _password ?? '';
  bool hasPassword() => _password != null;

  // "fechanacimiento" field.
  DateTime? _fechanacimiento;
  DateTime? get fechanacimiento => _fechanacimiento;
  bool hasFechanacimiento() => _fechanacimiento != null;

  // "nombre_granja" field.
  String? _nombreGranja;
  String get nombreGranja => _nombreGranja ?? '';
  bool hasNombreGranja() => _nombreGranja != null;

  // "id_granja" field.
  int? _idGranja;
  int get idGranja => _idGranja ?? 0;
  bool hasIdGranja() => _idGranja != null;

  // "direccion_granja" field.
  String? _direccionGranja;
  String get direccionGranja => _direccionGranja ?? '';
  bool hasDireccionGranja() => _direccionGranja != null;

  // "ubicacion_granja" field.
  LatLng? _ubicacionGranja;
  LatLng? get ubicacionGranja => _ubicacionGranja;
  bool hasUbicacionGranja() => _ubicacionGranja != null;

  // "sexo" field.
  String? _sexo;
  String get sexo => _sexo ?? '';
  bool hasSexo() => _sexo != null;

  // "cp" field.
  int? _cp;
  int get cp => _cp ?? 0;
  bool hasCp() => _cp != null;

  // "tipo_usuario" field.
  String? _tipoUsuario;
  String get tipoUsuario => _tipoUsuario ?? '';
  bool hasTipoUsuario() => _tipoUsuario != null;

  // "id_dispositivo" field.
  int? _idDispositivo;
  int get idDispositivo => _idDispositivo ?? 0;
  bool hasIdDispositivo() => _idDispositivo != null;

  void _initializeFields() {
    _nombre = snapshotData['nombre'] as String?;
    _email = snapshotData['email'] as String?;
    _password = snapshotData['password'] as String?;
    _fechanacimiento = snapshotData['fechanacimiento'] as DateTime?;
    _nombreGranja = snapshotData['nombre_granja'] as String?;
    _idGranja = castToType<int>(snapshotData['id_granja']);
    _direccionGranja = snapshotData['direccion_granja'] as String?;
    _ubicacionGranja = snapshotData['ubicacion_granja'] as LatLng?;
    _sexo = snapshotData['sexo'] as String?;
    _cp = castToType<int>(snapshotData['cp']);
    _tipoUsuario = snapshotData['tipo_usuario'] as String?;
    _idDispositivo = castToType<int>(snapshotData['id_dispositivo']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('usuarios');

  static Stream<UsuariosRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => UsuariosRecord.fromSnapshot(s));

  static Future<UsuariosRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => UsuariosRecord.fromSnapshot(s));

  static UsuariosRecord fromSnapshot(DocumentSnapshot snapshot) =>
      UsuariosRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static UsuariosRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      UsuariosRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'UsuariosRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is UsuariosRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createUsuariosRecordData({
  String? nombre,
  String? email,
  String? password,
  DateTime? fechanacimiento,
  String? nombreGranja,
  int? idGranja,
  String? direccionGranja,
  LatLng? ubicacionGranja,
  String? sexo,
  int? cp,
  String? tipoUsuario,
  int? idDispositivo,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'nombre': nombre,
      'email': email,
      'password': password,
      'fechanacimiento': fechanacimiento,
      'nombre_granja': nombreGranja,
      'id_granja': idGranja,
      'direccion_granja': direccionGranja,
      'ubicacion_granja': ubicacionGranja,
      'sexo': sexo,
      'cp': cp,
      'tipo_usuario': tipoUsuario,
      'id_dispositivo': idDispositivo,
    }.withoutNulls,
  );

  return firestoreData;
}

class UsuariosRecordDocumentEquality implements Equality<UsuariosRecord> {
  const UsuariosRecordDocumentEquality();

  @override
  bool equals(UsuariosRecord? e1, UsuariosRecord? e2) {
    return e1?.nombre == e2?.nombre &&
        e1?.email == e2?.email &&
        e1?.password == e2?.password &&
        e1?.fechanacimiento == e2?.fechanacimiento &&
        e1?.nombreGranja == e2?.nombreGranja &&
        e1?.idGranja == e2?.idGranja &&
        e1?.direccionGranja == e2?.direccionGranja &&
        e1?.ubicacionGranja == e2?.ubicacionGranja &&
        e1?.sexo == e2?.sexo &&
        e1?.cp == e2?.cp &&
        e1?.tipoUsuario == e2?.tipoUsuario &&
        e1?.idDispositivo == e2?.idDispositivo;
  }

  @override
  int hash(UsuariosRecord? e) => const ListEquality().hash([
        e?.nombre,
        e?.email,
        e?.password,
        e?.fechanacimiento,
        e?.nombreGranja,
        e?.idGranja,
        e?.direccionGranja,
        e?.ubicacionGranja,
        e?.sexo,
        e?.cp,
        e?.tipoUsuario,
        e?.idDispositivo
      ]);

  @override
  bool isValidKey(Object? o) => o is UsuariosRecord;
}
