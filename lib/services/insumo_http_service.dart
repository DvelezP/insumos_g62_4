import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/insumo.dart';

class InsumoHttpService {
  const InsumoHttpService({required this.url});

  final Uri url;

  Future<List<Insumo>> fetchInsumos() async {
    late final http.Response response;
    try {
      response = await http.get(url).timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const InsumoServiceException(
        'La solicitud tardó demasiado. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on SocketException {
      throw const InsumoServiceException(
        'No hay conexión a Internet. Revisa tu conexión e inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw const InsumoServiceException(
        'No se pudo conectar con el catálogo. Inténtalo de nuevo.',
      );
    }

    if (response.statusCode == 500) {
      throw const InsumoServiceException(
        'El servidor de INVIMA presentó un error (500). Inténtalo más tarde.',
      );
    }
    if (response.statusCode != 200) {
      throw InsumoServiceException(
        'La consulta al catálogo falló (código ${response.statusCode}).',
      );
    }

    late final dynamic decodedJson;
    try {
      decodedJson = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const InsumoServiceException(
        'El catálogo respondió con datos JSON que no se pudieron leer.',
      );
    }

    if (decodedJson is! List) {
      throw const InsumoServiceException(
        'La respuesta de INVIMA tiene un formato inesperado.',
      );
    }

    try {
      return decodedJson.asMap().entries.map((entry) {
        final row = entry.value;
        if (row is! Map<String, dynamic>) {
          throw const FormatException('Registro con formato inválido.');
        }

        final expediente = _text(row['expedientecum'] ?? row['expediente']);
        final consecutivo = _text(row['consecutivocum']);
        final id = expediente.isNotEmpty
            ? (consecutivo.isNotEmpty ? '$expediente-$consecutivo' : expediente)
            : 'invima-${entry.key}';

        return Insumo(
          id: id,
          nombre: _text(row['producto'], fallback: 'Producto sin nombre'),
          unidad: _text(
            row['unidadreferencia'] ?? row['unidad'] ?? row['unidadmedida'],
            fallback: 'unidad',
          ),
          categoria: _text(
            row['descripcionatc'] ?? row['atc'] ?? row['viaadministracion'],
            fallback: 'Medicamentos',
          ),
          descripcion: _text(
            row['descripcioncomercial'],
            fallback: 'Sin descripción comercial.',
          ),
        );
      }).toList();
    } on TypeError {
      throw const InsumoServiceException(
        'Uno o más registros de INVIMA tienen datos inválidos.',
      );
    } on FormatException {
      throw const InsumoServiceException(
        'Uno o más registros de INVIMA tienen un formato inválido.',
      );
    }
  }

  String _text(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }
}

class InsumoServiceException implements Exception {
  const InsumoServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}
