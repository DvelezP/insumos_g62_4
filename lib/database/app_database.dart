import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();
  static const _databaseName = 'insumos_g62_4.db';
  static const _databaseVersion = 2;
  static const tableSolicitudes = 'solicitudes';
  static const tableInsumos = 'insumos';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final databasePath = await getDatabasesPath();
    final fullPath = path.join(databasePath, _databaseName);
    _database = await openDatabase(
      fullPath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createSolicitudesTable(db);
        await _createInsumosTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createInsumosTable(db);
      },
    );
    return _database!;
  }

  Future<void> _createSolicitudesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tableSolicitudes (
        id TEXT PRIMARY KEY,
        empleadoId TEXT NOT NULL,
        fechaCreacion TEXT NOT NULL,
        estado TEXT NOT NULL,
        lineasJson TEXT NOT NULL,
        aprobadorId TEXT,
        fechaDecision TEXT,
        syncState TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        lastError TEXT
      )
    ''');
  }

  Future<void> _createInsumosTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tableInsumos (
        id TEXT PRIMARY KEY,
        nombre TEXT NOT NULL,
        datosJson TEXT NOT NULL
      )
    ''');
  }
}
