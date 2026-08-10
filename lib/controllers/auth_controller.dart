import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../services/api_service.dart';
import 'outcome.dart';

/// Controller MVC: encapsula la lógica de negocio de autenticación
/// (validación de registro, login y persistencia de sesión) para que
/// la View (LandingScreen) sólo se encargue de construir la UI.
class AuthController extends ChangeNotifier {
  bool isLoading = false;
  bool isRegistering = false;
  Usuario? usuario;

  void toggleRegistering() {
    isRegistering = !isRegistering;
    notifyListeners();
  }

  Future<Outcome> login(String correo, String contrasena) async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.login(correo, contrasena);
      if (response['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        await prefs.setString('usuario', jsonEncode(response['usuario']));
        usuario = Usuario.fromJson(response['usuario']);
        return const Outcome(true, '');
      }
      return Outcome(false, response['mensaje'] ?? 'Error al iniciar sesión');
    } catch (e) {
      return const Outcome(false, 'Error de conexión con el servidor');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Outcome> _procesarLoginSocial(Map<String, dynamic> response) async {
    if (response['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', response['token']);
      await prefs.setString('usuario', jsonEncode(response['usuario']));
      usuario = Usuario.fromJson(response['usuario']);
      return const Outcome(true, '');
    }
    return Outcome(false, response['mensaje'] ?? 'Error al iniciar sesión');
  }

  Future<Outcome> loginConGoogle() async {
    isLoading = true;
    notifyListeners();
    try {
      final cuenta = await GoogleSignIn().signIn();
      if (cuenta == null) {
        return const Outcome(false, 'Inicio de sesión con Google cancelado');
      }
      final partes = cuenta.displayName?.trim().split(RegExp(r'\s+')) ?? [];
      final nombres = partes.isNotEmpty ? partes.first : cuenta.email;
      final apellidos = partes.length > 1 ? partes.sublist(1).join(' ') : '';

      final response = await ApiService.loginSocial(
        nombres: nombres,
        apellidos: apellidos,
        correo: cuenta.email,
        fotoPerfil: cuenta.photoUrl,
        proveedorSocial: 'google',
        proveedorId: cuenta.id,
      );
      return await _procesarLoginSocial(response);
    } catch (e) {
      return const Outcome(false, 'Error al iniciar sesión con Google');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Outcome> loginConFacebook() async {
    isLoading = true;
    notifyListeners();
    try {
      final resultado = await FacebookAuth.instance.login(permissions: const ['email', 'public_profile']);
      if (resultado.status != LoginStatus.success) {
        return const Outcome(false, 'Inicio de sesión con Facebook cancelado');
      }
      final perfil = await FacebookAuth.instance.getUserData(
        fields: 'id,first_name,last_name,email,picture.type(large)',
      );
      final correo = perfil['email'] as String?;
      if (correo == null) {
        return const Outcome(false, 'Facebook no compartió un correo. Usa otro método de inicio de sesión.');
      }

      final response = await ApiService.loginSocial(
        nombres: (perfil['first_name'] as String?) ?? '',
        apellidos: (perfil['last_name'] as String?) ?? '',
        correo: correo,
        fotoPerfil: perfil['picture']?['data']?['url'] as String?,
        proveedorSocial: 'facebook',
        proveedorId: perfil['id'] as String,
      );
      return await _procesarLoginSocial(response);
    } catch (e) {
      return const Outcome(false, 'Error al iniciar sesión con Facebook');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Outcome> register({
    required String nombres,
    required String apellidos,
    required String dni,
    required String correo,
    required String contrasena,
  }) async {
    if (nombres.isEmpty || apellidos.isEmpty || dni.isEmpty || correo.isEmpty || contrasena.isEmpty) {
      return const Outcome(false, 'Por favor completa todos los campos');
    }
    if (nombres.length <= 3) {
      return const Outcome(false, 'Los nombres deben tener más de 3 letras');
    }
    if (apellidos.length <= 3) {
      return const Outcome(false, 'Los apellidos deben tener más de 3 letras');
    }
    if (dni.length != 8 || !RegExp(r'^\d{8}$').hasMatch(dni)) {
      return const Outcome(false, 'El DNI debe tener exactamente 8 dígitos');
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(correo)) {
      return const Outcome(false, 'Ingrese un correo electrónico válido');
    }
    if (!contrasena.contains(RegExp(r'[A-Z]'))) {
      return const Outcome(false, 'La contraseña debe tener al menos una letra mayúscula');
    }

    isLoading = true;
    notifyListeners();
    try {
      final userData = {
        'nombres': nombres,
        'apellidos': apellidos,
        'dni': dni,
        'correo': correo,
        'contrasena': contrasena,
        'rol_id': 1, // Ciudadano por defecto
        'zona_id': 1, // Centro Histórico por defecto
      };
      final response = await ApiService.register(userData);
      final mensaje = response['mensaje']?.toString();
      if (mensaje != null && mensaje.toLowerCase().contains('éxito')) {
        isRegistering = false;
        return const Outcome(true, 'Registro exitoso. Ahora puedes iniciar sesión.');
      }
      return Outcome(false, mensaje ?? 'Error al registrarse');
    } catch (e) {
      return const Outcome(false, 'Error al conectar con el servidor');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
