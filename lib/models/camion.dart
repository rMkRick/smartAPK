import 'json_utils.dart';

class Camion {
  final int id;
  final String? placa;
  final String? modelo;
  final dynamic capacidadKg;
  final String? estado;

  Camion({
    required this.id,
    this.placa,
    this.modelo,
    this.capacidadKg,
    this.estado,
  });

  factory Camion.fromJson(Map<String, dynamic> json) => Camion(
        id: intOrNull(json['id'])!,
        placa: json['placa'] as String?,
        modelo: json['modelo'] as String?,
        capacidadKg: json['capacidad_kg'],
        estado: json['estado'] as String?,
      );
}
