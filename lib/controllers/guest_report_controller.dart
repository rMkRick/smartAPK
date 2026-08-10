import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import 'outcome.dart';

/// Controller MVC de GuestReportScreen: reporte sin cuenta (sin usuario_id).
class GuestReportController extends ChangeNotifier {
  File? imageFile;
  Position? currentPosition;
  bool isLoading = false;

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      imageFile = File(pickedFile.path);
      notifyListeners();
    }
  }

  Future<void> _getCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    currentPosition = await Geolocator.getCurrentPosition();
  }

  Future<Outcome> submitReport(String descripcion) async {
    isLoading = true;
    notifyListeners();
    await _getCurrentLocation();

    if (currentPosition == null) {
      isLoading = false;
      notifyListeners();
      return const Outcome(false, 'No se pudo obtener la ubicación');
    }

    try {
      final reportData = {
        'usuario_id': null,
        'descripcion': descripcion.trim(),
        'latitud': currentPosition!.latitude,
        'longitud': currentPosition!.longitude,
        'foto_url': 'https://via.placeholder.com/300',
        'tipo_residuo_id': 1,
      };
      final response = await ApiService.createReport(reportData);
      final ticket = response['numero_ticket'];
      if (ticket == null) {
        return Outcome(false, response['mensaje']?.toString() ?? 'No se pudo enviar el reporte');
      }
      return Outcome(true, ticket.toString());
    } catch (e) {
      return const Outcome(false, 'Error al enviar reporte');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
