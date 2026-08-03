import 'package:flutter_test/flutter_test.dart';
import 'package:smart_apk/models/camion.dart';

void main() {
  group('Camion.fromJson', () {
    test('mapea un camión completo', () {
      final cam = Camion.fromJson({
        'id': 2,
        'placa': 'XYZ-987',
        'modelo': 'Volvo FMX',
        'capacidad_kg': 5000,
        'estado': 'disponible',
      });

      expect(cam.id, 2);
      expect(cam.placa, 'XYZ-987');
      expect(cam.modelo, 'Volvo FMX');
      expect(cam.capacidadKg, 5000);
      expect(cam.estado, 'disponible');
    });

    test('capacidad_kg puede venir como string (se conserva sin parsear en el modelo)', () {
      final cam = Camion.fromJson({'id': 1, 'capacidad_kg': '3000'});
      expect(cam.capacidadKg, '3000');
    });
  });
}
