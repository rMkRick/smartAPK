import 'json_utils.dart';

class Horario {
  final int id;
  final int? rutaId;
  final String? diaSemana;
  final String? horaInicio;
  final String? horaFin;
  final String? rutaNombre;
  final String? zonaNombre;
  final String? tipoResiduo;

  Horario({
    required this.id,
    this.rutaId,
    this.diaSemana,
    this.horaInicio,
    this.horaFin,
    this.rutaNombre,
    this.zonaNombre,
    this.tipoResiduo,
  });

  factory Horario.fromJson(Map<String, dynamic> json) => Horario(
        id: intOrNull(json['id'])!,
        rutaId: intOrNull(json['ruta_id']),
        diaSemana: json['dia_semana'] as String?,
        horaInicio: json['hora_inicio']?.toString(),
        horaFin: json['hora_fin']?.toString(),
        rutaNombre: json['ruta_nombre'] as String?,
        zonaNombre: json['zona_nombre'] as String?,
        tipoResiduo: json['tipo_residuo'] as String?,
      );
}
