enum RolUsuario { empleado, supervisor, bodega }

class PerfilUsuario {
  const PerfilUsuario({
    required this.uid,
    required this.correo,
    required this.rol,
    this.area = 'General',
  });

  final String uid;
  final String correo;
  final RolUsuario rol;
  final String area;

  factory PerfilUsuario.fromJson(String uid, Map<String, dynamic> json) {
    final rolTexto = json['rol'] as String? ?? 'empleado';
    final rol = RolUsuario.values.where((value) => value.name == rolTexto);
    if (rol.isEmpty) {
      throw const FormatException('El perfil tiene un rol inválido.');
    }
    return PerfilUsuario(
      uid: uid,
      correo: json['correo'] as String? ?? '',
      rol: rol.first,
      area: json['area'] as String? ?? 'General',
    );
  }
}
