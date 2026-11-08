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
      'area': solicitud.area,
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
    final local = rows.map(_fromRow).toList();
    final remoteSource = remote;
    if (remoteSource == null) return local;
    try {
      final remotas = await remoteSource.cargarSolicitudesDeEmpleado(
        empleadoId,
      );
      final porId = {for (final solicitud in local) solicitud.id: solicitud};
      for (final solicitud in remotas) {
        porId[solicitud.id] = solicitud;
        await database.insert(AppDatabase.tableSolicitudes, {
          'id': solicitud.id,
          'empleadoId': solicitud.empleadoId,
          'area': solicitud.area,
          'fechaCreacion': solicitud.fechaCreacion.toIso8601String(),
          'estado': solicitud.estado.name,
          'lineasJson': jsonEncode(
            solicitud.lineas.map((linea) => linea.toJson()).toList(),
          ),
          'aprobadorId': solicitud.aprobadorId,
          'fechaDecision': solicitud.fechaDecision?.toIso8601String(),
          'syncState': syncSincronizada,
          'updatedAt': DateTime.now().toIso8601String(),
          'lastError': null,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      return porId.values.toList()
        ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));
    } catch (_) {
      // En modo sin conexión se conserva lo que ya está guardado en el teléfono.
      return local;
    }
  }

  Future<void> cancelar(String solicitudId, String empleadoId) async {
    final remoteSource = remote;
    if (remoteSource == null) {
      throw StateError('Se requiere conexión para confirmar la cancelación.');
    }
    await remoteSource.cancelar(
      solicitudId: solicitudId,
      empleadoId: empleadoId,
    );
    final database = await _database.database;
    await database.update(
      AppDatabase.tableSolicitudes,
      {
        'estado': 'CANCELADA',
        'updatedAt': DateTime.now().toIso8601String(),
        'syncState': syncSincronizada,
        'lastError': null,
      },
      where: 'id = ? AND empleadoId = ? AND estado = ?',
      whereArgs: [solicitudId, empleadoId, 'SOLICITADA'],
    );
  }

  Future<void> descartarSolicitudRechazada(
    String solicitudId,
    String empleadoId,
  ) async {
    final database = await _database.database;
    final rows = await database.query(
      AppDatabase.tableSolicitudes,
      where: 'id = ? AND empleadoId = ? AND syncState = ?',
      whereArgs: [solicitudId, empleadoId, syncPendiente],
      limit: 1,
    );
    if (rows.isEmpty ||
        !'${rows.single['lastError']}'.contains('permission-denied')) {
      throw StateError(
        'Solo se puede descartar un envío que Firebase rechazó por permisos.',
      );
    }
    await database.delete(
      AppDatabase.tableSolicitudes,
      where: 'id = ? AND empleadoId = ?',
      whereArgs: [solicitudId, empleadoId],
    );
  }

  // Reintenta únicamente las solicitudes que siguen pendientes.
  Future<ResultadoSincronizacion> sincronizarPendientes({
    required String empleadoId,
  }) async {
    final database = await _database.database;
    final rows = await database.query(
      AppDatabase.tableSolicitudes,
      where: 'syncState = ? AND empleadoId = ?',
      whereArgs: [syncPendiente, empleadoId],
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
      'area': row['area'] ?? 'General',
      'fechaCreacion': row['fechaCreacion'],
      'estado': row['estado'],
      'lineas': lineas,
      'aprobadorId': row['aprobadorId'],
      'fechaDecision': row['fechaDecision'],
    };
    return Solicitud.fromJson(json).copyWith(
      pendienteSync: row['syncState'] == syncPendiente,
      syncError: _mensajeSync(row['lastError'] as String?),
      limpiarSyncError: row['lastError'] == null,
    );
  }

  String? _mensajeSync(String? error) {
    if (error == null || error.isEmpty) return null;
    if (error.contains('permission-denied')) {
      return 'Firebase rechazó el envío por permisos. Revisa el perfil y las reglas; puedes descartarlo.';
    }
    if (error.contains('unavailable') ||
        error.contains('deadline-exceeded') ||
        error.contains('TimeoutException')) {
      return 'Firebase no respondió. El envío sigue pendiente; revisa la conexión e inténtalo de nuevo.';
    }
    return 'Firebase no confirmó el envío. Revisa tu conexión y vuelve a intentarlo.';
  }
}
