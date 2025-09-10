import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class MedicionesRecord extends FirestoreRecord {
  MedicionesRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "id" field.
  int? _id;
  int get id => _id ?? 0;
  bool hasId() => _id != null;

  // "temperatura" field.
  double? _temperatura;
  double get temperatura => _temperatura ?? 0.0;
  bool hasTemperatura() => _temperatura != null;

  // "humedad" field.
  double? _humedad;
  double get humedad => _humedad ?? 0.0;
  bool hasHumedad() => _humedad != null;

  // "ith" field.
  double? _ith;
  double get ith => _ith ?? 0.0;
  bool hasIth() => _ith != null;

  // "id_granja" field.
  int? _idGranja;
  int get idGranja => _idGranja ?? 0;
  bool hasIdGranja() => _idGranja != null;

  void _initializeFields() {
    _id = castToType<int>(snapshotData['id']);
    _temperatura = castToType<double>(snapshotData['temperatura']);
    _humedad = castToType<double>(snapshotData['humedad']);
    _ith = castToType<double>(snapshotData['ith']);
    _idGranja = castToType<int>(snapshotData['id_granja']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('mediciones');

  static Stream<MedicionesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => MedicionesRecord.fromSnapshot(s));

  static Future<MedicionesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => MedicionesRecord.fromSnapshot(s));

  static MedicionesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      MedicionesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static MedicionesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      MedicionesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'MedicionesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is MedicionesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createMedicionesRecordData({
  int? id,
  double? temperatura,
  double? humedad,
  double? ith,
  int? idGranja,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'id': id,
      'temperatura': temperatura,
      'humedad': humedad,
      'ith': ith,
      'id_granja': idGranja,
    }.withoutNulls,
  );

  return firestoreData;
}

class MedicionesRecordDocumentEquality implements Equality<MedicionesRecord> {
  const MedicionesRecordDocumentEquality();

  @override
  bool equals(MedicionesRecord? e1, MedicionesRecord? e2) {
    return e1?.id == e2?.id &&
        e1?.temperatura == e2?.temperatura &&
        e1?.humedad == e2?.humedad &&
        e1?.ith == e2?.ith &&
        e1?.idGranja == e2?.idGranja;
  }

  @override
  int hash(MedicionesRecord? e) => const ListEquality()
      .hash([e?.id, e?.temperatura, e?.humedad, e?.ith, e?.idGranja]);

  @override
  bool isValidKey(Object? o) => o is MedicionesRecord;
}
