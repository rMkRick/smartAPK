import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Configuración dinámica de la URL según la plataforma
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (Platform.isAndroid || Platform.isWindows || Platform.isIOS) {
      return 'http://192.168.18.3:5000/api'; // IP local de tu PC
    } else {
      return 'http://192.168.18.3:5000/api';
    }
  }

  static Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'correo': correo,
          'contrasena': contrasena,
        }),
      ).timeout(const Duration(seconds: 10));
      
      print('API Response Status: ${response.statusCode}');
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en login: $e');
      return {'mensaje': 'No se pudo conectar con el servidor. ¿Está el backend encendido?'};
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    ).timeout(const Duration(seconds: 10));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reportData),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en createReport: $e');
      return {'mensaje': 'Error al enviar reporte (Tiempo agotado)'};
    }
  }

  static Future<String?> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/reports/upload'));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
      var response = await request.send();
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var decoded = jsonDecode(responseData);
        return decoded['foto_url'];
      }
    } catch (e) {
      print('Error uploading image: $e');
    }
    return null;
  }

  static Future<List<dynamic>> getReports() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reports'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error en getReports: $e');
    }
    return [];
  }

  static Future<List<dynamic>> getUserReports(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/reports/usuario/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error en getUserReports: $e');
    }
    return [];
  }

  static Future<Map<String, dynamic>> deleteReport(int reportId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/reports/${reportId.toString()}'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      print('Delete Response Status: ${response.statusCode}');
      
      if (response.body.startsWith('<!DOCTYPE html>')) {
        return {'mensaje': 'Error 404: El servidor no encontró la ruta de borrado. REINICIA EL BACKEND.'};
      }
      
      return jsonDecode(response.body);
    } catch (e) {
      print('Error en deleteReport: $e');
      return {'mensaje': 'Error al conectar para borrar. Revisa que el servidor esté prendido.'};
    }
  }

  // Admin Services
  static Future<Map<String, dynamic>> updateReportStatus(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/reports/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> getStaff() async {
    final response = await http.get(Uri.parse('$baseUrl/users/staff'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<Map<String, dynamic>> toggleStaffStatus(int id, String estado) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/staff/$id/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'estado': estado}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getStats() async {
    final response = await http.get(Uri.parse('$baseUrl/users/stats'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return {};
  }

  // Truck Services
  static Future<List<dynamic>> getTrucks() async {
    final response = await http.get(Uri.parse('$baseUrl/trucks'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getAssignments() async {
    final response = await http.get(Uri.parse('$baseUrl/trucks/assignments'));
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<Map<String, dynamic>> assignTruck(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/trucks/assign'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );
    return jsonDecode(response.body);
  }
}
