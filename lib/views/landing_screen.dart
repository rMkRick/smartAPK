import 'package:flutter/material.dart';
import '../controllers/auth_controller.dart';
import 'citizen_dashboard.dart';
import 'operador_dashboard.dart';
import 'admin_dashboard.dart';
import 'supervisor_dashboard.dart';
import 'guest_report_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _authController = AuthController();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _dniController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authController.addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    _authController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nombreController.dispose();
    _apellidoController.dispose();
    _dniController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final outcome = await _authController.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;

    if (outcome.success) {
      final rolId = _authController.usuario?.rol;
      Widget nextScreen;

      if (rolId == 1) {
        nextScreen = const CitizenDashboard();
      } else if (rolId == 2) {
        nextScreen = const OperadorDashboard();
      } else if (rolId == 3) {
        nextScreen = const AdminDashboard();
      } else if (rolId == 4) {
        nextScreen = const SupervisorDashboard();
      } else {
        nextScreen = const CitizenDashboard();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => nextScreen),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(outcome.message)));
    }
  }

  Future<void> _register() async {
    final outcome = await _authController.register(
      nombres: _nombreController.text.trim(),
      apellidos: _apellidoController.text.trim(),
      dni: _dniController.text.trim(),
      correo: _emailController.text.trim(),
      contrasena: _passwordController.text.trim(),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(outcome.message)));
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
            decoration: BoxDecoration(
              color: secondaryColor,
              image: DecorationImage(
                image: const NetworkImage('https://images.unsplash.com/photo-1526392060635-9d6019884377?q=80&w=2000&auto=format&fit=crop'),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {},
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
                              onPressed: _authController.toggleRegistering,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: Text(
                                _authController.isRegistering ? 'VOLVER AL LOGIN' : 'REGISTRO',
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
                              'SmartAPk',
                              style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Servicio de Gestión de Residuos. Trabajando por una ciudad limpia y sostenible.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, height: 1.6),
                            ),
                            const SizedBox(height: 40),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 20),
                            const Text(
                              '© 2026 SmartAPk.',
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
          'SmartAPk',
          style: TextStyle(
            color: Colors.white,
            fontSize: isLargeScreen ? 32 : 24,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        Text(
          'Impulsando una ciudad Limpia',
          style: TextStyle(
            color: primaryColor,
            fontSize: isLargeScreen ? 28 : 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Optimice sus rutas de recolección, reduzca emisiones y mejore la calidad de vida de todos.',
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
    final isRegistering = _authController.isRegistering;
    final isLoading = _authController.isLoading;

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: AutofillGroup(
          child: Column(
            children: [
              Icon(isRegistering ? Icons.person_add_outlined : Icons.delete_outline, color: primaryColor, size: 40),
              const SizedBox(height: 10),
              Text(
                isRegistering ? 'Registro Ciudadano' : 'Acceso al Sistema',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isRegistering ? 'Crea tu cuenta para reportar' : 'Inicie sesión para gestionar la recolección',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 25),

              if (isRegistering) ...[
                _buildInputField('Nombres', _nombreController, 'Juan'),
                const SizedBox(height: 10),
                _buildInputField('Apellidos', _apellidoController, 'Perez'),
                const SizedBox(height: 10),
                _buildInputField('DNI', _dniController, '12345678', keyboardType: TextInputType.number),
                const SizedBox(height: 10),
              ],

              _buildInputField('Correo Electrónico', _emailController, 'ejemplo@smartapk.com',
                keyboardType: TextInputType.emailAddress, autofill: AutofillHints.email),
              const SizedBox(height: 10),

              _buildInputField('Contraseña', _passwordController, '••••••••',
                obscureText: true, autofill: AutofillHints.password),

              const SizedBox(height: 25),

              // Submit Button
              ElevatedButton(
                onPressed: isLoading ? null : (isRegistering ? _register : _login),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isRegistering ? 'CREAR CUENTA' : 'ENTRAR', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: _authController.toggleRegistering,
                child: Text(
                  isRegistering ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate',
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
