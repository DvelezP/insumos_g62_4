// ignore_for_file: constant_identifier_names

import 'linea_solicitud.dart';

enum EstadoSolicitud {
  SOLICITADA,
  APROBADA,
  PARCIAL,
  ENTREGADA,
  RECHAZADA,
  CANCELADA,
}

class Solicitud {
  Solicitud({
    required this.id,
    required this.empleadoId,
    required this.fechaCreacion,
    required this.estado,
    required List<LineaSolicitud> lineas,
    this.area = 'General',
    this.aprobadorId,
    this.fechaDecision,
    this.pendienteSync = true,
    this.syncError,
  }) : lineas = List.unmodifiable(lineas) {
    if (this.lineas.isEmpty || this.lineas.length > 5) {
      throw ArgumentError.value(
        this.lineas.length,
        'lineas',
        'La solicitud debe tener entre 1 y 5 líneas.',
      );
    }

    final insumosDistintos = this.lineas.map((linea) => linea.insumoId).toSet();
    if (insumosDistintos.length != this.lineas.length) {
      throw ArgumentError.value(
        lineas,
        'lineas',
        'No se puede repetir un insumo en una solicitud.',
      );
    }
  }

  final String id;
  final String empleadoId;
  final DateTime fechaCreacion;
  final EstadoSolicitud estado;
  final List<LineaSolicitud> lineas;
  final String area;
  final String? aprobadorId;
  final DateTime? fechaDecision;

  // Estado local: indica si la solicitud aún no se ha confirmado en Firestore.
  final bool pendienteSync;
  final String? syncError;

  factory Solicitud.fromJson(Map<String, dynamic> json) {
    final lineasJson = json['lineas'] as List<dynamic>;
    return Solicitud(
      id: json['id'] as String,
      empleadoId: json['empleadoId'] as String,
      fechaCreacion: DateTime.parse(json['fechaCreacion'] as String),
      estado: EstadoSolicitud.values.byName(json['estado'] as String),
      lineas: lineasJson
          .map(
            (linea) => LineaSolicitud.fromJson(
              Map<String, dynamic>.from(linea as Map),
            ),
          )
          .toList(),
      area: json['area'] as String? ?? 'General',
      aprobadorId: json['aprobadorId'] as String?,
      fechaDecision: json['fechaDecision'] == null
          ? null
          : DateTime.parse(json['fechaDecision'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'empleadoId': empleadoId,
    'fechaCreacion': fechaCreacion.toIso8601String(),
    'estado': estado.name,
    'lineas': lineas.map((linea) => linea.toJson()).toList(),
    'area': area,
    'aprobadorId': aprobadorId,
    'fechaDecision': fechaDecision?.toIso8601String(),
  };

  Solicitud copyWith({
    String? id,
    String? empleadoId,
    DateTime? fechaCreacion,
    EstadoSolicitud? estado,
    List<LineaSolicitud>? lineas,
    String? area,
    String? aprobadorId,
    DateTime? fechaDecision,
    bool? pendienteSync,
    String? syncError,
    bool limpiarSyncError = false,
    bool limpiarAprobadorId = false,
    bool limpiarFechaDecision = false,
  }) {
    return Solicitud(
      id: id ?? this.id,
      empleadoId: empleadoId ?? this.empleadoId,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      estado: estado ?? this.estado,
      lineas: lineas ?? this.lineas,
      area: area ?? this.area,
      aprobadorId: limpiarAprobadorId ? null : aprobadorId ?? this.aprobadorId,
      fechaDecision: limpiarFechaDecision
          ? null
          : fechaDecision ?? this.fechaDecision,
      pendienteSync: pendienteSync ?? this.pendienteSync,
      syncError: limpiarSyncError ? null : syncError ?? this.syncError,
    );
  }
}
