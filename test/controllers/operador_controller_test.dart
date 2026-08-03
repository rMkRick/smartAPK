import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_apk/controllers/operador_controller.dart';

void main() {
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
}
