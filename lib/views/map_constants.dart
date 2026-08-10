import 'package:latlong2/latlong.dart';

// Mismo centro y tiles OSM que usa el mapa de la web (MapaPicker.jsx), para
// que la ubicación se vea de forma consistente en toda la app.
const LatLng kCuscoCenter = LatLng(-13.5319, -71.9675);
// Sin subdominios {s}: la política actual de OSM desaconseja repartir la
// carga entre a/b/c.tile — un solo dominio es lo recomendado hoy.
const String kOsmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
