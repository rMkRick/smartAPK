import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'landing_screen.dart';
import 'dart:convert';

class OperadorDashboard extends StatefulWidget {
  const OperadorDashboard({super.key});

  @override
  State<OperadorDashboard> createState() => _OperadorDashboardState();
}

class _OperadorDashboardState extends State<OperadorDashboard> {
  Map<String, dynamic>? _usuario;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('usuario');
    if (userStr != null) {
      setState(() => _usuario = jsonDecode(userStr));
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LandingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF97316);
    const secondaryColor = Color(0xFF0F172A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Operador'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bienvenido, Operador ${_usuario?['nombres'] ?? ''}', 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            const Card(
              child: ListTile(
                leading: Icon(Icons.local_shipping, color: primaryColor),
                title: Text('Mi Ruta Asignada'),
                subtitle: Text('Ruta Centro - Sector 01'),
                trailing: Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 10),
            const Card(
              child: ListTile(
                leading: Icon(Icons.timer, color: primaryColor),
                title: Text('Horario de Hoy'),
                subtitle: Text('20:00 - 22:00'),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.play_arrow),
              label: const Text('INICIAR RUTA DE RECOLECCIÓN'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
