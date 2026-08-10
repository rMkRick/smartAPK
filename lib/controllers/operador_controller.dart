import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ruta.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';

/// Controller MVC de OperadorDashboard: sesión del operador/recolector,
/// su ruta asignada del día y el seguimiento GPS mientras la recorre.
class OperadorController extends ChangeNotifier {
  Usuario? usuario;
  Ruta? rutaAsignada;
  bool cargandoRuta = false;

  Position? currentPosition;
  bool activandoGps = false;
  String? errorGps;
  StreamSubscription<Position>? _posicionSub;

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('usuario');
    if (userStr != null) {
      usuario = Usuario.fromJson(jsonDecode(userStr));
      notifyListeners();
      await cargarRutaAsignada();
    }
  }

  /// Busca, entre las rutas de gestión, la asignada al operador logueado.
  /// El backend solo expone el nombre del operador en cada ruta (no su id),
  /// así que se empareja por nombre completo; si hay varias, se prefiere la
  /// de fecha_asignacion == hoy.
  Future<void> cargarRutaAsignada() async {
    if (usuario == null) return;
    cargandoRuta = true;
    notifyListeners();
    try {
      final nombreCompleto = '${usuario!.nombres ?? ''} ${usuario!.apellidos ?? ''}'.trim().toLowerCase();
      if (nombreCompleto.isEmpty) {
        rutaAsignada = null;
        return;
      }
      final data = await ApiService.getRutasGestion();
      final rutas = data
          .whereType<Map>()
          .map((e) => Ruta.fromJson(e.cast<String, dynamic>()))
          .where((r) => r.camionId != null)
          .where((r) => '${r.operadorNombres ?? ''} ${r.operadorApellidos ?? ''}'.trim().toLowerCase() == nombreCompleto)
          .toList();

      final ahora = DateTime.now();
      final hoy = '${ahora.year.toString().padLeft(4, '0')}-${ahora.month.toString().padLeft(2, '0')}-${ahora.day.toString().padLeft(2, '0')}';
      rutaAsignada = rutas.isEmpty
          ? null
          : rutas.firstWhere((r) => r.fechaAsignacion == hoy, orElse: () => rutas.first);
    } catch (_) {
      rutaAsignada = null;
    } finally {
      cargandoRuta = false;
      notifyListeners();
    }
  }

  /// Enciende el GPS (pidiendo permiso si hace falta), obtiene la posición
  /// actual y arranca el seguimiento continuo para el mapa de la ruta.
  Future<bool> iniciarRuta() async {
    errorGps = null;
    activandoGps = true;
    notifyListeners();
    try {
      final servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) {
        errorGps = 'Activa el GPS del dispositivo para iniciar la ruta';
        return false;
      }

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        errorGps = 'Se necesita permiso de ubicación para iniciar la ruta';
        return false;
      }

      currentPosition = await Geolocator.getCurrentPosition();
      _posicionSub?.cancel();
      _posicionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
      ).listen((position) {
        currentPosition = position;
        notifyListeners();
      });
      return true;
    } catch (_) {
      errorGps = 'No se pudo obtener tu ubicación GPS';
      return false;
    } finally {
      activandoGps = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  void dispose() {
    _posicionSub?.cancel();
    super.dispose();
  }
}
