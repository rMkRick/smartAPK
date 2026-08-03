import 'package:flutter_test/flutter_test.dart';
import 'package:smart_apk/models/ruta.dart';

void main() {
  group('Ruta.fromJson', () {
    test('mapea una ruta asignada con waypoints', () {
      final ruta = Ruta.fromJson({
        'id': 5,
        'nombre': 'Ruta Centro',
        'descripcion': 'Recojo diario',
        'zona_nombre': 'Centro Histórico',
        'camion_id': 2,
        'placa': 'XYZ-987',
        'modelo': 'Volvo FMX',
        'fecha_asignacion': '2026-01-15',
        'hora_inicio': '20:00:00',
        'hora_fin': '23:00:00',
        'operador_nombres': 'Luis',
        'operador_apellidos': 'Ramirez',
        'waypoints': [
          {'lat': -13.5, 'lng': -71.9},
          {'lat': -13.51, 'lng': -71.91},
        ],
      });

      expect(ruta.id, 5);
      expect(ruta.zonaNombre, 'Centro Histórico');
      expect(ruta.camionId, 2);
      expect(ruta.waypoints, hasLength(2));
    });

    test('ruta libre (sin camión) deja camionId y waypoints en null', () {
      final ruta = Ruta.fromJson({'id': 1, 'nombre': 'Ruta Libre'});

      expect(ruta.camionId, isNull);
      expect(ruta.waypoints, isNull);
    });
  });
}
