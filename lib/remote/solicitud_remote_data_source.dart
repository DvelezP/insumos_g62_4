import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/solicitud.dart';

class SolicitudRemoteDataSource {
  SolicitudRemoteDataSource({required this.firestore});

  static const coleccion = 'solicitudes';

  final FirebaseFirestore firestore;

  // El id de la solicitud es el id del documento: reenviar la misma
  // solicitud actualiza el documento en lugar de crear uno nuevo.
  Future<void> guardar(Solicitud solicitud) async {
    await firestore
        .collection(coleccion)
        .doc(solicitud.id)
        .set({
          'id': solicitud.id,
          'empleadoId': solicitud.empleadoId,
          'fechaCreacion': Timestamp.fromDate(solicitud.fechaCreacion),
          'estado': solicitud.estado.name,
          'lineas': solicitud.lineas.map((linea) => linea.toJson()).toList(),
          'aprobadorId': solicitud.aprobadorId,
          'fechaDecision': solicitud.fechaDecision == null
              ? null
              : Timestamp.fromDate(solicitud.fechaDecision!),
        }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 8));
  }
}
