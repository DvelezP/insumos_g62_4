import 'dart:convert';

import '../database/app_database.dart';
import '../models/insumo.dart';

class InsumoLocalDataSource {
  InsumoLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<Insumo>> obtenerTodos() async {
    final database = await _database.database;
    final rows = await database.query('insumos', orderBy: 'nombre ASC');
    return rows
        .map(
          (row) => Insumo.fromJson(
            Map<String, dynamic>.from(
              jsonDecode(row['datosJson']! as String) as Map,
            ),
          ),
        )
        .toList();
  }

  Future<void> guardarTodos(List<Insumo> insumos) async {
    final database = await _database.database;
    await database.transaction((transaction) async {
      await transaction.delete('insumos');
      final batch = transaction.batch();
      for (final insumo in insumos) {
        batch.insert('insumos', {
          'id': insumo.id,
          'nombre': insumo.nombre,
          'datosJson': jsonEncode(insumo.toJson()),
        });
      }
      await batch.commit(noResult: true);
    });
  }
}
