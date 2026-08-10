import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Cliente HTTP inyectable: en producción es un http.Client() normal; en
  // los tests se reemplaza por un MockClient (package:http/testing.dart)
  // para simular respuestas del backend sin red real.
  static http.Client client = http.Client();

  // Backend centralizado (Node/Express + MySQL) desplegado en Vercel: todos
  // los dispositivos comparten los mismos datos, a diferencia de la base
  // SQLite local que usaba cada instalación por separado.
  static const String baseUrl = 'https://smartwaste-nine.vercel.app/api';

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
      return jsonDecode(response.body);
    } catch (e) {
      return {'mensaje': 'No se pudo conectar con el servidor. ¿Está el backend encendido?'};
    }
  }

  // Login con Google/Facebook: el SDK nativo ya autenticó al usuario en el
  // dispositivo, aquí solo se registra/recupera su cuenta en el backend con
  // el perfil obtenido (mismo contrato que usa smartwaste/frontend).
  static Future<Map<String, dynamic>> loginSocial({
    required String nombres,
    required String apellidos,
    required String correo,
    String? fotoPerfil,
    required String proveedorSocial,
    required String proveedorId,
  }) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/auth/login-social'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombres': nombres,
          'apellidos': apellidos,
          'correo': correo,
          'foto_perfil': fotoPerfil,
          'proveedor_social': proveedorSocial,
          'proveedor_id': proveedorId,
        }),
      ).timeout(const Duration(seconds: 10));
      return jsonDecode(response.body);
    } catch (e) {
      return {'mensaje': 'No se pudo conectar con el servidor.'};
    }
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await client.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(userData),
    ).timeout(const Duration(seconds: 10));
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    // Este backend devuelve validaciones fallidas como {'errores': [...]}
    // en vez de {'mensaje': ...}; se normaliza para que el resto de la app
    // (que solo lee 'mensaje') siga funcionando.
    if (decoded['mensaje'] == null && decoded['errores'] is List) {
      final errores = (decoded['errores'] as List).join('. ');
      return {...decoded, 'mensaje': errores};
    }
    return decoded;
  }

  static Future<Map<String, dynamic>> createReport(Map<String, dynamic> reportData) async {
    try {
      final response = await client.post(
        Uri.parse('$baseUrl/reportes'),
        headers: await _authHeaders(),
        body: jsonEncode(reportData),
      ).timeout(const Duration(seconds: 10));
      if (response.body.startsWith('<!DOCTYPE html>')) {
        return {'mensaje': 'Error 404: el backend no tiene la ruta /reportes.'};
      }
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> && decoded['numero_ticket'] == null && decoded['mensaje'] == null) {
        return {...decoded, 'mensaje': 'No se pudo registrar el reporte.'};
      }
      return decoded;
    } catch (e) {
      return {'mensaje': 'Error al enviar reporte (Tiempo agotado)'};
    }
  }

  static Future<String?> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/reportes/upload'));
      final headers = await _authHeaders();
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));

      var response = await client.send(request);
      if (response.statusCode == 200) {
        var responseData = await response.stream.bytesToString();
        var decoded = jsonDecode(responseData);
        return decoded['foto_url'];
      }
    } catch (e) {
      // Sin conexión o backend caído: se ignora, el llamador usa un
      // placeholder si uploadImage devuelve null.
    }
    return null;
  }

  static Future<List<dynamic>> getUserReports(int userId) async {
    try {
      final response = await client.get(
        Uri.parse('$baseUrl/reportes/usuario/$userId'),
        headers: await _authHeaders(),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      // Sin conexión: se devuelve lista vacía más abajo.
    }
    return [];
  }

  static Future<Map<String, dynamic>> deleteReport(int reportId) async {
    try {
      final response = await client.delete(
        Uri.parse('$baseUrl/reportes/${reportId.toString()}'),
        headers: await _authHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.body.startsWith('<!DOCTYPE html>')) {
        return {'mensaje': 'Error 404: el backend no tiene la ruta para borrar reportes.'};
      }

      return jsonDecode(response.body);
    } catch (e) {
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
