import 'package:flutter/material.dart';
import '../controllers/operador_controller.dart';
import 'landing_screen.dart';

class OperadorDashboard extends StatefulWidget {
  const OperadorDashboard({super.key});

  @override
  State<OperadorDashboard> createState() => _OperadorDashboardState();
}

class _OperadorDashboardState extends State<OperadorDashboard> {
  final _controller = OperadorController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
    _controller.loadUser();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _logout() async {
    await _controller.logout();
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
        title: const Text('SmartAPk - Recolector'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bienvenido, Operador ${_controller.usuario?.nombres ?? ''}',
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
