import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_apk/controllers/supervisor_controller.dart';
import 'package:smart_apk/services/api_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SupervisorController.cargarTodo', () {
    late SupervisorController controller;
    setUp(() => controller = SupervisorController());
    tearDown(() => ApiService.client = http.Client());

    test('puebla rutas/camiones/conductores/horarios tipados', () async {
      ApiService.client = MockClient((request) async {
        final path = request.url.path;
        if (path.contains('/rutas-gestion')) {
          return http.Response(jsonEncode([{'id': 1, 'nombre': 'Ruta A'}]), 200);
        }
        if (path.contains('/camiones')) {
          return http.Response(jsonEncode([{'id': 1, 'placa': 'AAA-111'}]), 200);
        }
        if (path.contains('/conductores')) {
          return http.Response(jsonEncode([{'id': 1, 'nombres': 'Ana'}]), 200);
        }
        if (path.contains('/horarios')) {
          return http.Response(jsonEncode([{'id': 1, 'dia_semana': 'Lunes'}]), 200);
        }
        return http.Response('[]', 200);
      });

      final ok = await controller.cargarTodo();

      expect(ok, isTrue);
      expect(controller.rutas.first.nombre, 'Ruta A');
      expect(controller.camiones.first.placa, 'AAA-111');
      expect(controller.conductores.first.nombres, 'Ana');
      expect(controller.horarios.first.diaSemana, 'Lunes');
    });

    test('devuelve false cuando el servidor falla', () async {
      ApiService.client = MockClient((request) async => throw Exception('caído'));
      final ok = await controller.cargarTodo();
      expect(ok, isFalse);
    });
  });

  group('SupervisorController — reportes ciudadanos', () {
    late SupervisorController controller;
    setUp(() => controller = SupervisorController());
    tearDown(() => ApiService.client = http.Client());

    test('cargarReportes puebla la lista tipada', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'id': 1, 'estado': 'enviado'},
            {'id': 2, 'estado': 'completado'},
          ]),
          200,
        );
      });

      final ok = await controller.cargarReportes();

      expect(ok, isTrue);
      expect(controller.reportes, hasLength(2));
    });

    test('reportesFiltrados aplica el filtro por estado', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {'id': 1, 'estado': 'enviado'},
            {'id': 2, 'estado': 'completado'},
          ]),
          200,
        );
      });
      await controller.cargarReportes();

      controller.setFiltroReporte('completado');

      expect(controller.reportesFiltrados, hasLength(1));
      expect(controller.reportesFiltrados.first.id, 2);
    });

    test('asignarRuta, cambiarEstadoCamion, cambiarEstadoConductor y responderReporte delegan a ApiService', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode({'mensaje': 'ok'}), 200);
      });

      expect((await controller.asignarRuta({'ruta_id': 1}))['mensaje'], 'ok');
      expect((await controller.cambiarEstadoCamion(1, 'disponible'))['mensaje'], 'ok');
      expect((await controller.cambiarEstadoConductor(1, 'activo'))['mensaje'], 'ok');
      expect((await controller.responderReporte(1, {'estado': 'atendido'}))['mensaje'], 'ok');
    });
  });

  group('SupervisorController — sesión', () {
    test('loadUser lee la sesión guardada en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'usuario': jsonEncode({'id': 1, 'nombres': 'Super'}),
      });
      final controller = SupervisorController();

      await controller.loadUser();

      expect(controller.usuario?.nombres, 'Super');
    });

    test('logout limpia la sesión de SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'token': 'jwt-1'});
      final controller = SupervisorController();

      await controller.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), isNull);
    });
  });
}
