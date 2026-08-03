import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';

/// Controller MVC de OperadorDashboard: sesión del operador/recolector.
class OperadorController extends ChangeNotifier {
  Usuario? usuario;

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('usuario');
    if (userStr != null) {
      usuario = Usuario.fromJson(jsonDecode(userStr));
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
