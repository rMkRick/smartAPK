import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_apk/controllers/admin_controller.dart';
import 'package:smart_apk/services/api_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AdminController.cargarTodo', () {
    late AdminController controller;
    setUp(() => controller = AdminController());
    tearDown(() => ApiService.client = http.Client());

    test('puebla conductores/camiones/rutas tipados desde el backend', () async {
      ApiService.client = MockClient((request) async {
        if (request.url.path.contains('/conductores')) {
          return http.Response(
            jsonEncode([
              {'id': 1, 'nombres': 'Luis', 'apellidos': 'Ramirez', 'conductor_estado': 'activo'},
            ]),
            200,
          );
        }
        if (request.url.path.contains('/camiones')) {
          return http.Response(
            jsonEncode([
              {'id': 1, 'placa': 'ABC-123', 'estado': 'disponible'},
            ]),
            200,
          );
        }
        if (request.url.path.contains('/rutas-gestion')) {
          return http.Response(
            jsonEncode([
              {'id': 1, 'nombre': 'Ruta Centro'},
            ]),
            200,
          );
        }
        return http.Response('[]', 200);
      });

      final ok = await controller.cargarTodo();

      expect(ok, isTrue);
      expect(controller.cargando, isFalse);
      expect(controller.conductores, hasLength(1));
      expect(controller.conductores.first.nombres, 'Luis');
      expect(controller.camiones.first.placa, 'ABC-123');
      expect(controller.rutas.first.nombre, 'Ruta Centro');
    });

    test('devuelve false y no revienta si el servidor falla', () async {
      ApiService.client = MockClient((request) async {
        throw Exception('servidor caído');
      });

      final ok = await controller.cargarTodo();

      expect(ok, isFalse);
      expect(controller.cargando, isFalse);
    });
  });

  group('AdminController — acciones CRUD delegan a ApiService', () {
    late AdminController controller;
    setUp(() => controller = AdminController());
    tearDown(() => ApiService.client = http.Client());

    test('cambiarEstadoConductor hace PUT y relaya el mensaje del backend', () async {
      ApiService.client = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.url.path, contains('/conductores/1/estado'));
        return http.Response(jsonEncode({'mensaje': 'Estado actualizado'}), 200);
      });

      final resp = await controller.cambiarEstadoConductor(1, 'inactivo');
      expect(resp['mensaje'], 'Estado actualizado');
    });

    test('crearConductor, actualizarConductor, asignarRuta, cambiarEstadoCamion y actualizarCamion delegan a ApiService', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode({'mensaje': 'ok'}), 200);
      });

      expect((await controller.crearConductor({'nombres': 'Ana'}))['mensaje'], 'ok');
      expect((await controller.actualizarConductor(1, {'nombres': 'Ana'}))['mensaje'], 'ok');
      expect((await controller.asignarRuta({'ruta_id': 1}))['mensaje'], 'ok');
      expect((await controller.cambiarEstadoCamion(1, 'mantenimiento'))['mensaje'], 'ok');
      expect((await controller.actualizarCamion(1, {'placa': 'XYZ-1'}))['mensaje'], 'ok');
    });
  });

  group('AdminController — sesión', () {
    test('loadUser lee la sesión guardada en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'usuario': jsonEncode({'id': 1, 'nombres': 'Admin'}),
      });
      final controller = AdminController();

      await controller.loadUser();

      expect(controller.usuario?.nombres, 'Admin');
    });

    test('logout limpia la sesión de SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'token': 'jwt-1'});
      final controller = AdminController();

      await controller.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), isNull);
    });
  });
}
