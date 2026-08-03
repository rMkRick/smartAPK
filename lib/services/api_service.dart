import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Cliente HTTP inyectable: en producción es un http.Client() normal; en
  // los tests se reemplaza por un MockClient (package:http/testing.dart)
  // para simular respuestas del backend sin red real.
  static http.Client client = http.Client();

  // Configuración dinámica de la URL según la plataforma
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    } else if (Platform.isAndroid || Platform.isWindows || Platform.isIOS) {
      return 'http://10.202.66.103:5000/api'; // IP local de tu PC
    } else {
      return 'http://10.202.66.103:5000/api';
    }
  }

  static Future<Map<String, dynamic>> login(String correo, String contrasena) async {
    try {
      final response = await client.post(
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
    final response = await client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    ).timeout(const Duration(seconds: 10));
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    try {
      final response = await client.post(
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
      
      var response = await client.send(request);
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

  static Future<List<dynamic>> getUserReports(int userId) async {
    try {
      final response = await client.get(Uri.parse('$baseUrl/reports/usuario/$userId'));
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
      final response = await client.delete(
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

  // Supervisor: Gestión de Rutas (requiere JWT del supervisor logueado)
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<List<dynamic>> getRutasGestion() async {
    final response = await client.get(
      Uri.parse('$baseUrl/supervisor/rutas-gestion'),
      headers: await _authHeaders(),
    );
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getCamiones() async {
    final response = await client.get(Uri.parse('$baseUrl/camiones'), headers: await _authHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getConductores() async {
    final response = await client.get(Uri.parse('$baseUrl/conductores'), headers: await _authHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<List<dynamic>> getHorarios() async {
    final response = await client.get(Uri.parse('$baseUrl/horarios'), headers: await _authHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<Map<String, dynamic>> asignarRuta(Map<String, dynamic> datos) async {
    final response = await client.post(
      Uri.parse('$baseUrl/rutas/asignar'),
      headers: await _authHeaders(),
      body: jsonEncode(datos),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> cambiarEstadoCamion(int id, String estado) async {
    final response = await client.put(
      Uri.parse('$baseUrl/camiones/$id/estado'),
      headers: await _authHeaders(),
      body: jsonEncode({'estado': estado}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> cambiarEstadoConductor(int id, String estado) async {
    final response = await client.put(
      Uri.parse('$baseUrl/conductores/$id/estado'),
      headers: await _authHeaders(),
      body: jsonEncode({'estado': estado}),
    );
    return jsonDecode(response.body);
  }

  // Admin: CRUD de conductores y camiones (requiere JWT del admin logueado)
  static Future<Map<String, dynamic>> crearConductor(Map<String, dynamic> datos) async {
    final response = await client.post(
      Uri.parse('$baseUrl/conductores'),
      headers: await _authHeaders(),
      body: jsonEncode(datos),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> actualizarConductor(int id, Map<String, dynamic> datos) async {
    final response = await client.put(
      Uri.parse('$baseUrl/conductores/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(datos),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> actualizarCamion(int id, Map<String, dynamic> datos) async {
    final response = await client.put(
      Uri.parse('$baseUrl/camiones/$id'),
      headers: await _authHeaders(),
      body: jsonEncode(datos),
    );
    return jsonDecode(response.body);
  }

  // Supervisor: Reportes Ciudadanos (CU17/CU22)
  static Future<List<dynamic>> getSupervisorReportes() async {
    final response = await client.get(Uri.parse('$baseUrl/supervisor/reportes'), headers: await _authHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    return [];
  }

  static Future<Map<String, dynamic>> responderReporte(int id, Map<String, dynamic> datos) async {
    final response = await client.put(
      Uri.parse('$baseUrl/supervisor/incidencias/$id/responder'),
      headers: await _authHeaders(),
      body: jsonEncode(datos),
    );
    return jsonDecode(response.body);
  }
}
