class Insumo {
  const Insumo({
    required this.id,
    required this.nombre,
    required this.unidad,
    required this.categoria,
    required this.descripcion,
  });

  final String id;
  final String nombre;
  final String unidad;
  final String categoria;
  final String descripcion;

  factory Insumo.fromJson(Map<String, dynamic> json) {
    return Insumo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      unidad: json['unidad'] as String,
      categoria: json['categoria'] as String,
      descripcion: json['descripcion'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'unidad': unidad,
    'categoria': categoria,
    'descripcion': descripcion,
  };

  Insumo copyWith({
    String? id,
    String? nombre,
    String? unidad,
    String? categoria,
    String? descripcion,
  }) {
    return Insumo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      unidad: unidad ?? this.unidad,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
    );
  }
}
