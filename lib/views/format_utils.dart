import 'package:flutter/material.dart';
import '../models/ruta.dart';

// Helpers de formato/presentación compartidos entre AdminDashboard y
// SupervisorDashboard (Views) — antes duplicados en ambos archivos.

const List<String> kCategorias = ['AI', 'AII', 'AIII', 'BI', 'BII', 'BIII', 'BIIIC'];

const List<String> kDiasSemana = [
  'Domingo', 'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado',
];
const List<String> kDiasOrden = [
  'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
];

// Franjas horarias permitidas al asignar una ruta (turnos de 3 horas). El
// Centro Histórico solo recoge de noche; el resto de rutas es diurno. Al
// terminar la hora_fin del turno, el camión y el conductor vuelven solos a
// "disponible"/"activo" (lo calcula el backend, no hace falta nada manual).
const List<Map<String, String>> kSlotsHorario = [
  {'inicio': '09:00', 'fin': '12:00', 'label': '9:00 a. m. – 12:00 p. m.'},
  {'inicio': '10:00', 'fin': '13:00', 'label': '10:00 a. m. – 1:00 p. m.'},
  {'inicio': '14:00', 'fin': '17:00', 'label': '2:00 p. m. – 5:00 p. m.'},
  {'inicio': '15:00', 'fin': '18:00', 'label': '3:00 p. m. – 6:00 p. m.'},
];
const Map<String, String> kSlotCentroHistorico = {
  'inicio': '20:00', 'fin': '23:00', 'label': '8:00 p. m. – 11:00 p. m.',
};

List<Map<String, String>> slotsDisponibles(Ruta ruta) =>
    (ruta.zonaNombre == 'Centro Histórico') ? [kSlotCentroHistorico] : kSlotsHorario;

String fmtFecha(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String hora(dynamic v) => v == null ? '' : v.toString().substring(0, 5);

String capacidadKg(dynamic v) {
  final n = v is String ? double.tryParse(v) : (v as num?)?.toDouble();
  return n != null ? n.toStringAsFixed(0) : (v?.toString() ?? '—');
}

Map<String, dynamic> estadoInfo(String? estado) {
  const colores = {
    'disponible': Color(0xFF22C55E),
    'en_ruta': Color(0xFF3B82F6),
    'mantenimiento': Color(0xFFEAB308),
    'de_baja': Color(0xFFEF4444),
    'activo': Color(0xFF22C55E),
    'inactivo': Color(0xFFEF4444),
    'suspendido': Color(0xFFEAB308),
    'enviado': Color(0xFFF97316),
    'leido': Color(0xFFEAB308),
    'en_proceso': Color(0xFF3B82F6),
    'completado': Color(0xFF22C55E),
    'rechazado': Color(0xFFEF4444),
  };
  const labels = {
    'disponible': 'Disponible',
    'en_ruta': 'En Ruta',
    'mantenimiento': 'Mantenimiento',
    'de_baja': 'Dado de baja',
    'activo': 'Activo',
    'inactivo': 'Inactivo',
    'suspendido': 'Suspendido',
    'enviado': 'Enviado',
    'leido': 'Leído',
    'en_proceso': 'En Proceso',
    'completado': 'Completado',
    'rechazado': 'Rechazado',
  };
  return {
    'color': colores[estado] ?? const Color(0xFF94A3B8),
    'label': labels[estado] ?? (estado ?? '—'),
  };
}

class EstadoBadge extends StatelessWidget {
  final String? estado;
  const EstadoBadge({super.key, required this.estado});

  @override
  Widget build(BuildContext context) {
    final info = estadoInfo(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: info['color'], borderRadius: BorderRadius.circular(20)),
      child: Text(
        info['label'],
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
