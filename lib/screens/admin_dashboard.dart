import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'landing_screen.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<dynamic> _todosLosReportes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchGlobalReports();
  }

  Future<void> _fetchGlobalReports() async {
    final reports = await ApiService.getReports();
    setState(() {
      _todosLosReportes = reports;
      _isLoading = false;
    });
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
        title: const Text('Administración SmartWaste'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        actions: [IconButton(onPressed: _logout, icon: const Icon(Icons.logout))],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Gestión Global de Denuncias', 
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Row(
                  children: [
                    _statCard('Total', '${_todosLosReportes.length}', Colors.blue),
                    _statCard('Hoy', '2', Colors.orange),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _todosLosReportes.length,
                    itemBuilder: (context, index) {
                      final report = _todosLosReportes[index];
                      // Formatear fecha simple
                      final fecha = report['fecha_creacion'] != null 
                          ? report['fecha_creacion'].toString().split('T')[0] 
                          : 'Reciente';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Ticket: ${report['numero_ticket']}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Text(
                                      'REGISTRADO',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              const SizedBox(height: 5),
                              _detailRow(Icons.person, 'Ciudadano:', '${report['nombres']} ${report['apellidos']}'),
                              _detailRow(Icons.category, 'Tipo:', '${report['tipo_residuo'] ?? 'No especificado'}'),
                              _detailRow(Icons.calendar_today, 'Fecha:', fecha),
                              const SizedBox(height: 10),
                              const Text(
                                'Descripción:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                report['descripcion'] ?? 'Sin descripción',
                                style: const TextStyle(color: Colors.black87),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Ubicación del Reporte'),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('Latitud: ${report['latitud']}'),
                                              Text('Longitud: ${report['longitud']}'),
                                              const SizedBox(height: 15),
                                              const Text('Nota: En una versión futura, aquí se mostrará un mapa interactivo.', 
                                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey)),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CERRAR')),
                                          ],
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.location_on, size: 16),
                                    label: const Text('VER UBICACIÓN'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(width: 5),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
              Text(label, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }
}
