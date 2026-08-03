import 'package:flutter_test/flutter_test.dart';
import 'package:smart_apk/models/horario.dart';

void main() {
  group('Horario.fromJson', () {
    test('mapea un horario completo', () {
      final h = Horario.fromJson({
        'id': 8,
        'ruta_id': 5,
        'dia_semana': 'Lunes',
        'hora_inicio': '09:00:00',
        'hora_fin': '12:00:00',
        'ruta_nombre': 'Ruta Centro',
        'zona_nombre': 'Centro Histórico',
        'tipo_residuo': 'Orgánico',
      });

      expect(h.id, 8);
      expect(h.rutaId, 5);
      expect(h.diaSemana, 'Lunes');
      expect(h.rutaNombre, 'Ruta Centro');
    });
  });
}
