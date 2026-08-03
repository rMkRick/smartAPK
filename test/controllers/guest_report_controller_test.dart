import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:smart_apk/controllers/guest_report_controller.dart';
import 'package:smart_apk/services/api_service.dart';

import '../support/fake_platform_interfaces.dart';

void main() {
  test('GuestReportController arranca sin foto, sin ubicación y sin cargar', () {
    final controller = GuestReportController();

    expect(controller.imageFile, isNull);
    expect(controller.currentPosition, isNull);
    expect(controller.isLoading, isFalse);
  });

  group('GuestReportController.pickImage — con ImagePickerPlatform fakeado', () {
    test('guarda el archivo que "elige" el usuario', () async {
      ImagePickerPlatform.instance = FakeImagePickerPlatform()..nextImagePath = 'foto_guest.jpg';
      final controller = GuestReportController();

      await controller.pickImage();

      expect(controller.imageFile?.path, 'foto_guest.jpg');
    });

    test('no cambia nada si el usuario cancela la selección', () async {
      ImagePickerPlatform.instance = FakeImagePickerPlatform()..nextImagePath = null;
      final controller = GuestReportController();

      await controller.pickImage();

      expect(controller.imageFile, isNull);
    });
  });

  group('GuestReportController.submitReport — con GeolocatorPlatform fakeado', () {
    tearDown(() => ApiService.client = http.Client());

    test('falla si el servicio de ubicación está apagado', () async {
      GeolocatorPlatform.instance = FakeGeolocatorPlatform()..serviceEnabled = false;
      final controller = GuestReportController();

      final outcome = await controller.submitReport('hay basura acumulada');

      expect(outcome.success, isFalse);
      expect(outcome.message, contains('ubicación'));
      expect(controller.isLoading, isFalse);
    });

    test('falla si el permiso de ubicación queda denegado', () async {
      GeolocatorPlatform.instance = FakeGeolocatorPlatform()..permission = LocationPermission.denied;
      final controller = GuestReportController();

      final outcome = await controller.submitReport('hay basura acumulada');

      expect(outcome.success, isFalse);
      expect(controller.isLoading, isFalse);
    });

    test('éxito: envía el reporte y devuelve el número de ticket', () async {
      GeolocatorPlatform.instance = FakeGeolocatorPlatform();
      ApiService.client = MockClient((request) async {
        expect(request.url.path, endsWith('/reports'));
        return http.Response(jsonEncode({'numero_ticket': 'TCK-77'}), 200);
      });
      final controller = GuestReportController();

      final outcome = await controller.submitReport('hay basura acumulada');

      expect(outcome.success, isTrue);
      expect(outcome.message, 'TCK-77');
      expect(controller.isLoading, isFalse);
    });
  });
}
