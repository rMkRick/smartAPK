import 'package:flutter_test/flutter_test.dart';
import 'package:smart_apk/models/conductor.dart';

void main() {
  group('Conductor.fromJson', () {
    test('mapea un conductor completo', () {
      final c = Conductor.fromJson({
        'id': 4,
        'usuario_id': 9,
        'nombres': 'Luis',
        'apellidos': 'Ramirez',
        'dni': '12345678',
        'correo': 'luis@smartapk.com',
        'telefono': '999888777',
        'licencia': 'A2b',
        'categoria_licencia': 'BIIIC',
        'fecha_ingreso': '2024-03-01',
        'conductor_estado': 'activo',
        'usuario_estado': 'activo',
        'ruta_actual': 'Centro Histórico',
        'camion_actual': 'ABC-123',
      });

      expect(c.id, 4);
      expect(c.usuarioId, 9);
      expect(c.nombres, 'Luis');
      expect(c.conductorEstado, 'activo');
      expect(c.rutaActual, 'Centro Histórico');
      expect(c.camionActual, 'ABC-123');
    });

    test('conductor sin ruta asignada deja los campos opcionales en null', () {
      final c = Conductor.fromJson({'id': 1, 'conductor_estado': 'inactivo'});

      expect(c.rutaActual, isNull);
      expect(c.camionActual, isNull);
      expect(c.conductorEstado, 'inactivo');
    });
  });
}
