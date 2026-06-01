import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class GuestReportScreen extends StatefulWidget {
  const GuestReportScreen({super.key});

  @override
  State<GuestReportScreen> createState() => _GuestReportScreenState();
}

class _GuestReportScreenState extends State<GuestReportScreen> {
  final _descripcionController = TextEditingController();
  File? _imageFile;
  Position? _currentPosition;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _submitReport() async {
    setState(() => _isLoading = true);
    await _getCurrentLocation();

    if (_currentPosition == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo obtener la ubicación')));
      return;
    }

    try {
      final reportData = {
        'usuario_id': null,
        'descripcion': _descripcionController.text.trim(),
        'latitud': _currentPosition!.latitude,
        'longitud': _currentPosition!.longitude,
        'foto_url': 'https://via.placeholder.com/300',
        'tipo_residuo_id': 1,
      };

      final response = await ApiService.createReport(reportData);
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Reporte Enviado'),
            content: Text('Su reporte ha sido registrado con éxito. Ticket: ${response['numero_ticket']}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al enviar reporte')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFF97316);
    const secondaryColor = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: secondaryColor,
      appBar: AppBar(
        title: const Text('Reporte Invitado'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Reportar Residuo',
              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const Text(
              'No necesitas cuenta para ayudarnos',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 40),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe el problema...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Evidencia (Foto)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: secondaryColor,
                          ),
                        ),
                        if (_imageFile != null)
                          const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(Icons.check_circle, color: Colors.green),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading 
                        ? const CircularProgressIndicator(color: Colors.white) 
                        : const Text('ENVIAR REPORTE AHORA', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
