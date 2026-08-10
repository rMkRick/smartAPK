import 'package:flutter/material.dart';
import '../controllers/operador_controller.dart';
import 'landing_screen.dart';
import 'operador_ruta_screen.dart';

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

  Future<void> _iniciarRuta() async {
    final ruta = _controller.rutaAsignada;
    if (ruta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tienes una ruta asignada por hoy.')));
      return;
    }

    final gpsListo = await _controller.iniciarRuta();
    if (!mounted) return;
    if (!gpsListo) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorGps ?? 'No se pudo activar el GPS')));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OperadorRutaScreen(controller: _controller, ruta: ruta)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF97316);
    const secondaryColor = Color(0xFF0F172A);
    final ruta = _controller.rutaAsignada;
    final activando = _controller.activandoGps;

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
            Card(
              child: ListTile(
                leading: const Icon(Icons.local_shipping, color: primaryColor),
                title: const Text('Mi Ruta Asignada'),
                subtitle: Text(_controller.cargandoRuta
                    ? 'Buscando ruta asignada...'
                    : (ruta != null ? '${ruta.nombre ?? ''} - ${ruta.zonaNombre ?? ''}' : 'Sin ruta asignada por hoy')),
                trailing: const Icon(Icons.map),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: ListTile(
                leading: const Icon(Icons.timer, color: primaryColor),
                title: const Text('Horario de Hoy'),
                subtitle: Text(ruta != null && ruta.horaInicio != null
                    ? '${ruta.horaInicio} - ${ruta.horaFin ?? ''}'
                    : 'Sin horario asignado'),
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: activando ? null : _iniciarRuta,
              icon: activando
                  ? const SizedBox(
                      width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.play_arrow),
              label: Text(activando ? 'ACTIVANDO GPS...' : 'INICIAR RUTA DE RECOLECCIÓN'),
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
