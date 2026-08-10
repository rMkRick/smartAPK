import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_apk/controllers/operador_controller.dart';
import 'package:smart_apk/services/api_service.dart';

import '../support/fake_platform_interfaces.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ApiService.client = MockClient((request) async => http.Response(jsonEncode([]), 200));
  });

  tearDown(() {
    ApiService.client = http.Client();
  });

  group('OperadorController', () {
    test('loadUser lee la sesión guardada en SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'usuario': jsonEncode({'id': 9, 'nombres': 'Carlos', 'rol': 2}),
      });

      final controller = OperadorController();
      await controller.loadUser();

      expect(controller.usuario?.id, 9);
      expect(controller.usuario?.nombres, 'Carlos');
    });

    test('loadUser no cambia usuario si no hay sesión guardada', () async {
      SharedPreferences.setMockInitialValues({});

      final controller = OperadorController();
      await controller.loadUser();

      expect(controller.usuario, isNull);
    });

    test('logout limpia la sesión de SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'token': 'jwt-123'});

      final controller = OperadorController();
      await controller.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), isNull);
    });
  });

  group('OperadorController.cargarRutaAsignada', () {
    test('encuentra la ruta cuyo operador coincide con el usuario logueado', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode([
          {
            'id': 1,
            'nombre': 'Ruta Centro',
            'camion_id': 2,
            'operador_nombres': 'Carlos',
            'operador_apellidos': 'Ramirez',
            'waypoints': [
              {'lat': -13.5, 'lng': -71.9},
            ],
          },
          {'id': 2, 'nombre': 'Ruta de otro operador', 'camion_id': 3, 'operador_nombres': 'Ana', 'operador_apellidos': 'Lopez'},
        ]), 200);
      });

      final controller = OperadorController();
      SharedPreferences.setMockInitialValues({
        'usuario': jsonEncode({'id': 9, 'nombres': 'Carlos', 'apellidos': 'Ramirez', 'rol': 2}),
      });
      await controller.loadUser();

      expect(controller.rutaAsignada?.id, 1);
      expect(controller.cargandoRuta, isFalse);
    });

    test('deja rutaAsignada en null si ninguna ruta coincide con el operador', () async {
      ApiService.client = MockClient((request) async {
        return http.Response(jsonEncode([
          {'id': 2, 'nombre': 'Ruta de otro operador', 'camion_id': 3, 'operador_nombres': 'Ana', 'operador_apellidos': 'Lopez'},
        ]), 200);
      });

      final controller = OperadorController();
      SharedPreferences.setMockInitialValues({
        'usuario': jsonEncode({'id': 9, 'nombres': 'Carlos', 'apellidos': 'Ramirez', 'rol': 2}),
      });
      await controller.loadUser();

      expect(controller.rutaAsignada, isNull);
    });
  });

  group('OperadorController.iniciarRuta', () {
    late FakeGeolocatorPlatform fakeGeo;
    setUp(() {
      fakeGeo = FakeGeolocatorPlatform();
      GeolocatorPlatform.instance = fakeGeo;
    });

    test('activa el GPS y guarda la posición actual cuando hay permiso', () async {
      final controller = OperadorController();
      final ok = await controller.iniciarRuta();

      expect(ok, isTrue);
      expect(controller.currentPosition, isNotNull);
      expect(controller.errorGps, isNull);
    });

    test('falla con mensaje si el servicio de ubicación está apagado', () async {
      fakeGeo.serviceEnabled = false;
      final controller = OperadorController();
      final ok = await controller.iniciarRuta();

      expect(ok, isFalse);
      expect(controller.errorGps, isNotNull);
    });

    test('falla con mensaje si se deniega el permiso de ubicación', () async {
      fakeGeo.permission = LocationPermission.denied;
      final controller = OperadorController();
      final ok = await controller.iniciarRuta();

      expect(ok, isFalse);
      expect(controller.errorGps, isNotNull);
    });
  });
}
