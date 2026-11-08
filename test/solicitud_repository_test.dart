import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insumos_g62_4/database/app_database.dart';
import 'package:insumos_g62_4/models/linea_solicitud.dart';
import 'package:insumos_g62_4/models/solicitud.dart';
import 'package:insumos_g62_4/remote/solicitud_remote_data_source.dart';
import 'package:insumos_g62_4/repositories/solicitud_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

// Simula Firestore disponible o caído sin conectarse a Firebase.
class FakeSolicitudRemoteDataSource implements SolicitudRemoteDataSource {
  FakeSolicitudRemoteDataSource({this.shouldFail = false});

  bool shouldFail;
  final List<String> enviadas = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  FirebaseFirestore get firestore => throw UnimplementedError();

  @override
  Future<void> guardar(Solicitud solicitud) async {
    if (shouldFail) throw Exception('Fallo remoto simulado');
    enviadas.add(solicitud.id);
  }
}

Solicitud crearSolicitud(String id) {
  return Solicitud(
    id: id,
    empleadoId: 'empleado-prueba',
    fechaCreacion: DateTime(2026, 11, 5, 10),
    estado: EstadoSolicitud.SOLICITADA,
    lineas: [LineaSolicitud(insumoId: 'insumo-1', cantidadSolicitada: 3)],
  );
}

void main() {
  late AppDatabase database;
  late FakeSolicitudRemoteDataSource remote;
  late SolicitudRepository repository;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    database = AppDatabase.enMemoria();
    remote = FakeSolicitudRemoteDataSource();
    repository = SolicitudRepository(database: database, remote: remote);
  });

  tearDown(() async {
    await database.cerrar();
  });

  group('Guardar solicitud', () {
    test('Con Firestore disponible queda sincronizada', () async {
      final sincronizada = await repository.guardar(crearSolicitud('s-1'));

      final solicitudes = await repository.listarPorEmpleado('empleado-prueba');
      expect(sincronizada, isTrue);
      expect(remote.enviadas, ['s-1']);
      expect(solicitudes.single.pendienteSync, isFalse);
    });

    test(
      'Si Firestore falla se conserva en el dispositivo como pendiente',
      () async {
        remote.shouldFail = true;

        final sincronizada = await repository.guardar(crearSolicitud('s-1'));

        final solicitudes = await repository.listarPorEmpleado(
          'empleado-prueba',
        );
        expect(sincronizada, isFalse);
        expect(solicitudes.single.id, 's-1');
        expect(solicitudes.single.pendienteSync, isTrue);
      },
    );

    test('Sin Firebase configurado queda pendiente', () async {
      final sinRemoto = SolicitudRepository(database: database);

      final sincronizada = await sinRemoto.guardar(crearSolicitud('s-1'));

      final solicitudes = await sinRemoto.listarPorEmpleado('empleado-prueba');
      expect(sincronizada, isFalse);
      expect(solicitudes.single.pendienteSync, isTrue);
    });
  });

  group('Sincronizar pendientes', () {
    test('No envía solicitudes pendientes de otra cuenta', () async {
      remote.shouldFail = true;
      await repository.guardar(crearSolicitud('s-actual'));
      await repository.guardar(
        crearSolicitud('s-otra-cuenta').copyWith(empleadoId: 'otro-empleado'),
      );

      remote.shouldFail = false;
      final resultado = await repository.sincronizarPendientes(
        empleadoId: 'empleado-prueba',
      );

      expect(resultado.sincronizadas, 1);
      expect(remote.enviadas, ['s-actual']);
      final ajenas = await repository.listarPorEmpleado('otro-empleado');
      expect(ajenas.single.pendienteSync, isTrue);
    });

    test('Envía las pendientes cuando Firestore vuelve a responder', () async {
      remote.shouldFail = true;
      await repository.guardar(crearSolicitud('s-1'));
      await repository.guardar(crearSolicitud('s-2'));

      remote.shouldFail = false;
      final resultado = await repository.sincronizarPendientes(
        empleadoId: 'empleado-prueba',
      );

      final solicitudes = await repository.listarPorEmpleado('empleado-prueba');
      expect(resultado.sincronizadas, 2);
      expect(resultado.pendientes, 0);
      expect(solicitudes.every((s) => !s.pendienteSync), isTrue);
    });

    test('No reenvía las solicitudes ya sincronizadas', () async {
      await repository.guardar(crearSolicitud('s-1'));

      final resultado = await repository.sincronizarPendientes(
        empleadoId: 'empleado-prueba',
      );

      expect(resultado.sincronizadas, 0);
      expect(resultado.pendientes, 0);
      expect(remote.enviadas, ['s-1']);
    });

    test(
      'Si Firestore sigue caído las solicitudes continúan pendientes',
      () async {
        remote.shouldFail = true;
        await repository.guardar(crearSolicitud('s-1'));

        final resultado = await repository.sincronizarPendientes(
          empleadoId: 'empleado-prueba',
        );

        expect(resultado.sincronizadas, 0);
        expect(resultado.pendientes, 1);
      },
    );
  });
}
