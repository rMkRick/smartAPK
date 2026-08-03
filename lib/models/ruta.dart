import 'json_utils.dart';

class Ruta {
  final int id;
  final String? nombre;
  final String? descripcion;
  final String? zonaNombre;
  final int? camionId;
  final String? placa;
  final String? modelo;
  final String? fechaAsignacion;
  final String? horaInicio;
  final String? horaFin;
  final String? operadorNombres;
  final String? operadorApellidos;
  final List<dynamic>? waypoints;

  Ruta({
    required this.id,
    this.nombre,
    this.descripcion,
    this.zonaNombre,
    this.camionId,
    this.placa,
    this.modelo,
    this.fechaAsignacion,
    this.horaInicio,
    this.horaFin,
    this.operadorNombres,
    this.operadorApellidos,
    this.waypoints,
  });

  factory Ruta.fromJson(Map<String, dynamic> json) => Ruta(
        id: intOrNull(json['id'])!,
        nombre: json['nombre'] as String?,
        descripcion: json['descripcion'] as String?,
        zonaNombre: json['zona_nombre'] as String?,
        camionId: intOrNull(json['camion_id']),
        placa: json['placa'] as String?,
        modelo: json['modelo'] as String?,
        fechaAsignacion: json['fecha_asignacion']?.toString(),
        horaInicio: json['hora_inicio']?.toString(),
        horaFin: json['hora_fin']?.toString(),
        operadorNombres: json['operador_nombres'] as String?,
        operadorApellidos: json['operador_apellidos'] as String?,
        waypoints: json['waypoints'] is List ? json['waypoints'] as List<dynamic> : null,
      );
}
