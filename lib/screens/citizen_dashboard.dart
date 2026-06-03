import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'landing_screen.dart';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  Map<String, dynamic>? _usuario;
  List<dynamic> _misReportes = [];
  bool _isLoading = false;
  bool _isLocationLoading = true;
  
  final _descripcionController = TextEditingController();
  File? _imageFile;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _startLocationTracking();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('usuario');
    if (userStr != null) {
      setState(() {
        _usuario = jsonDecode(userStr);
      });
      _fetchReports();
    } else {
      _logout();
    }
  }

  void _startLocationTracking() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) setState(() => _isLocationLoading = false);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _isLocationLoading = false);
        return;
      }
    }

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 5),
    ).listen((Position position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLocationLoading = false;
        });
      }
    });
  }

  Future<void> _fetchReports() async {
    if (_usuario == null) return;
    final reports = await ApiService.getUserReports(_usuario!['id']);
    if (mounted) {
      setState(() {
        _misReportes = reports;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar Foto (Cámara)'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Cargar Foto (Galería)'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, tome o cargue una foto')));
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Esperando ubicación GPS...')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      String fotoUrl = 'https://via.placeholder.com/300';
      if (_imageFile != null) {
        final uploadedUrl = await ApiService.uploadImage(_imageFile!);
        if (uploadedUrl != null) {
          fotoUrl = uploadedUrl;
        }
      }

      final reportData = {
        'usuario_id': _usuario!['id'],
        'descripcion': _descripcionController.text.trim(),
        'latitud': _currentPosition!.latitude,
        'longitud': _currentPosition!.longitude,
        'foto_url': fotoUrl, 
        'tipo_residuo_id': 1,
      };

      final response = await ApiService.createReport(reportData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reporte enviado. Ticket: ${response['numero_ticket']}')),
        );
        _descripcionController.clear();
        setState(() {
          _imageFile = null;
        });
        _fetchReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al enviar reporte')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReport(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar reporte?'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final response = await ApiService.deleteReport(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['mensaje'] ?? 'Reporte eliminado')),
        );
        _fetchReports();
      }
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LandingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF97316);
    const secondaryColor = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('Municipio Cusco - Ciudadano'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hola, ${_usuario?['nombres'] ?? 'Usuario'}!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: secondaryColor),
            ),
            const SizedBox(height: 20),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nuevo Reporte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe el residuo...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Ubicación en tiempo real
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _isLocationLoading 
                              ? const Text('Buscando GPS...', style: TextStyle(fontSize: 12))
                              : Text(
                                  _currentPosition != null 
                                    ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, Lon: ${_currentPosition!.longitude.toStringAsFixed(6)}'
                                    : 'GPS no disponible',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                          ),
                          if (_currentPosition != null)
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: _showImageSourceActionSheet,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Evidencia (Foto)'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], foregroundColor: secondaryColor),
                        ),
                        const SizedBox(width: 10),
                        if (_imageFile != null)
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ENVIAR REPORTE'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text('Mis Reportes Recientes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: secondaryColor)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _misReportes.length,
              itemBuilder: (context, index) {
                final report = _misReportes[index];
                final String estado = report['estado'] ?? 'registrado';
                final String? comentario = report['comentario_admin'];

                Color statusColor = Colors.orange;
                String statusText = 'RECIBIDO';
                
                if (estado == 'en_proceso') {
                  statusColor = Colors.blue;
                  statusText = 'EN PROCESO';
                } else if (estado == 'atendido') {
                  statusColor = Colors.green;
                  statusText = 'ATENDIDO';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.description, color: primaryColor),
                        ),
                        title: Text('Ticket: ${report['numero_ticket']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(report['descripcion'] ?? 'Sin descripción', maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                          child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                      ),
                      if (comentario != null && comentario.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.message, size: 14, color: Colors.green),
                                  SizedBox(width: 5),
                                  Text('Respuesta del Supervisor:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(comentario, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black87)),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(right: 10, bottom: 5, left: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              report['fecha_creacion'].toString().split('T')[0],
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _deleteReport(report['id']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
