import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:insumos_g62_4/services/insumo_http_service.dart';

void main() {
  const url = 'https://catalogo-prueba.example/insumos.json';
  late MockClient client;
  late InsumoHttpService service;

  tearDown(() => service.cerrar());

  test('lee y transforma registros JSON del catálogo', () async {
    client = MockClient(
      (_) async => http.Response(
        '[{"producto":"Guantes","descripcioncomercial":"Nitrilo","unidadreferencia":"caja","descripcionatc":"Protección","expedientecum":"ABC","consecutivocum":"01"}]',
        200,
        headers: const {'content-type': 'application/json; charset=utf-8'},
      ),
    );
    service = InsumoHttpService(url: Uri.parse(url), client: client);
    final insumos = await service.fetchInsumos();
    expect(insumos.single.id, 'ABC-01');
    expect(insumos.single.nombre, 'Guantes');
    expect(insumos.single.unidad, 'caja');
  });

  test('informa un error cuando el servidor responde 500', () async {
    client = MockClient((_) async => http.Response('error', 500));
    service = InsumoHttpService(url: Uri.parse(url), client: client);
    await expectLater(
      service.fetchInsumos(),
      throwsA(isA<InsumoServiceException>()),
    );
  });

  test('rechaza respuestas JSON malformadas', () async {
    client = MockClient((_) async => http.Response('{mal json', 200));
    service = InsumoHttpService(url: Uri.parse(url), client: client);
    await expectLater(
      service.fetchInsumos(),
      throwsA(isA<InsumoServiceException>()),
    );
  });

  test('convierte el timeout en un mensaje controlado', () async {
    client = MockClient((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return http.Response('[]', 200);
    });
    service = InsumoHttpService(
      url: Uri.parse(url),
      client: client,
      timeout: const Duration(milliseconds: 1),
    );
    await expectLater(
      service.fetchInsumos(),
      throwsA(isA<InsumoServiceException>()),
    );
  });

  test('convierte la falta de red en un mensaje controlado', () async {
    client = MockClient((_) async => throw const SocketException('sin red'));
    service = InsumoHttpService(url: Uri.parse(url), client: client);
    await expectLater(
      service.fetchInsumos(),
      throwsA(isA<InsumoServiceException>()),
    );
  });
}
