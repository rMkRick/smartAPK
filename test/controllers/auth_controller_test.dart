import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_apk/controllers/auth_controller.dart';
import 'package:smart_apk/services/api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthController.register — validación (sin red)', () {
    late AuthController controller;
    setUp(() => controller = AuthController());

    test('rechaza campos vacíos', () async {
      final outcome = await controller.register(
        nombres: '', apellidos: '', dni: '', correo: '', contrasena: '');
      expect(outcome.success, isFalse);
      expect(outcome.message, contains('completa todos los campos'));
    });

    test('rechaza nombres de 3 letras o menos', () async {
      final outcome = await controller.register(
        nombres: 'Ana', apellidos: 'Gomez', dni: '12345678',
        correo: 'ana@smartapk.com', contrasena: 'Clave123');
      expect(outcome.success, isFalse);
      expect(outcome.message, contains('nombres'));
    });

    test('rechaza un DNI que no tiene 8 dígitos', () async {
      final outcome = await controller.register(
        nombres: 'Andrea', apellidos: 'Gomez', dni: '123',
        correo: 'andrea@smartapk.com', contrasena: 'Clave123');
      expect(outcome.success, isFalse);
      expect(outcome.message, contains('DNI'));
    });

    test('rechaza un correo con formato inválido', () async {
      final outcome = await controller.register(
        nombres: 'Andrea', apellidos: 'Gomez', dni: '12345678',
        correo: 'no-es-correo', contrasena: 'Clave123');
      expect(outcome.success, isFalse);
      expect(outcome.message, contains('correo'));
    });

    test('rechaza una contraseña sin mayúsculas', () async {
      final outcome = await controller.register(
        nombres: 'Andrea', apellidos: 'Gomez', dni: '12345678',
        correo: 'andrea@smartapk.com', contrasena: 'clave123');
      expect(outcome.success, isFalse);
      expect(outcome.message, contains('mayúscula'));
    });
  });

  group('AuthController.register — con servidor simulado', () {
    late AuthController controller;
    setUp(() => controller = AuthController());
    tearDown(() => ApiService.client = http.Client());

    test('éxito cuando el backend responde con mensaje de éxito', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode({'mensaje': 'Registro con éxito'}), 200);
      });

      final outcome = await controller.register(
        nombres: 'Andrea', apellidos: 'Gomez', dni: '12345678',
        correo: 'andrea@smartapk.com', contrasena: 'Clave123');

      expect(outcome.success, isTrue);
      expect(controller.isRegistering, isFalse);
    });

    test('propaga el mensaje de error del backend (p. ej. correo duplicado)', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode({'mensaje': 'El correo ya está registrado'}), 200);
      });

      final outcome = await controller.register(
        nombres: 'Andrea', apellidos: 'Gomez', dni: '12345678',
        correo: 'andrea@smartapk.com', contrasena: 'Clave123');

      expect(outcome.success, isFalse);
      expect(outcome.message, 'El correo ya está registrado');
    });
  });

  group('AuthController.login', () {
    late AuthController controller;
    setUp(() => controller = AuthController());
    tearDown(() => ApiService.client = http.Client());

    test('éxito: guarda token/usuario y expone el Usuario tipado', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'token': 'jwt-123',
            'usuario': {'id': 1, 'nombres': 'Ana', 'rol': 1},
          }),
          200,
        );
      });

      final outcome = await controller.login('ana@smartapk.com', 'Clave123');

      expect(outcome.success, isTrue);
      expect(controller.usuario?.id, 1);
      expect(controller.usuario?.rol, 1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), 'jwt-123');
    });

    test('falla cuando el backend no devuelve token', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode({'mensaje': 'Credenciales inválidas'}), 200);
      });

      final outcome = await controller.login('ana@smartapk.com', 'mala');

      expect(outcome.success, isFalse);
      expect(outcome.message, 'Credenciales inválidas');
    });

    test('falla con mensaje genérico si el servidor no responde', () async {
      // ApiService.login ya atrapa la excepción de red y devuelve su propio
      // mensaje (sin 'token'), por lo que AuthController lo relaya tal cual.
      ApiService.client = MockClient((request) async {
        throw Exception('sin conexión');
      });

      final outcome = await controller.login('ana@smartapk.com', 'Clave123');

      expect(outcome.success, isFalse);
      expect(outcome.message, contains('conectar'));
    });
  });
}
