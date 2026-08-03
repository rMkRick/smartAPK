// Pruebas de integracion: corren la app COMPLETA (Navigator real,
// transiciones reales) en un dispositivo/desktop de verdad, a diferencia
// de los widget tests que corren en un ambiente simulado dentro de
// `flutter test`. Se siguen fakeando red/GPS/camara con los mismos
// mocks/fakes de test/support/ para no depender de un backend real ni
// de hardware real.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_apk/main.dart';
import 'package:smart_apk/services/api_service.dart';

import '../test/support/fake_platform_interfaces.dart';

// LandingScreen carga una imagen de fondo desde internet real (NetworkImage);
// en un integration test la app corre de verdad, y si no hay salida a
// internet esa carga nunca termina. pumpAndSettle() espera a que TODO
// termine de animar/repintar y se cuelga por eso. En vez de eso avanzamos
// el reloj un tiempo acotado: alcanza para que las transiciones de
// Navigator y las respuestas fakeadas (instantáneas) se reflejen en pantalla.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GeolocatorPlatform.instance = FakeGeolocatorPlatform();
  });

  tearDown(() {
    ApiService.client = http.Client();
  });

  testWidgets('Flujo: login de ciudadano llega a su dashboard', (tester) async {
    ApiService.client = MockClient((request) async {
      if (request.url.path.endsWith('/auth/login')) {
        return http.Response(
          jsonEncode({
            'token': 'jwt-fake',
            'usuario': {'id': 1, 'nombres': 'Juan', 'correo': 'juan@test.com', 'rol': 1},
          }),
          200,
        );
      }
      // fetchReports() al entrar al dashboard.
      return http.Response(jsonEncode([]), 200);
    });

    await tester.pumpWidget(const SmartAPkApp());
    await settle(tester);

    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), 'juan@test.com');
    await tester.enterText(campos.at(1), 'Secreta123');
    await tester.tap(find.text('ENTRAR'));
    await settle(tester);

    expect(find.text('MUNI CUSCO'), findsNothing);
  });

  testWidgets('Flujo: reporte de invitado se envia y muestra el ticket', (tester) async {
    ImagePickerPlatform.instance = FakeImagePickerPlatform();
    ApiService.client = MockClient((request) async {
      return http.Response(jsonEncode({'numero_ticket': 'TCK-INT-1'}), 200);
    });

    await tester.pumpWidget(const SmartAPkApp());
    await settle(tester);

    await tester.tap(find.text('Registrar Reporte Residuos'));
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, 'Hay basura acumulada en la esquina');
    await tester.tap(find.text('ENVIAR REPORTE AHORA'));
    await settle(tester);

    expect(find.text('Reporte Enviado'), findsOneWidget);
    expect(find.textContaining('TCK-INT-1'), findsOneWidget);
  });
}
