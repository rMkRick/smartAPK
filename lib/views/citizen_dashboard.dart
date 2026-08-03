import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/citizen_controller.dart';
import 'landing_screen.dart';

// Mismo centro y tiles OSM que usa el mapa de la web (MapaPicker.jsx), para
// que la ubicación se vea y se elija de forma consistente en ambas apps.
const LatLng kCuscoCenter = LatLng(-13.5319, -71.9675);
// Sin subdominios {s}: la política actual de OSM desaconseja repartir la
// carga entre a/b/c.tile — un solo dominio es lo recomendado hoy.
const String kOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

class CitizenDashboard extends StatefulWidget {
  const CitizenDashboard({super.key});

  @override
  State<CitizenDashboard> createState() => _CitizenDashboardState();
}

class _CitizenDashboardState extends State<CitizenDashboard> {
  final _controller = CitizenController();
  final _descripcionController = TextEditingController();
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerChanged);
    _loadUser();
    _controller.startLocationTracking();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    _descripcionController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});

    // Centra el mapa en el GPS mientras el usuario no haya fijado un punto a mano.
    final pos = _controller.currentPosition;
    if (pos != null && _controller.pickedPosition == null) {
      try {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
      } catch (_) {
        // el mapa puede no estar montado todavía; se centrará al construirse
      }
    }
  }

  Future<void> _loadUser() async {
    final ok = await _controller.loadUser();
    if (!ok) _logout();
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
                _controller.pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Cargar Foto (Galería)'),
              onTap: () {
                Navigator.pop(context);
                _controller.pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    final outcome = await _controller.submitReport(_descripcionController.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(outcome.message)));
    if (outcome.success) {
      _descripcionController.clear();
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
      final mensaje = await _controller.deleteReport(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
      }
    }
  }

  void _logout() async {
    await _controller.logout();
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

    final usuario = _controller.usuario;
    final misReportes = _controller.misReportes;
    final isLoading = _controller.isLoading;
    final isLocationLoading = _controller.isLocationLoading;
    final ubicacionEfectiva = _controller.ubicacionEfectiva;
    final currentPosition = _controller.currentPosition;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text('SmartAPk - Ciudadano'),
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
              'Hola, ${usuario?.nombres ?? 'Usuario'}!',
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

                    // Ubicación del incidente: mismo mapa OSM que en la web
                    // (toca el mapa para fijarla a mano, o usa el botón de GPS).
                    const Text('Ubicación del Incidente', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text(
                      'Toca el mapa para fijar la ubicación o usa tu GPS.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 220,
                        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFCBD5E1))),
                        child: isLocationLoading && _controller.pickedPosition == null
                            ? const Center(child: CircularProgressIndicator())
                            : FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: ubicacionEfectiva ?? kCuscoCenter,
                                  initialZoom: 15,
                                  onTap: (tapPosition, point) => _controller.selectPickedPosition(point),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: kOsmTileUrl,
                                    userAgentPackageName: 'com.smartwaste.smartapk',
                                  ),
                                  if (ubicacionEfectiva != null)
                                    MarkerLayer(markers: [
                                      Marker(
                                        point: ubicacionEfectiva,
                                        width: 40,
                                        height: 40,
                                        child: const Icon(Icons.location_pin, color: Colors.redAccent, size: 40),
                                      ),
                                    ]),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: ubicacionEfectiva != null ? Colors.green : Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isLocationLoading && ubicacionEfectiva == null
                                ? 'Buscando GPS...'
                                : ubicacionEfectiva != null
                                    ? 'Ubicación: ${ubicacionEfectiva.latitude.toStringAsFixed(6)}, ${ubicacionEfectiva.longitude.toStringAsFixed(6)}'
                                    : 'GPS no disponible, toca el mapa para elegir',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: currentPosition == null
                          ? null
                          : () {
                              _controller.clearPickedPosition();
                              try {
                                _mapController.move(
                                  LatLng(currentPosition.latitude, currentPosition.longitude), 15);
                              } catch (_) {}
                            },
                      icon: const Icon(Icons.gps_fixed, size: 16),
                      label: const Text('Usar mi ubicación GPS'),
                      style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF0EA5E9)),
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
                        if (_controller.imageFile != null)
                          const Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('ENVIAR REPORTE'),
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
              itemCount: misReportes.length,
              itemBuilder: (context, index) {
                final report = misReportes[index];
                final String estado = report.estado ?? 'registrado';
                final String? comentario = report.comentarioAdmin;

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
                        title: Text('Ticket: ${report.numeroTicket}', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(report.descripcion ?? 'Sin descripción', maxLines: 2, overflow: TextOverflow.ellipsis),
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
                              (report.fechaCreacion ?? '').split('T')[0],
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                              onPressed: () => _deleteReport(report.id),
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
