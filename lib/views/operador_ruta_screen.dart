import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../controllers/operador_controller.dart';
import '../models/ruta.dart';
import 'map_constants.dart';

/// Mapa de la ruta en curso: dibuja el trayecto desde la posición GPS actual
/// del operador hasta el punto de inicio y luego todo el recorrido asignado.
class OperadorRutaScreen extends StatefulWidget {
  final OperadorController controller;
  final Ruta ruta;

  const OperadorRutaScreen({super.key, required this.controller, required this.ruta});

  @override
  State<OperadorRutaScreen> createState() => _OperadorRutaScreenState();
}

class _OperadorRutaScreenState extends State<OperadorRutaScreen> {
  final MapController _mapController = MapController();
  bool _centrado = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    _mapController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    final pos = widget.controller.currentPosition;
    if (pos != null && !_centrado) {
      _centrado = true;
      try {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    const secondaryColor = Color(0xFF0F172A);
    final pos = widget.controller.currentPosition;
    final ubicacionActual = pos != null ? LatLng(pos.latitude, pos.longitude) : null;
    final puntosRuta = widget.ruta.puntosRuta;

    // Trayecto completo: de donde está el operador al inicio de la ruta y
    // luego unido con todos los puntos de la ruta asignada.
    final trayecto = [
      ?ubicacionActual,
      ...puntosRuta,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ruta.nombre ?? 'Ruta asignada'),
        backgroundColor: secondaryColor,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: ubicacionActual ?? (puntosRuta.isNotEmpty ? puntosRuta.first : kCuscoCenter),
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: kOsmTileUrl,
                userAgentPackageName: 'com.smartwaste.smartapk',
              ),
              if (trayecto.length > 1)
                PolylineLayer(polylines: [
                  Polyline(points: trayecto, strokeWidth: 4, color: const Color(0xFF3B82F6)),
                ]),
              MarkerLayer(markers: [
                if (ubicacionActual != null)
                  Marker(
                    point: ubicacionActual,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.my_location, color: Color(0xFF0EA5E9), size: 32),
                  ),
                for (var i = 0; i < puntosRuta.length; i++)
                  Marker(
                    point: puntosRuta[i],
                    width: 36,
                    height: 36,
                    child: Icon(
                      i == 0
                          ? Icons.flag_circle
                          : (i == puntosRuta.length - 1 ? Icons.sports_score : Icons.circle),
                      color: i == 0
                          ? Colors.green
                          : (i == puntosRuta.length - 1 ? Colors.red : const Color(0xFFF97316)),
                      size: i == 0 || i == puntosRuta.length - 1 ? 32 : 14,
                    ),
                  ),
              ]),
            ],
          ),
          if (widget.controller.currentPosition == null)
            const Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Expanded(child: Text('Buscando tu ubicación GPS...')),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0EA5E9),
        onPressed: ubicacionActual == null
            ? null
            : () => _mapController.move(ubicacionActual, 15),
        child: const Icon(Icons.gps_fixed, color: Colors.white),
      ),
    );
  }
}
