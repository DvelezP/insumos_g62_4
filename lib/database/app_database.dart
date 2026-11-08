import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._([this._path]);

  // Base temporal en memoria para las pruebas automatizadas.
  factory AppDatabase.enMemoria() => AppDatabase._(inMemoryDatabasePath);

  static final AppDatabase instance = AppDatabase._();
  static const _databaseName = 'insumos_g62_4.db';
  static const _databaseVersion = 3;
  static const tableSolicitudes = 'solicitudes';
  static const tableInsumos = 'insumos';

  final String? _path;
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    final fullPath =
        _path ?? path.join(await getDatabasesPath(), _databaseName);
    _database = await openDatabase(
      fullPath,
      version: _databaseVersion,
      onCreate: (db, version) async {
        await _createSolicitudesTable(db);
        await _createInsumosTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createInsumosTable(db);
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE $tableSolicitudes ADD COLUMN area TEXT NOT NULL DEFAULT 'General'",
          );
        }
      },
    );
    return _database!;
  }

  Future<void> cerrar() async {
    await _database?.close();
    _database = null;
  }

  Future<void> _createSolicitudesTable(DatabaseExecutor db) async {
    await db.execute('''
      CREATE TABLE $tableSolicitudes (
        id TEXT PRIMARY KEY,
        empleadoId TEXT NOT NULL,
        area TEXT NOT NULL DEFAULT 'General',
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
