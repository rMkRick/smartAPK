import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/camion.dart';
import '../models/conductor.dart';
import '../models/horario.dart';
import '../models/reporte.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';

/// Controller MVC de SupervisorDashboard: sesión, gestión de rutas/camiones/
/// conductores/horarios y atención de reportes ciudadanos. Media entre la
/// View y ApiService (Modelo); la View nunca llama a ApiService directamente.
class SupervisorController extends ChangeNotifier {
  Usuario? usuario;
  bool cargando = true;

  List<Ruta> rutas = [];
  List<Camion> camiones = [];
  List<Conductor> conductores = [];
  List<Horario> horarios = [];

  List<Reporte> reportes = [];
  bool cargandoReportes = true;
  String filtroReporte = 'todos';

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
        ApiService.getRutasGestion(),
        ApiService.getCamiones(),
        ApiService.getConductores(),
        ApiService.getHorarios(),
      ]);
      rutas = resultados[0].map((e) => Ruta.fromJson(e as Map<String, dynamic>)).toList();
      camiones = resultados[1].map((e) => Camion.fromJson(e as Map<String, dynamic>)).toList();
      conductores = resultados[2].map((e) => Conductor.fromJson(e as Map<String, dynamic>)).toList();
      horarios = resultados[3].map((e) => Horario.fromJson(e as Map<String, dynamic>)).toList();
      return true;
    } catch (e) {
      return false;
    } finally {
      cargando = false;
      notifyListeners();
    }
  }

  Future<bool> cargarReportes() async {
    cargandoReportes = true;
    notifyListeners();
    try {
      final resultados = await ApiService.getSupervisorReportes();
      reportes = resultados.map((e) => Reporte.fromJson(e as Map<String, dynamic>)).toList();
      return true;
    } catch (e) {
      return false;
    } finally {
      cargandoReportes = false;
      notifyListeners();
    }
  }

  void setFiltroReporte(String filtro) {
    filtroReporte = filtro;
    notifyListeners();
  }

  List<Reporte> get reportesFiltrados => filtroReporte == 'todos'
      ? reportes
      : reportes.where((r) => r.estado == filtroReporte).toList();

  Future<Map<String, dynamic>> asignarRuta(Map<String, dynamic> datos) => ApiService.asignarRuta(datos);

  Future<Map<String, dynamic>> cambiarEstadoCamion(int id, String estado) =>
      ApiService.cambiarEstadoCamion(id, estado);

  Future<Map<String, dynamic>> cambiarEstadoConductor(int id, String estado) =>
      ApiService.cambiarEstadoConductor(id, estado);

  Future<Map<String, dynamic>> responderReporte(int id, Map<String, dynamic> datos) =>
      ApiService.responderReporte(id, datos);

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
