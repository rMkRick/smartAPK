import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reporte.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import 'outcome.dart';

/// Controller MVC de CitizenDashboard: mantiene la sesión del ciudadano,
/// el tracking de ubicación, la lista de reportes y la creación/borrado de
/// reportes. La View sólo dibuja UI y llama a estos métodos.
class CitizenController extends ChangeNotifier {
  Usuario? usuario;
  List<Reporte> misReportes = [];
  bool isLoading = false;
  bool isLocationLoading = true;

  File? imageFile;
  Position? currentPosition;
  LatLng? pickedPosition;

  LatLng? get ubicacionEfectiva =>
      pickedPosition ?? (currentPosition != null ? LatLng(currentPosition!.latitude, currentPosition!.longitude) : null);

  /// Devuelve false si no hay sesión guardada (la View debe llevar al landing).
  Future<bool> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('usuario');
    if (userStr == null) return false;
    usuario = Usuario.fromJson(jsonDecode(userStr));
    notifyListeners();
    await fetchReports();
    return true;
  }

  Future<void> fetchReports() async {
    if (usuario?.id == null) return;
    final reports = await ApiService.getUserReports(usuario!.id!);
    misReportes = reports.map((e) => Reporte.fromJson(e as Map<String, dynamic>)).toList();
    notifyListeners();
  }

  void startLocationTracking() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      isLocationLoading = false;
      notifyListeners();
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        isLocationLoading = false;
        notifyListeners();
        return;
      }
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      currentPosition = position;
      isLocationLoading = false;
      notifyListeners();
    });
  }

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      notifyListeners();
    }
  }

  void selectPickedPosition(LatLng point) {
    pickedPosition = point;
    notifyListeners();
  }

  void clearPickedPosition() {
    pickedPosition = null;
    notifyListeners();
  }

  Future<Outcome> submitReport(String descripcion) async {
    if (imageFile == null) {
      return const Outcome(false, 'Por favor, tome o cargue una foto');
    }
    final ubicacion = ubicacionEfectiva;
    if (ubicacion == null) {
      return const Outcome(false, 'Esperando ubicación GPS...');
    }

    isLoading = true;
    notifyListeners();
    try {
      String fotoUrl = 'https://via.placeholder.com/300';
      final uploadedUrl = await ApiService.uploadImage(imageFile!);
      if (uploadedUrl != null) fotoUrl = uploadedUrl;

      final reportData = {
        'usuario_id': usuario!.id,
        'descripcion': descripcion.trim(),
        'latitud': ubicacion.latitude,
        'longitud': ubicacion.longitude,
        'foto_url': fotoUrl,
        'tipo_residuo_id': 1,
      };

      final response = await ApiService.createReport(reportData);
      imageFile = null;
      await fetchReports();
      return Outcome(true, 'Reporte enviado. Ticket: ${response['numero_ticket']}');
    } catch (e) {
      return const Outcome(false, 'Error al enviar reporte');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String> deleteReport(int id) async {
    final response = await ApiService.deleteReport(id);
    await fetchReports();
    return response['mensaje'] ?? 'Reporte eliminado';
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
