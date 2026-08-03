import 'json_utils.dart';

class Reporte {
  final int id;
  final int? usuarioId;
  final String? numeroTicket;
  final String? descripcion;
  final String? estado;
  final String? comentarioAdmin;
  final String? respuestaSupervisor;
  final String? fechaCreacion;
  final String? fotoUrl;
  final dynamic latitud;
  final dynamic longitud;
  final String? nombres;
  final String? apellidos;
  final String? correo;
  final String? tipoResiduo;

  Reporte({
    required this.id,
    this.usuarioId,
    this.numeroTicket,
    this.descripcion,
    this.estado,
    this.comentarioAdmin,
    this.respuestaSupervisor,
    this.fechaCreacion,
    this.fotoUrl,
    this.latitud,
    this.longitud,
    this.nombres,
    this.apellidos,
    this.correo,
    this.tipoResiduo,
  });

  factory Reporte.fromJson(Map<String, dynamic> json) => Reporte(
        id: intOrNull(json['id'])!,
        usuarioId: intOrNull(json['usuario_id']),
        numeroTicket: json['numero_ticket'] as String?,
        descripcion: json['descripcion'] as String?,
        estado: json['estado'] as String?,
        comentarioAdmin: json['comentario_admin'] as String?,
        respuestaSupervisor: json['respuesta_supervisor'] as String?,
        fechaCreacion: json['fecha_creacion']?.toString(),
        fotoUrl: json['foto_url'] as String?,
        latitud: json['latitud'],
        longitud: json['longitud'],
        nombres: json['nombres'] as String?,
        apellidos: json['apellidos'] as String?,
        correo: json['correo'] as String?,
        tipoResiduo: json['tipo_residuo'] as String?,
      );
}
