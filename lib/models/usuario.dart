import 'json_utils.dart';

class Usuario {
  final int? id;
  final String? nombres;
  final String? apellidos;
  final String? nombre;
  final String? correo;
  final int? rol;

  Usuario({
    this.id,
    this.nombres,
    this.apellidos,
    this.nombre,
    this.correo,
    this.rol,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
        id: intOrNull(json['id']),
        nombres: json['nombres'] as String?,
        apellidos: json['apellidos'] as String?,
        nombre: json['nombre'] as String?,
        correo: json['correo'] as String?,
        rol: intOrNull(json['rol']),
      );
}
