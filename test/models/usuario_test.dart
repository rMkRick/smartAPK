import 'package:flutter_test/flutter_test.dart';
import 'package:smart_apk/models/usuario.dart';

void main() {
  group('Usuario.fromJson', () {
    test('mapea todos los campos cuando vienen presentes', () {
      final usuario = Usuario.fromJson({
        'id': 7,
        'nombres': 'Juan',
        'apellidos': 'Perez',
        'nombre': 'Juan Perez',
        'correo': 'juan@smartapk.com',
        'rol': 3,
      });

      expect(usuario.id, 7);
      expect(usuario.nombres, 'Juan');
      expect(usuario.apellidos, 'Perez');
      expect(usuario.nombre, 'Juan Perez');
      expect(usuario.correo, 'juan@smartapk.com');
      expect(usuario.rol, 3);
    });

    test('acepta campos ausentes como null', () {
      final usuario = Usuario.fromJson({'id': 1});

      expect(usuario.id, 1);
      expect(usuario.nombres, isNull);
      expect(usuario.rol, isNull);
    });

    test('castea un id numérico double (sin decimales) a int', () {
      final usuario = Usuario.fromJson({'id': 5.0, 'rol': 1.0});

      expect(usuario.id, 5);
      expect(usuario.rol, 1);
    });
  });
}
