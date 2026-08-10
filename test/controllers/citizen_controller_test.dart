import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_apk/controllers/citizen_controller.dart';
import 'package:smart_apk/models/usuario.dart';
import 'package:smart_apk/services/api_service.dart';

import '../support/fake_platform_interfaces.dart';

void main() {
  group('CitizenController.submitReport — validaciones sin red ni GPS', () {
    late CitizenController controller;
    setUp(() => controller = CitizenController());

    test('rechaza si no hay foto', () async {
      final outcome = await controller.submitReport('hay basura acumulada');
      expect(outcome.success, isFalse);
      expect(outcome.message, contains('foto'));
    });

    test('rechaza si hay foto pero no hay ubicación', () async {
      controller.imageFile = File('evidencia.jpg'); // no necesita existir en disco
      final outcome = await controller.submitReport('hay basura acumulada');
      expect(outcome.success, isFalse);
      expect(outcome.message, contains('GPS'));
    });
  });

  group('CitizenController — estado puro del mapa', () {
    test('selectPickedPosition fija la ubicación elegida a mano', () {
      final controller = CitizenController();
      controller.selectPickedPosition(const LatLng(-13.5, -71.9));

      expect(controller.pickedPosition, const LatLng(-13.5, -71.9));
      expect(controller.ubicacionEfectiva, const LatLng(-13.5, -71.9));
    });

    test('clearPickedPosition la limpia', () {
      final controller = CitizenController();
      controller.selectPickedPosition(const LatLng(-13.5, -71.9));
      controller.clearPickedPosition();

      expect(controller.pickedPosition, isNull);
    });
  });

  group('CitizenController.logout', () {
    test('limpia la sesión de SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({'token': 'jwt-123'});
      final controller = CitizenController();

      await controller.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('token'), isNull);
    });
  });

  group('CitizenController.pickImage — con ImagePickerPlatform fakeado', () {
    test('guarda el archivo que "elige" el usuario', () async {
      ImagePickerPlatform.instance = FakeImagePickerPlatform()..nextImagePath = 'foto_evidencia.jpg';
      final controller = CitizenController();

      await controller.pickImage(ImageSource.camera);

      expect(controller.imageFile?.path, 'foto_evidencia.jpg');
    });

    test('no cambia nada si el usuario cancela la selección', () async {
      ImagePickerPlatform.instance = FakeImagePickerPlatform()..nextImagePath = null;
      final controller = CitizenController();

      await controller.pickImage(ImageSource.gallery);

      expect(controller.imageFile, isNull);
    });
  });

  group('CitizenController.startLocationTracking — con GeolocatorPlatform fakeado', () {
    test('si el servicio de ubicación está apagado, deja de cargar sin posición', () async {
      GeolocatorPlatform.instance = FakeGeolocatorPlatform()..serviceEnabled = false;
      final controller = CitizenController();

      controller.startLocationTracking();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.isLocationLoading, isFalse);
      expect(controller.currentPosition, isNull);
    });

    test('si el permiso queda denegado, deja de cargar sin posición', () async {
      GeolocatorPlatform.instance = FakeGeolocatorPlatform()..permission = LocationPermission.denied;
      final controller = CitizenController();

      controller.startLocationTracking();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.isLocationLoading, isFalse);
      expect(controller.currentPosition, isNull);
    });

    test('cuando el GPS reporta una posición, la expone y deja de cargar', () async {
      final fakeGeo = FakeGeolocatorPlatform();
      GeolocatorPlatform.instance = fakeGeo;
      final controller = CitizenController();

      controller.startLocationTracking();
      await Future.delayed(const Duration(milliseconds: 20));
      fakeGeo.emitPosition(fakeGeo.currentPosition!);
      await Future.delayed(const Duration(milliseconds: 20));

      expect(controller.isLocationLoading, isFalse);
      expect(controller.currentPosition?.latitude, closeTo(-13.5319, 0.0001));
    });
  });

  group('CitizenController.fetchReports / deleteReport', () {
    late CitizenController controller;

    setUp(() {
      controller = CitizenController();
      controller.usuario = Usuario(id: 42);
    });

    tearDown(() => ApiService.client = http.Client());

    test('fetchReports puebla misReportes desde el JSON del backend', () async {
      ApiService.client = MockClient((request) async {
        expect(request.url.path, contains('/reportes/usuario/42'));
        return http.Response(
          jsonEncode([
            {'id': 1, 'numero_ticket': 'TCK-1', 'estado': 'enviado'},
            {'id': 2, 'numero_ticket': 'TCK-2', 'estado': 'atendido'},
          ]),
          200,
        );
      });

      await controller.fetchReports();

      expect(controller.misReportes, hasLength(2));
      expect(controller.misReportes.first.numeroTicket, 'TCK-1');
    });

    test('deleteReport llama al backend y refresca la lista', () async {
      var deleteCalled = false;
      ApiService.client = MockClient((request) async {
        if (request.method == 'DELETE') {
          deleteCalled = true;
          return http.Response(jsonEncode({'mensaje': 'Reporte eliminado'}), 200);
        }
        return http.Response(jsonEncode([]), 200);
      });

      final mensaje = await controller.deleteReport(1);

      expect(deleteCalled, isTrue);
      expect(mensaje, 'Reporte eliminado');
      expect(controller.misReportes, isEmpty);
    });
  });

  group('CitizenController.submitReport — flujo completo de éxito', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('smartapk_test_');
    });

    tearDown(() {
      ApiService.client = http.Client();
      tempDir.deleteSync(recursive: true);
    });

    test('sube la foto, crea el reporte, limpia el formulario y refresca la lista', () async {
      final photoFile = File('${tempDir.path}/evidencia.jpg')..writeAsBytesSync([0, 1, 2, 3]);

      final controller = CitizenController();
      controller.usuario = Usuario(id: 7);
      controller.imageFile = photoFile;
      controller.selectPickedPosition(const LatLng(-13.53, -71.96));

      var uploadCalled = false;
      var createCalled = false;
      ApiService.client = MockClient((request) async {
        final path = request.url.path;
        if (path.endsWith('/reportes/upload')) {
          uploadCalled = true;
          return http.Response(jsonEncode({'foto_url': 'https://cdn/evidencia.jpg'}), 200);
        }
        if (request.method == 'POST' && path.endsWith('/reportes')) {
          createCalled = true;
          return http.Response(jsonEncode({'numero_ticket': 'TCK-99'}), 200);
        }
        // Llamada de fetchReports() al refrescar tras enviar.
        return http.Response(jsonEncode([]), 200);
      });

      final outcome = await controller.submitReport('  hay basura acumulada  ');

      expect(outcome.success, isTrue);
      expect(outcome.message, contains('TCK-99'));
      expect(uploadCalled, isTrue);
      expect(createCalled, isTrue);
      expect(controller.imageFile, isNull);
    });
  });
}
