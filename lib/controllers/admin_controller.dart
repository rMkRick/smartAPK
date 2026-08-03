import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/camion.dart';
import '../models/conductor.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';

/// Controller MVC de AdminDashboard: sesión y gestión de conductores,
/// camiones y rutas. Media entre la View y ApiService (el Modelo de datos);
/// la View nunca llama a ApiService directamente.
class AdminController extends ChangeNotifier {
  Usuario? usuario;
  bool cargando = true;

  List<Conductor> conductores = [];
  List<Camion> camiones = [];
  List<Ruta> rutas = [];

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('usuario');
    if (userStr != null) {
      usuario = Usuario.fromJson(jsonDecode(userStr));
      notifyListeners();
    }
  }

  Future<bool> cargarTodo() async {
    cargando = true;
    notifyListeners();
    try {
      final resultados = await Future.wait([
        ApiService.getConductores(),
        ApiService.getCamiones(),
        ApiService.getRutasGestion(),
      ]);
      conductores = resultados[0].map((e) => Conductor.fromJson(e as Map<String, dynamic>)).toList();
      camiones = resultados[1].map((e) => Camion.fromJson(e as Map<String, dynamic>)).toList();
      rutas = resultados[2].map((e) => Ruta.fromJson(e as Map<String, dynamic>)).toList();
      return true;
    } catch (e) {
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> cambiarEstadoConductor(int id, String estado) =>
      ApiService.cambiarEstadoConductor(id, estado);

  Future<Map<String, dynamic>> crearConductor(Map<String, dynamic> datos) => ApiService.crearConductor(datos);

  Future<Map<String, dynamic>> actualizarConductor(int id, Map<String, dynamic> datos) =>
      ApiService.actualizarConductor(id, datos);

  Future<Map<String, dynamic>> asignarRuta(Map<String, dynamic> datos) => ApiService.asignarRuta(datos);

  Future<Map<String, dynamic>> cambiarEstadoCamion(int id, String estado) =>
      ApiService.cambiarEstadoCamion(id, estado);

  Future<Map<String, dynamic>> actualizarCamion(int id, Map<String, dynamic> datos) =>
      ApiService.actualizarCamion(id, datos);

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
