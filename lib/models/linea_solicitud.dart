class LineaSolicitud {
  LineaSolicitud({
    required this.insumoId,
    required this.cantidadSolicitada,
    this.cantidadEntregada = 0,
  }) {
    if (cantidadSolicitada < 1 || cantidadSolicitada > 20) {
      throw ArgumentError.value(
        cantidadSolicitada,
        'cantidadSolicitada',
        'Debe ser un número entero entre 1 y 20.',
      );
    }
    if (cantidadEntregada < 0 || cantidadEntregada > cantidadSolicitada) {
      throw ArgumentError.value(
        cantidadEntregada,
        'cantidadEntregada',
        'Debe estar entre 0 y la cantidad solicitada.',
      );
    }
  }

  final String insumoId;
  final int cantidadSolicitada;
  final int cantidadEntregada;

  factory LineaSolicitud.fromJson(Map<String, dynamic> json) {
    return LineaSolicitud(
      insumoId: json['insumoId'] as String,
      cantidadSolicitada: json['cantidadSolicitada'] as int,
      cantidadEntregada: json['cantidadEntregada'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'insumoId': insumoId,
        'cantidadSolicitada': cantidadSolicitada,
        'cantidadEntregada': cantidadEntregada,
      };

  LineaSolicitud copyWith({
    String? insumoId,
    int? cantidadSolicitada,
    int? cantidadEntregada,
  }) {
    return LineaSolicitud(
      insumoId: insumoId ?? this.insumoId,
      cantidadSolicitada: cantidadSolicitada ?? this.cantidadSolicitada,
      cantidadEntregada: cantidadEntregada ?? this.cantidadEntregada,
    );
  }
}
