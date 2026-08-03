import 'json_utils.dart';

class Conductor {
  final int id;
  final int? usuarioId;
  final String? nombres;
  final String? apellidos;
  final String? dni;
  final String? correo;
  final String? telefono;
  final String? licencia;
  final String? categoriaLicencia;
  final String? fechaIngreso;
  final String? conductorEstado;
  final String? usuarioEstado;
  final String? rutaActual;
  final String? camionActual;

  Conductor({
    required this.id,
    this.usuarioId,
    this.nombres,
    this.apellidos,
    this.dni,
    this.correo,
    this.telefono,
    this.licencia,
    this.categoriaLicencia,
    this.fechaIngreso,
    this.conductorEstado,
    this.usuarioEstado,
    this.rutaActual,
    this.camionActual,
  });

  factory Conductor.fromJson(Map<String, dynamic> json) => Conductor(
        id: intOrNull(json['id'])!,
        usuarioId: intOrNull(json['usuario_id']),
        nombres: json['nombres'] as String?,
        apellidos: json['apellidos'] as String?,
        dni: json['dni'] as String?,
        correo: json['correo'] as String?,
        telefono: json['telefono'] as String?,
        licencia: json['licencia'] as String?,
        categoriaLicencia: json['categoria_licencia'] as String?,
        fechaIngreso: json['fecha_ingreso']?.toString(),
        conductorEstado: json['conductor_estado'] as String?,
        usuarioEstado: json['usuario_estado'] as String?,
        rutaActual: json['ruta_actual'] as String?,
        camionActual: json['camion_actual'] as String?,
      );
}
