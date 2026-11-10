import 'dart:async';
import 'dart:convert';

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
          'area': solicitud.area,
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

  Stream<List<Map<String, dynamic>>> solicitudesPorEstado(
    String estado, {
    String? area,
  }) {
    var query = firestore
        .collection(coleccion)
        .where('estado', isEqualTo: estado);
    if (area != null) query = query.where('area', isEqualTo: area);
    return query.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList(),
    );
  }

  Stream<List<Map<String, dynamic>>> solicitudesParaEntrega() {
    return firestore
        .collection(coleccion)
        .where('estado', whereIn: const ['APROBADA', 'PARCIAL'])
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> inventarioActual() {
    return firestore
        .collection('inventario')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  static String idOperacionEntrega({
    required String solicitudId,
    required List<Map<String, dynamic>> lineas,
    required Map<String, int> cantidades,
  }) {
    final estadoAnterior = lineas
        .map(
          (linea) => '${linea['insumoId']}:${linea['cantidadEntregada'] ?? 0}',
        )
        .join('|');
    final entradas = cantidades.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final cambio = entradas
        .map((item) => '${item.key}:${item.value}')
        .join('|');
    return base64Url.encode(
      utf8.encode('$solicitudId::$estadoAnterior::$cambio'),
    );
  }

  Stream<List<Map<String, dynamic>>> solicitudesDeEmpleado(String empleadoId) {
    return firestore
        .collection(coleccion)
        .where('empleadoId', isEqualTo: empleadoId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> solicitudesDelArea(String area) {
    return firestore
        .collection(coleccion)
        .where('area', isEqualTo: area)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {...doc.data(), 'id': doc.id})
              .toList(),
        );
  }

  Future<List<Solicitud>> cargarSolicitudesDeEmpleado(String empleadoId) async {
    final snapshot = await firestore
        .collection(coleccion)
        .where('empleadoId', isEqualTo: empleadoId)
        // Solo el servidor confirma la sincronización: la caché offline de
        // Firestore incluye escrituras aún no enviadas y no debe usarse aquí.
        .get(const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 12));
    return snapshot.docs.map((doc) {
      final data = doc.data();
      final fechaCreacion = data['fechaCreacion'];
      final fechaDecision = data['fechaDecision'];
      return Solicitud.fromJson({
        ...data,
        'id': doc.id,
        'fechaCreacion': fechaCreacion is Timestamp
            ? fechaCreacion.toDate().toIso8601String()
            : fechaCreacion.toString(),
        'fechaDecision': fechaDecision is Timestamp
            ? fechaDecision.toDate().toIso8601String()
            : fechaDecision?.toString(),
      }).copyWith(pendienteSync: false);
    }).toList();
  }

  Future<void> decidir({
    required String solicitudId,
    required String supervisorId,
    required bool aprobar,
    required String motivo,
  }) async {
    final requestRef = firestore.collection(coleccion).doc(solicitudId);
    await firestore
        .runTransaction((transaction) async {
          final requestSnapshot = await transaction.get(requestRef);
          final request = requestSnapshot.data();
          if (request == null || request['estado'] != 'SOLICITADA') {
            throw StateError(
              'La solicitud ya fue atendida o no existe. Actualiza la lista.',
            );
          }
          if (request['empleadoId'] == supervisorId) {
            throw StateError(
              'No puedes aprobar una solicitud creada por tu cuenta.',
            );
          }
          final lineas = (request['lineas'] as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          final stockRefs = lineas
              .map(
                (linea) => firestore
                    .collection('inventario')
                    .doc(linea['insumoId'] as String),
              )
              .toList();
          final stockSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
          for (final ref in stockRefs) {
            stockSnapshots.add(await transaction.get(ref));
          }
          if (aprobar) {
            for (var i = 0; i < lineas.length; i++) {
              final stock = stockSnapshots[i].data();
              final solicitado = lineas[i]['cantidadSolicitada'] as int;
              if (stock == null) {
                throw StateError(
                  'Falta configurar el stock de uno de los insumos.',
                );
              }
              final disponible =
                  (stock['existencias'] as num).toInt() -
                  (stock['reservado'] as num? ?? 0).toInt();
              if (disponible < solicitado) {
                throw StateError(
                  'No hay existencias suficientes para aprobar toda la solicitud.',
                );
              }
            }
          }
          if (aprobar) {
            for (var i = 0; i < lineas.length; i++) {
              final stock = stockSnapshots[i].data()!;
              transaction.update(stockRefs[i], {
                'reservado':
                    (stock['reservado'] as num? ?? 0).toInt() +
                    (lineas[i]['cantidadSolicitada'] as int),
                'actualizadoEn': FieldValue.serverTimestamp(),
              });
            }
          }
          transaction.update(requestRef, {
            'estado': aprobar ? 'APROBADA' : 'RECHAZADA',
            'aprobadorId': supervisorId,
            'fechaDecision': FieldValue.serverTimestamp(),
            'motivoDecision': motivo,
          });
        })
        .timeout(const Duration(seconds: 15));
  }

  Future<void> registrarEntrega({
    required String solicitudId,
    required String encargadoId,
    required Map<String, int> cantidades,
    required String motivo,
    required String operationId,
  }) async {
    final requestRef = firestore.collection(coleccion).doc(solicitudId);
    final operationRef = firestore
        .collection('operaciones_entrega')
        .doc(operationId);
    await firestore
        .runTransaction((transaction) async {
          final requestSnapshot = await transaction.get(requestRef);
          final operationSnapshot = await transaction.get(operationRef);
          if (operationSnapshot.exists) {
            final operation = operationSnapshot.data();
            if (operation?['solicitudId'] != solicitudId ||
                operation?['actorId'] != encargadoId) {
              throw StateError(
                'El identificador de entrega ya pertenece a otra operación.',
              );
            }
            return;
          }
          final request = requestSnapshot.data();
          if (request == null ||
              !{'APROBADA', 'PARCIAL'}.contains(request['estado'])) {
            throw StateError(
              'La solicitud no está aprobada o ya fue entregada.',
            );
          }
          final lineas = (request['lineas'] as List)
              .map((item) => Map<String, dynamic>.from(item as Map))
              .toList();
          final refs = <DocumentReference<Map<String, dynamic>>>[];
          final snapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
          for (final linea in lineas) {
            final id = linea['insumoId'] as String;
            refs.add(firestore.collection('inventario').doc(id));
          }
          for (final ref in refs) {
            snapshots.add(await transaction.get(ref));
          }
          var todasCompletas = true;
          for (var i = 0; i < lineas.length; i++) {
            final linea = lineas[i];
            final cantidad = cantidades[linea['insumoId']] ?? 0;
            final saldo =
                (linea['cantidadSolicitada'] as int) -
                (linea['cantidadEntregada'] as int? ?? 0);
            if (cantidad < 0 || cantidad > saldo) {
              throw StateError(
                'La cantidad entregada supera el saldo aprobado.',
              );
            }
            if (cantidad > 0) {
              final stock = snapshots[i].data();
              if (stock == null ||
                  (stock['reservado'] as num? ?? 0).toInt() < cantidad ||
                  (stock['existencias'] as num? ?? 0).toInt() < cantidad) {
                throw StateError(
                  'El inventario no tiene la reserva necesaria para esta entrega.',
                );
              }
              linea['cantidadEntregada'] =
                  (linea['cantidadEntregada'] as int? ?? 0) + cantidad;
            }
            if ((linea['cantidadEntregada'] as int? ?? 0) <
                (linea['cantidadSolicitada'] as int)) {
              todasCompletas = false;
            }
          }
          for (var i = 0; i < lineas.length; i++) {
            final cantidad = cantidades[lineas[i]['insumoId']] ?? 0;
            if (cantidad > 0) {
              final stock = snapshots[i].data()!;
              transaction.update(refs[i], {
                'existencias': (stock['existencias'] as num).toInt() - cantidad,
                'reservado':
                    (stock['reservado'] as num? ?? 0).toInt() - cantidad,
                'actualizadoEn': FieldValue.serverTimestamp(),
              });
            }
          }
          transaction.update(requestRef, {
            'lineas': lineas,
            'estado': todasCompletas ? 'ENTREGADA' : 'PARCIAL',
            'ultimaEntregaPor': encargadoId,
            'ultimaEntregaEn': FieldValue.serverTimestamp(),
            'motivoEntrega': motivo,
          });
          transaction.set(operationRef, {
            'solicitudId': solicitudId,
            'actorId': encargadoId,
            'cantidades': cantidades,
            'motivo': motivo,
            'fecha': FieldValue.serverTimestamp(),
          });
        })
        .timeout(const Duration(seconds: 15));
  }

  Future<void> cancelar({
    required String solicitudId,
    required String empleadoId,
  }) async {
    final ref = firestore.collection(coleccion).doc(solicitudId);
    await firestore
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          final data = snapshot.data();
          if (data == null ||
              data['empleadoId'] != empleadoId ||
              data['estado'] != 'SOLICITADA') {
            throw StateError(
              'Solo puedes cancelar una solicitud propia que aún no ha sido aprobada.',
            );
          }
          transaction.update(ref, {
            'estado': 'CANCELADA',
            'fechaCancelacion': FieldValue.serverTimestamp(),
          });
        })
        .timeout(const Duration(seconds: 12));
  }

  Future<void> ajustarInventario({
    required String insumoId,
    required int cambio,
    required String actorId,
    required String motivo,
  }) async {
    if (cambio == 0 || motivo.trim().isEmpty) {
      throw ArgumentError('El ajuste requiere cantidad y motivo.');
    }
    final ref = firestore.collection('inventario').doc(insumoId);
    final movementRef = firestore.collection('movimientos_inventario').doc();
    await firestore
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          final stock = snapshot.data();
          if (stock == null) {
            throw StateError('El insumo no tiene inventario configurado.');
          }
          final existencias = (stock['existencias'] as num).toInt();
          final reservado = (stock['reservado'] as num? ?? 0).toInt();
          if (existencias + cambio < reservado) {
            throw StateError(
              'El ajuste dejaría existencias por debajo del stock reservado.',
            );
          }
          if (existencias + cambio < 0) {
            throw StateError('El inventario no puede quedar negativo.');
          }
          transaction.update(ref, {
            'existencias': existencias + cambio,
            'actualizadoEn': FieldValue.serverTimestamp(),
            'ultimoMovimientoId': movementRef.id,
          });
          transaction.set(movementRef, {
            'insumoId': insumoId,
            'cambio': cambio,
            'motivo': motivo.trim(),
            'actorId': actorId,
            'fecha': FieldValue.serverTimestamp(),
          });
        })
        .timeout(const Duration(seconds: 15));
  }

  Future<void> inicializarInventario({
    required String insumoId,
    required int cantidad,
    required String actorId,
    required String motivo,
  }) async {
    if (cantidad <= 0 || motivo.trim().isEmpty) {
      throw ArgumentError('Ingresa una cantidad positiva y un motivo.');
    }
    final ref = firestore.collection('inventario').doc(insumoId);
    final movementRef = firestore.collection('movimientos_inventario').doc();
    await firestore
        .runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (snapshot.exists) {
            throw StateError(
              'El stock ya fue creado; usa la opción de ajuste.',
            );
          }
          transaction.set(ref, {
            'existencias': cantidad,
            'reservado': 0,
            'actualizadoEn': FieldValue.serverTimestamp(),
            'ultimoMovimientoId': movementRef.id,
          });
          transaction.set(movementRef, {
            'insumoId': insumoId,
            'cambio': cantidad,
            'motivo': motivo.trim(),
            'actorId': actorId,
            'fecha': FieldValue.serverTimestamp(),
          });
        })
        .timeout(const Duration(seconds: 15));
  }
}
