import 'package:flutter/material.dart';
import 'citizen_dashboard.dart';
import 'operador_dashboard.dart';
import 'admin_dashboard.dart';
import 'guest_report_screen.dart';
import '../services/api_service.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();
  
  bool _isLoading = false;
  bool _isRegistering = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (response['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', response['token']);
        await prefs.setString('usuario', jsonEncode(response['usuario']));

        if (mounted) {
          final rolId = response['usuario']['rol_id'];
          Widget nextScreen;
          
          if (rolId == 1) {
            nextScreen = const CitizenDashboard();
          } else if (rolId == 2) {
            nextScreen = const OperadorDashboard();
          } else if (rolId == 3 || rolId == 4) {
            nextScreen = const AdminDashboard();
          } else {
            nextScreen = const CitizenDashboard();
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => nextScreen),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['mensaje'] ?? 'Error al iniciar sesión')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión con el servidor')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    final nombres = _nombreController.text.trim();
    final apellidos = _apellidoController.text.trim();
    final dni = _dniController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (nombres.isEmpty || apellidos.isEmpty || dni.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    // Validar Nombres (> 3 letras)
    if (nombres.length <= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los nombres deben tener más de 3 letras')),
      );
      return;
    }

    // Validar Apellidos (> 3 letras)
    if (apellidos.length <= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Los apellidos deben tener más de 3 letras')),
      );
      return;
    }

    // Validar DNI (8 dígitos)
    if (dni.length != 8 || !RegExp(r'^\d{8}$').hasMatch(dni)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El DNI debe tener exactamente 8 dígitos')),
      );
      return;
    }

    // Validar Correo
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un correo electrónico válido')),
      );
      return;
    }

    // Validar Contraseña (al menos una mayúscula)
    if (!password.contains(RegExp(r'[A-Z]'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La contraseña debe tener al menos una letra mayúscula')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userData = {
        'nombres': nombres,
        'apellidos': apellidos,
        'dni': dni,
        'correo': email,
        'contrasena': password,
        'rol_id': 1, // Ciudadano por defecto
        'zona_id': 1, // Centro Histórico por defecto
      };

      final response = await ApiService.register(userData);

      if (mounted) {
        if (response['mensaje'] != null && response['mensaje'].toString().toLowerCase().contains('éxito')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registro exitoso. Ahora puedes iniciar sesión.')),
          );
          setState(() => _isRegistering = false);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['mensaje'] ?? 'Error al registrarse')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al conectar con el servidor')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF97316); // Orange
    const secondaryColor = Color(0xFF0F172A); // Navy Blue
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800;

    return Scaffold(
      body: Stack(
        children: [
          // Background Image with Overlay
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: secondaryColor,
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1526392060635-9d6019884377?q=80&w=2000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              color: secondaryColor.withOpacity(0.7),
            ),
          ),

          // Scrollable Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Navbar
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isLargeScreen ? 50 : 20,
                          vertical: 10
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.delete_outline, color: primaryColor, size: 24),
                                const SizedBox(width: 8),
                                const Text(
                                  'MUNI CUSCO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isRegistering = !_isRegistering;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: Text(
                                _isRegistering ? 'VOLVER AL LOGIN' : 'REGISTRO', 
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Responsive Layout for Hero and Login
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? 50 : 20),
                        child: isLargeScreen 
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(child: _buildHeroSection(primaryColor, isLargeScreen)),
                                const SizedBox(width: 50),
                                SizedBox(width: 450, child: _buildAuthForm(primaryColor, secondaryColor)),
                              ],
                            )
                          : Column(
                              children: [
                                _buildHeroSection(primaryColor, isLargeScreen),
                                const SizedBox(height: 15),
                                _buildAuthForm(primaryColor, secondaryColor),
                              ],
                            ),
                      ),

                      const SizedBox(height: 40),

                      // Stats Section
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _statItem('-30%', 'Tiempo de Ruta', primaryColor, secondaryColor),
                                _statItem('-25%', 'Emisiones CO2', primaryColor, secondaryColor),
                                _statItem('98%', 'Cumplimiento', primaryColor, secondaryColor),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Footer
                      Container(
                        width: double.infinity,
                        color: secondaryColor,
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Text(
                              'MUNICIPIO CUSCO',
                              style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Servicio de Gestión de Residuos del Distrito de Cusco. Trabajando por una ciudad limpia y sostenible.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, height: 1.6),
                            ),
                            const SizedBox(height: 40),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 20),
                            const Text(
                              '© 2026 Municipalidad del Cusco.',
                              style: TextStyle(color: Colors.white38, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(Color primaryColor, bool isLargeScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Software de Recolección de Residuos',
          style: TextStyle(
            color: Colors.white,
            fontSize: isLargeScreen ? 32 : 24,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        Text(
          'Impulsando un Cusco Limpio',
          style: TextStyle(
            color: primaryColor,
            fontSize: isLargeScreen ? 28 : 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Optimice sus rutas de recolección, reduzca emisiones en la ciudad imperial y mejore la calidad de vida de todos los cusqueños.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: isLargeScreen ? 15 : 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 15),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GuestReportScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          child: Text(
            'Registrar Reporte Residuos',
            style: TextStyle(fontSize: isLargeScreen ? 15 : 13, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthForm(Color primaryColor, Color secondaryColor) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: AutofillGroup(
          child: Column(
            children: [
              Icon(_isRegistering ? Icons.person_add_outlined : Icons.delete_outline, color: primaryColor, size: 40),
              const SizedBox(height: 10),
              Text(
                _isRegistering ? 'Registro Ciudadano' : 'Acceso al Sistema',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _isRegistering ? 'Crea tu cuenta para reportar' : 'Inicie sesión para gestionar la recolección',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 25),

              if (_isRegistering) ...[
                _buildInputField('Nombres', _nombreController, 'Juan'),
                const SizedBox(height: 10),
                _buildInputField('Apellidos', _apellidoController, 'Perez'),
                const SizedBox(height: 10),
                _buildInputField('DNI', _dniController, '12345678', keyboardType: TextInputType.number),
                const SizedBox(height: 10),
              ],

              _buildInputField('Correo Electrónico', _emailController, 'ejemplo@cusco.gob.pe', 
                keyboardType: TextInputType.emailAddress, autofill: AutofillHints.email),
              const SizedBox(height: 10),
              
              _buildInputField('Contraseña', _passwordController, '••••••••', 
                obscureText: true, autofill: AutofillHints.password),
              
              const SizedBox(height: 25),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : (_isRegistering ? _register : _login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_isRegistering ? 'CREAR CUENTA' : 'ENTRAR', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              
              const SizedBox(height: 20),
              
              GestureDetector(
                onTap: () => setState(() => _isRegistering = !_isRegistering),
                child: Text(
                  _isRegistering ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, String hint, {bool obscureText = false, TextInputType? keyboardType, String? autofill}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          autofillHints: autofill != null ? [autofill] : null,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _statItem(String value, String label, Color primary, Color secondary) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: primary, fontSize: 28, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: secondary, fontWeight: FontWeight.w600, fontSize: 12)),
      ],
    );
  }
}
