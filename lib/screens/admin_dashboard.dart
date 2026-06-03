import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'landing_screen.dart';
import '../services/api_service.dart';
import 'dart:convert';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  bool _isLoading = true;
  
  // Data lists
  List<dynamic> _reports = [];
  List<dynamic> _staff = [];
  List<dynamic> _trucks = [];
  List<dynamic> _assignments = [];
  Map<String, dynamic> _stats = {};

  final _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final reports = await ApiService.getReports();
      final staff = await ApiService.getStaff();
      final trucks = await ApiService.getTrucks();
      final assignments = await ApiService.getAssignments();
      final stats = await ApiService.getStats();

      setState(() {
        _reports = reports;
        _staff = staff;
        _trucks = trucks;
        _assignments = assignments;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LandingScreen()));
    }
  }

  Future<void> _openMap(dynamic lat, dynamic lon) async {
    final double? dLat = double.tryParse(lat.toString());
    final double? dLon = double.tryParse(lon.toString());
    
    if (dLat == null || dLon == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coordenadas inválidas')));
      return;
    }

    final url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$dLat,$dLon');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo abrir el mapa')));
    }
  }

  Future<void> _handleCompleteReport(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Reporte'),
        content: const Text('¿Desea marcar este reporte como ATENDIDO?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('CONFIRMAR')),
        ],
      ),
    );

    if (confirm == true) {
      try {
        debugPrint('Intentando completar reporte ID: $id');
        final response = await ApiService.updateReportStatus(id, {'estado': 'atendido'});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['mensaje'] ?? 'Reporte actualizado con éxito')),
          );
          _loadAllData();
        }
      } catch (e) {
        if (mounted) {
          final String errorMsg = e.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error 404 o Red: $errorMsg. Verifique que el ID $id sea válido en el servidor.'), 
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  void _showReplyDialog(Map<String, dynamic> report) {
    _replyController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Responder Ticket: ${report['numero_ticket']}'),
        content: TextField(
          controller: _replyController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Escriba un mensaje para el ciudadano...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () async {
              if (_replyController.text.isNotEmpty) {
                await ApiService.updateReportStatus(report['id'], {
                  'estado': 'en_proceso',
                  'comentario_admin': _replyController.text
                });
                if (mounted) {
                  Navigator.pop(context);
                  _loadAllData();
                }
              }
            },
            child: const Text('ENVIAR'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStaffStatus(int id, String currentStatus) async {
    final newStatus = currentStatus == 'activo' ? 'inactivo' : 'activo';
    await ApiService.toggleStaffStatus(id, newStatus);
    _loadAllData();
  }

  void _showAssignTruckDialog(Map<String, dynamic> truck) {
    int? selectedStaffId;
    int selectedRouteId = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Asignar Unidad: ${truck['placa']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Seleccionar Conductor'),
                items: _staff.where((s) => s['rol'] == 'operadorRecolector' && s['estado'] == 'activo').map((s) {
                  return DropdownMenuItem<int>(
                    value: s['id'],
                    child: Text('${s['nombres']} ${s['apellidos']}'),
                  );
                }).toList(),
                onChanged: (val) => setModalState(() => selectedStaffId = val),
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: 'Ruta'),
                value: selectedRouteId,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Ruta Centro Monumental')),
                  DropdownMenuItem(value: 2, child: Text('Ruta San Blas')),
                  DropdownMenuItem(value: 3, child: Text('Ruta Santa Ana')),
                ],
                onChanged: (val) => setModalState(() => selectedRouteId = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () async {
                if (selectedStaffId != null) {
                  await ApiService.assignTruck({
                    'camion_id': truck['id'],
                    'ruta_id': selectedRouteId,
                    'operador_id': selectedStaffId
                  });
                  if (mounted) {
                    Navigator.pop(context);
                    _loadAllData();
                  }
                }
              },
              child: const Text('ASIGNAR'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF97316);
    const secondaryColor = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Muni Cusco - Gestión'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _loadAllData, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _buildSection(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.inbox), label: 'Bandeja'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Personal'),
          BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Flota'),
        ],
      ),
    );
  }

  Widget _buildSection() {
    switch (_currentIndex) {
      case 0: return _buildInbox();
      case 1: return _buildStats();
      case 2: return _buildStaff();
      case 3: return _buildTrucks();
      default: return _buildInbox();
    }
  }

  Widget _buildInbox() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final report = _reports[index];
        final String estado = report['estado'] ?? 'registrado';
        Color statusColor = Colors.orange;
        if (estado == 'en_proceso') statusColor = Colors.blue;
        if (estado == 'atendido') statusColor = Colors.green;

        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Ticket: ${report['numero_ticket']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(estado.toUpperCase(), style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Ciudadano: ${report['nombres']} ${report['apellidos']}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 5),
                Text(report['descripcion'] ?? 'Sin descripción'),
                if (report['foto_url'] != null && report['foto_url'].toString().startsWith('http'))
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        report['foto_url'],
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 150,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                // Vista previa del mapa
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    'https://static-maps.yandex.ru/1.x/?ll=${report['longitud']},${report['latitud']}&z=16&l=map&size=450,150&pt=${report['longitud']},${report['latitud']},pm2rdm',
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.blueGrey[50],
                      child: const Center(child: Text('Vista previa del mapa no disponible', style: TextStyle(fontSize: 10))),
                    ),
                  ),
                ),
                const Divider(height: 25),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _openMap(report['latitud'], report['longitud']),
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('GPS'),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showReplyDialog(report),
                      icon: const Icon(Icons.reply, color: Colors.blue),
                    ),
                    if (estado != 'atendido')
                      IconButton(
                        onPressed: () => _handleCompleteReport(report['id']),
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                      ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        children: [
          _statCard('Total Reportes', '${_stats['totalReports'] ?? 0}', Colors.blue),
          _statCard('Pendientes', '${_stats['pendingReports'] ?? 0}', Colors.orange),
          _statCard('Atendidos', '${_stats['completedReports'] ?? 0}', Colors.green),
          _statCard('Personal Activo', '${_stats['staffCount'] ?? 0}', Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildStaff() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _staff.length,
      itemBuilder: (context, index) {
        final person = _staff[index];
        final isActive = person['estado'] == 'activo';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isActive ? Colors.green : Colors.red,
              child: Text(person['nombres'][0], style: const TextStyle(color: Colors.white)),
            ),
            title: Text('${person['nombres']} ${person['apellidos']}'),
            subtitle: Text(person['rol']),
            trailing: Switch(
              value: isActive,
              onChanged: (_) => _toggleStaffStatus(person['id'], person['estado']),
              activeColor: Colors.green,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrucks() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _trucks.length,
      itemBuilder: (context, index) {
        final truck = _trucks[index];
        final assignment = _assignments.firstWhere((a) => a['placa'] == truck['placa'], orElse: () => null);
        
        return Card(
          margin: const EdgeInsets.only(bottom: 15),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                const Icon(Icons.local_shipping, size: 40, color: Colors.blueGrey),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(truck['placa'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFF97316))),
                      Text(truck['modelo'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 5),
                      Text(
                        assignment != null 
                          ? 'Operador: ${assignment['operador_nombre']} ${assignment['operador_apellido']}' 
                          : 'Sin asignar',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showAssignTruckDialog(truck),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A), foregroundColor: Colors.white),
                  child: const Text('ASIGNAR'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
