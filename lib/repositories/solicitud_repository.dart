import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/solicitud.dart';

class SolicitudRepository {
  SolicitudRepository({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> guardar(Solicitud solicitud) async {
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
      'syncState': 'PENDIENTE',
      'updatedAt': now,
      'lastError': null,
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }

  Future<List<Solicitud>> listarPorEmpleado(String empleadoId) async {
    final database = await _database.database;
    final rows = await database.query(
      AppDatabase.tableSolicitudes,
      where: 'empleadoId = ?',
      whereArgs: [empleadoId],
      orderBy: 'fechaCreacion DESC',
    );

    return rows.map((row) {
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
      return Solicitud.fromJson(json);
    }).toList();
  }
}
