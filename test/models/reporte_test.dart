import 'package:flutter_test/flutter_test.dart';
import 'package:smart_apk/models/reporte.dart';

void main() {
  group('Reporte.fromJson', () {
    test('mapea un reporte completo (vista de supervisor)', () {
      final rep = Reporte.fromJson({
        'id': 12,
        'usuario_id': 3,
        'numero_ticket': 'TCK-001',
        'descripcion': 'Basura acumulada',
        'estado': 'en_proceso',
        'comentario_admin': null,
        'respuesta_supervisor': 'Se envió al camión',
        'fecha_creacion': '2026-01-15T10:00:00.000Z',
        'foto_url': 'https://example.com/foto.jpg',
        'latitud': -13.53,
        'longitud': -71.96,
        'nombres': 'Ana',
        'apellidos': 'Gomez',
        'correo': 'ana@smartapk.com',
        'tipo_residuo': 'Orgánico',
      });

      expect(rep.id, 12);
      expect(rep.usuarioId, 3);
      expect(rep.numeroTicket, 'TCK-001');
      expect(rep.estado, 'en_proceso');
      expect(rep.respuestaSupervisor, 'Se envió al camión');
      expect(rep.fechaCreacion, '2026-01-15T10:00:00.000Z');
      expect(rep.latitud, -13.53);
      expect(rep.tipoResiduo, 'Orgánico');
    });

    test('requiere id pero acepta el resto ausente', () {
      final rep = Reporte.fromJson({'id': 1});

      expect(rep.id, 1);
      expect(rep.numeroTicket, isNull);
      expect(rep.estado, isNull);
    });
  });
}
