import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/solicitud.dart';
import '../remote/solicitud_remote_data_source.dart';

class ResultadoSincronizacion {
  const ResultadoSincronizacion({
    required this.sincronizadas,
    required this.pendientes,
  });

  final int sincronizadas;
  final int pendientes;
}

class SolicitudRepository {
  SolicitudRepository({AppDatabase? database, this.remote})
    : _database = database ?? AppDatabase.instance;

  static const syncPendiente = 'PENDIENTE';
  static const syncSincronizada = 'SINCRONIZADA';

  final AppDatabase _database;
  final SolicitudRemoteDataSource? remote;

  // Guarda primero en el dispositivo y luego intenta enviarla a Firestore.
  // Devuelve true solo si Firestore confirmó la escritura.
  Future<bool> guardar(Solicitud solicitud) async {
    final database = await _database.database;
    final now = DateTime.now().toIso8601String();
    await database.insert(AppDatabase.tableSolicitudes, {
      'id': solicitud.id,
      'empleadoId': solicitud.empleadoId,
      'fechaCreacion': solicitud.fechaCreacion.toIso8601String(),
      'estado': solicitud.estado.name,
      'lineasJson': jsonEncode(
        solicitud.lineas.map((linea) => linea.toJson()).toList(),
      ),
      'aprobadorId': solicitud.aprobadorId,
      'fechaDecision': solicitud.fechaDecision?.toIso8601String(),
      'syncState': syncPendiente,
      'updatedAt': now,
      'lastError': null,
    }, conflictAlgorithm: ConflictAlgorithm.abort);

    return _enviar(solicitud);
  }

  Future<List<Solicitud>> listarPorEmpleado(String empleadoId) async {
    final database = await _database.database;
    final rows = await database.query(
      AppDatabase.tableSolicitudes,
      where: 'empleadoId = ?',
      whereArgs: [empleadoId],
      orderBy: 'fechaCreacion DESC',
    );
    return rows.map(_fromRow).toList();
  }

  // Reintenta únicamente las solicitudes que siguen pendientes.
  Future<ResultadoSincronizacion> sincronizarPendientes() async {
    final database = await _database.database;
    final rows = await database.query(
      AppDatabase.tableSolicitudes,
      where: 'syncState = ?',
      whereArgs: [syncPendiente],
      orderBy: 'fechaCreacion ASC',
    );

    var sincronizadas = 0;
    var pendientes = 0;
    for (final row in rows) {
      if (await _enviar(_fromRow(row))) {
        sincronizadas++;
      } else {
        pendientes++;
      }
    }

    return ResultadoSincronizacion(
      sincronizadas: sincronizadas,
      pendientes: pendientes,
    );
  }

  // Si Firestore falla, la solicitud se conserva en el dispositivo con
  // syncState = PENDIENTE y el motivo en lastError; no se lanza error.
  Future<bool> _enviar(Solicitud solicitud) async {
    final remoteSource = remote;
    if (remoteSource == null) {
      await _actualizarSync(
        solicitud.id,
        syncPendiente,
        lastError: 'Firebase no está disponible.',
      );
      return false;
    }

    try {
      await remoteSource.guardar(solicitud);
      await _actualizarSync(solicitud.id, syncSincronizada);
      return true;
    } catch (error) {
      await _actualizarSync(
        solicitud.id,
        syncPendiente,
        lastError: error.toString(),
      );
      return false;
    }
  }

  Future<void> _actualizarSync(
    String id,
    String syncState, {
    String? lastError,
  }) async {
    final database = await _database.database;
    await database.update(
      AppDatabase.tableSolicitudes,
      {
        'syncState': syncState,
        'updatedAt': DateTime.now().toIso8601String(),
        'lastError': lastError,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Solicitud _fromRow(Map<String, Object?> row) {
    final lineas = (jsonDecode(row['lineasJson']! as String) as List)
        .map((linea) => Map<String, dynamic>.from(linea as Map))
        .toList();
    final json = <String, dynamic>{
      'id': row['id'],
      'empleadoId': row['empleadoId'],
      'fechaCreacion': row['fechaCreacion'],
      'estado': row['estado'],
      'lineas': lineas,
      'aprobadorId': row['aprobadorId'],
      'fechaDecision': row['fechaDecision'],
    };
    return Solicitud.fromJson(
      json,
    ).copyWith(pendienteSync: row['syncState'] == syncPendiente);
  }
}
