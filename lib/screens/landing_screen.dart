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
  bool _isLoading = false;

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
                                  'SMARTWASTE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text('ACCESO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                                SizedBox(width: 450, child: _buildLoginForm(primaryColor, secondaryColor)),
                              ],
                            )
                          : Column(
                              children: [
                                _buildHeroSection(primaryColor, isLargeScreen),
                                const SizedBox(height: 15),
                                _buildLoginForm(primaryColor, secondaryColor),
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
                              'SMARTWASTE',
                              style: TextStyle(color: primaryColor, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Transformando la recolección de residuos en Cusco a través de la optimización de rutas y la participación ciudadana.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, height: 1.6),
                            ),
                            const SizedBox(height: 40),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 20),
                            const Text(
                              '© 2026 SmartWaste Cusco.',
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

  Widget _buildLoginForm(Color primaryColor, Color secondaryColor) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: AutofillGroup(
          child: Column(
            children: [
              Icon(Icons.delete_outline, color: primaryColor, size: 40),
              const SizedBox(height: 10),
              Text(
                'Acceso al Sistema',
                style: TextStyle(
                  color: secondaryColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Inicie sesión para gestionar la recolección',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 30),

              // Email Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Correo Electrónico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _emailController,
                    autofillHints: const [AutofillHints.email],
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'admin@smartwaste.com',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Password Input
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contraseña', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: _passwordController,
                    autofillHints: const [AutofillHints.password],
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: _isLoading 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('ENTRAR', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              const Text(
                '¿Olvidó su contraseña?',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
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

