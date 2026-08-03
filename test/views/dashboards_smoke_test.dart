// Smoke tests: solo verifican que cada dashboard se construye sin lanzar
// excepciones al montarse (con dependencias externas fakeadas), no que cada
// interacción sea correcta. Sirven para subir la cobertura del código de
// construcción de UI que hoy no toca ningún test.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:smart_apk/services/api_service.dart';
import 'package:smart_apk/views/admin_dashboard.dart';
import 'package:smart_apk/views/citizen_dashboard.dart';
import 'package:smart_apk/views/guest_report_screen.dart';
import 'package:smart_apk/views/operador_dashboard.dart';
import 'package:smart_apk/views/supervisor_dashboard.dart';

import '../support/fake_platform_interfaces.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Cualquier GET/POST del ApiService responde con una lista vacía: alcanza
    // para que los controllers terminen su carga inicial sin red real.
    ApiService.client = MockClient((request) async {
      return http.Response(jsonEncode([]), 200);
    });
    GeolocatorPlatform.instance = FakeGeolocatorPlatform();
  });

  tearDown(() {
    ApiService.client = http.Client();
  });

  testWidgets('AdminDashboard renderiza sin crashear', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AdminDashboard()));
    await tester.pump();
    expect(find.byType(AdminDashboard), findsOneWidget);
  });

  testWidgets('OperadorDashboard renderiza sin crashear', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OperadorDashboard()));
    await tester.pump();
    expect(find.byType(OperadorDashboard), findsOneWidget);
  });

  testWidgets('SupervisorDashboard renderiza sin crashear', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SupervisorDashboard()));
    await tester.pump();
    expect(find.byType(SupervisorDashboard), findsOneWidget);
  });

  testWidgets('GuestReportScreen renderiza sin crashear', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GuestReportScreen()));
    await tester.pump();
    expect(find.byType(GuestReportScreen), findsOneWidget);
  });

  testWidgets('CitizenDashboard renderiza sin crashear', (tester) async {
    SharedPreferences.setMockInitialValues({
      'usuario': jsonEncode({'id': 1, 'nombres': 'Juan', 'correo': 'juan@test.com'}),
    });
    await tester.pumpWidget(const MaterialApp(home: CitizenDashboard()));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(CitizenDashboard), findsOneWidget);
  });
}
