import 'package:flutter/material.dart';
import '../controllers/supervisor_controller.dart';
import '../models/camion.dart';
import '../models/conductor.dart';
import '../models/reporte.dart';
import '../models/ruta.dart';
import 'format_utils.dart';
import 'landing_screen.dart';

const _kPrimary = Color(0xFFF97316);
const _kSecondary = Color(0xFF0F172A);

class SupervisorDashboard extends StatefulWidget {
  const SupervisorDashboard({super.key});

  @override
  State<SupervisorDashboard> createState() => _SupervisorDashboardState();
}

class _SupervisorDashboardState extends State<SupervisorDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _controller = SupervisorController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _controller.addListener(_onChanged);
    _controller.loadUser();
    _cargarReportes();
    _cargarTodo();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _cargarReportes() async {
    final ok = await _controller.cargarReportes();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error al cargar reportes')));
    }
  }

  Future<void> _cargarTodo() async {
    final ok = await _controller.cargarTodo();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al cargar datos del servidor')),
      );
    }
  }

  void _logout() async {
    await _controller.logout();
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LandingScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuario = _controller.usuario;
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Supervisor${usuario?.nombre != null ? ' · ${usuario!.nombre}' : ''}'),
        backgroundColor: _kSecondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              _cargarReportes();
              _cargarTodo();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _kPrimary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Reportes'),
            Tab(text: 'Rutas'),
            Tab(text: 'Horarios'),
            Tab(text: 'Camiones'),
            Tab(text: 'Conductores'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportesTab(),
          _controller.cargando ? const Center(child: CircularProgressIndicator(color: _kPrimary)) : _buildRutasTab(),
          _controller.cargando ? const Center(child: CircularProgressIndicator(color: _kPrimary)) : _buildHorariosTab(),
          _controller.cargando ? const Center(child: CircularProgressIndicator(color: _kPrimary)) : _buildCamionesTab(),
          _controller.cargando ? const Center(child: CircularProgressIndicator(color: _kPrimary)) : _buildConductoresTab(),
        ],
      ),
    );
  }

  // ── TAB: RUTAS ──────────────────────────────────────────────────
  Widget _buildRutasTab() {
    final rutas = _controller.rutas;
    if (rutas.isEmpty) {
      return const Center(child: Text('No hay rutas registradas'));
    }
    final asignadas = rutas.where((r) => r.camionId != null).length;
    return RefreshIndicator(
      onRefresh: _cargarTodo,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              '$asignadas de ${rutas.length} rutas con camión asignado hoy',
              style: const TextStyle(color: Colors.black54, fontSize: 13),
            ),
          ),
          ...rutas.map(_buildRutaCard),
        ],
      ),
    );
  }

  Widget _buildRutaCard(Ruta ruta) {
    final asignada = ruta.camionId != null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: asignada ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1), width: 3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ruta.nombre ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(ruta.zonaNombre ?? '', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: asignada ? const Color(0xFF22C55E) : const Color(0xFF94A3B8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    asignada ? 'ASIGNADA' : 'LIBRE',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(ruta.descripcion ?? '', style: const TextStyle(color: Colors.black54, fontSize: 12)),
            const SizedBox(height: 10),
            if (asignada) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_shipping, size: 15, color: Color(0xFF22C55E)),
                        const SizedBox(width: 6),
                        Text('${ruta.placa ?? ''} · ${ruta.modelo ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 12, color: Colors.black54),
                        const SizedBox(width: 4),
                        Text((ruta.fechaAsignacion ?? '').split('T').first,
                            style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        if (ruta.horaInicio != null) ...[
                          const SizedBox(width: 4),
                          Text('· ${hora(ruta.horaInicio)}–${hora(ruta.horaFin)}',
                              style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ],
                    ),
                    if (ruta.operadorNombres != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 12, color: Colors.black54),
                          const SizedBox(width: 4),
                          Text('${ruta.operadorNombres} ${ruta.operadorApellidos ?? ''}',
                              style: const TextStyle(fontSize: 11, color: Colors.black54)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _abrirAsignar(ruta),
                icon: const Icon(Icons.local_shipping, size: 16),
                label: Text(asignada ? 'Reasignar' : 'Asignar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: asignada ? const Color(0xFFF1F5F9) : _kPrimary,
                  foregroundColor: asignada ? Colors.black87 : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Día de la semana (formato horarios) correspondiente a una fecha.
  String _diaSemanaDeFecha(DateTime fecha) => kDiasSemana[fecha.weekday % 7];

  Future<void> _abrirAsignar(Ruta ruta) async {
    final hoy = DateTime.now();
    final dia = _diaSemanaDeFecha(hoy);
    final slots = slotsDisponibles(ruta);

    final horarioRuta = _controller.horarios.where(
      (h) => h.rutaId == ruta.id && h.diaSemana == dia,
    ).toList();
    final slotPorDefecto = horarioRuta.isNotEmpty
        ? slots.firstWhere(
            (s) => s['inicio'] == hora(horarioRuta.first.horaInicio),
            orElse: () => slots.first,
          )
        : slots.first;

    int? camionId;
    int? operadorId;
    String horaSeleccionada = '${slotPorDefecto['inicio']}-${slotPorDefecto['fin']}';
    DateTime fecha = hoy;
    bool asignando = false;

    final conductoresActivos = _controller.conductores
        .where((c) => c.conductorEstado == 'activo' && c.usuarioEstado == 'activo')
        .toList();

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(ruta.nombre ?? 'Asignar ruta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Camión Recolector', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: camionId,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      hint: const Text('— Selecciona un camión —'),
                      items: _controller.camiones.map<DropdownMenuItem<int>>((c) {
                        final bloqueado = c.estado == 'mantenimiento' || c.estado == 'de_baja';
                        return DropdownMenuItem<int>(
                          value: c.id,
                          enabled: !bloqueado,
                          child: Text(
                            '${c.placa} · ${c.modelo}${bloqueado ? ' ✗' : c.estado == 'en_ruta' ? ' · en ruta' : ' ✓'}',
                            style: TextStyle(color: bloqueado ? Colors.grey : Colors.black),
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setDialogState(() => camionId = v),
                    ),
                    const SizedBox(height: 14),
                    const Text('Conductor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: operadorId,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      hint: const Text('— Selecciona un conductor —'),
                      items: conductoresActivos.map<DropdownMenuItem<int>>((c) {
                        return DropdownMenuItem<int>(
                          value: c.usuarioId,
                          child: Text('${c.nombres} ${c.apellidos}'),
                        );
                      }).toList(),
                      onChanged: (v) => setDialogState(() => operadorId = v),
                    ),
                    const SizedBox(height: 14),
                    const Text('Horario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: horaSeleccionada,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
                      items: slots.map<DropdownMenuItem<String>>((s) {
                        return DropdownMenuItem<String>(
                          value: '${s['inicio']}-${s['fin']}',
                          child: Text(s['label']!),
                        );
                      }).toList(),
                      onChanged: (v) => setDialogState(() => horaSeleccionada = v!),
                    ),
                    const SizedBox(height: 14),
                    const Text('Fecha de Asignación', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final nueva = await showDatePicker(
                          context: context,
                          initialDate: fecha,
                          firstDate: DateTime(hoy.year - 1),
                          lastDate: DateTime(hoy.year + 1),
                        );
                        if (nueva != null) setDialogState(() => fecha = nueva);
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(fmtFecha(fecha)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: asignando
                      ? null
                      : () async {
                          if (camionId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Selecciona un camión')));
                            return;
                          }
                          if (operadorId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Selecciona un conductor')));
                            return;
                          }
                          setDialogState(() => asignando = true);
                          final partes = horaSeleccionada.split('-');
                          final resp = await _controller.asignarRuta({
                            'camion_id': camionId,
                            'ruta_id': ruta.id,
                            'operador_id': operadorId,
                            'fecha_asignacion': fmtFecha(fecha),
                            'hora_inicio': partes[0],
                            'hora_fin': partes[1],
                          });
                          if (dialogContext.mounted) Navigator.pop(dialogContext);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(resp['mensaje'] ?? 'Listo')),
                            );
                          }
                          await _cargarTodo();
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                  child: Text(asignando ? 'Asignando...' : 'Confirmar Asignación'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── TAB: HORARIOS ───────────────────────────────────────────────
  Widget _buildHorariosTab() {
    return RefreshIndicator(
      onRefresh: _cargarTodo,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: kDiasOrden.map((dia) {
          final esHoy = kDiasSemana[DateTime.now().weekday % 7] == dia;
          final items = _controller.horarios.where((h) => h.diaSemana == dia).toList();
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: esHoy ? _kPrimary : const Color(0xFFCBD5E1), width: 3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dia, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      if (esHoy)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(20)),
                          child: const Text('HOY', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (items.isEmpty)
                    const Text('Sin recojos programados', style: TextStyle(color: Colors.black45, fontSize: 12))
                  else
                    ...items.map((h) {
                      final rutasConId = _controller.rutas.where((r) => r.id == h.rutaId).toList();
                      final ruta = rutasConId.isNotEmpty ? rutasConId.first : null;
                      final asignadaHoy = ruta != null && ruta.camionId != null;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(h.rutaNombre ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(
                              '${h.zonaNombre ?? ''} · ${h.tipoResiduo ?? ''} · ${hora(h.horaInicio)}–${hora(h.horaFin)}',
                              style: const TextStyle(fontSize: 11, color: Colors.black54),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: asignadaHoy ? const Color(0xFF22C55E) : const Color(0xFFCBD5E1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    asignadaHoy ? 'ASIGNADA HOY' : 'SIN ASIGNAR',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (esHoy && !asignadaHoy && ruta != null) ...[
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      _tabController.animateTo(0);
                                      _abrirAsignar(ruta);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(color: _kPrimary, borderRadius: BorderRadius.circular(20)),
                                      child: const Text('Asignar', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── TAB: CAMIONES ───────────────────────────────────────────────
  Future<void> _handleCambiarEstadoCamion(Camion camion, String estado) async {
    final resp = await _controller.cambiarEstadoCamion(camion.id, estado);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp['mensaje'] ?? 'Estado actualizado')),
      );
    }
    await _cargarTodo();
  }

  Widget _buildCamionesTab() {
    final camiones = _controller.camiones;
    if (camiones.isEmpty) return const Center(child: Text('No hay camiones registrados'));
    return RefreshIndicator(
      onRefresh: _cargarTodo,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: camiones.length,
        itemBuilder: (context, i) {
          final cam = camiones[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text('${cam.placa} · ${cam.modelo}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${capacidadKg(cam.capacidadKg)} kg'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EstadoBadge(estado: cam.estado),
                  PopupMenuButton<String>(
                    onSelected: (v) => _handleCambiarEstadoCamion(cam, v),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'disponible', child: Text('Disponible')),
                      PopupMenuItem(value: 'mantenimiento', child: Text('Mantenimiento')),
                      PopupMenuItem(value: 'de_baja', child: Text('Dado de baja')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── TAB: CONDUCTORES ────────────────────────────────────────────
  Future<void> _handleCambiarEstadoConductor(Conductor c) async {
    final nuevoEstado = c.conductorEstado == 'activo' ? 'inactivo' : 'activo';
    final resp = await _controller.cambiarEstadoConductor(c.id, nuevoEstado);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resp['mensaje'] ?? 'Estado actualizado')),
      );
    }
    await _cargarTodo();
  }

  Widget _buildConductoresTab() {
    final conductores = _controller.conductores;
    if (conductores.isEmpty) return const Center(child: Text('No hay conductores registrados'));
    return RefreshIndicator(
      onRefresh: _cargarTodo,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: conductores.length,
        itemBuilder: (context, i) {
          final c = conductores[i];
          final enRuta = c.rutaActual != null && c.conductorEstado == 'activo';
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text('${c.apellidos}, ${c.nombres}', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(c.rutaActual ?? 'Sin asignar'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EstadoBadge(estado: enRuta ? 'en_ruta' : c.conductorEstado),
                  IconButton(
                    icon: Icon(
                      c.conductorEstado == 'activo' ? Icons.person_off : Icons.person,
                      color: c.conductorEstado == 'activo' ? Colors.red : Colors.green,
                    ),
                    onPressed: () => _handleCambiarEstadoConductor(c),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ── TAB: REPORTES CIUDADANOS ────────────────────────────────────
  Widget _buildReportesTab() {
    final reportes = _controller.reportes;
    final kpis = {
      'total': reportes.length,
      'pendientes': reportes.where((r) => r.estado == 'enviado').length,
      'enProceso': reportes.where((r) => r.estado == 'en_proceso').length,
      'completados': reportes.where((r) => r.estado == 'completado').length,
    };
    final reportesFiltrados = _controller.reportesFiltrados.toList()
      ..sort((a, b) => (a.estado == 'completado' ? 1 : 0).compareTo(b.estado == 'completado' ? 1 : 0));

    return RefreshIndicator(
      onRefresh: _cargarReportes,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          Row(
            children: [
              _kpiTile('Total', kpis['total']!, _kPrimary),
              const SizedBox(width: 8),
              _kpiTile('Pendientes', kpis['pendientes']!, const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _kpiTile('En Proceso', kpis['enProceso']!, const Color(0xFF3B82F6)),
              const SizedBox(width: 8),
              _kpiTile('Completados', kpis['completados']!, const Color(0xFF22C55E)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['todos', 'enviado', 'leido', 'en_proceso', 'completado'].map((f) {
                final activo = _controller.filtroReporte == f;
                final count = f == 'todos' ? null : reportes.where((r) => r.estado == f).length;
                final info = estadoInfo(f == 'todos' ? null : f);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${f == 'todos' ? 'Todos' : info['label']}${count != null ? ' ($count)' : ''}'),
                    selected: activo,
                    selectedColor: f == 'todos' ? _kSecondary : info['color'],
                    labelStyle: TextStyle(color: activo ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                    onSelected: (_) => _controller.setFiltroReporte(f),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          if (_controller.cargandoReportes)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: _kPrimary)))
          else if (reportesFiltrados.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('No hay reportes con este filtro', style: TextStyle(color: Colors.black54))),
            )
          else
            ...reportesFiltrados.map(_buildReporteCard),
        ],
      ),
    );
  }

  Widget _kpiTile(String label, int val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border(top: BorderSide(color: color, width: 4)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$val', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.black54, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildReporteCard(Reporte rep) {
    final info = estadoInfo(rep.estado);
    final descripcion = rep.descripcion ?? '';
    final respuesta = rep.respuestaSupervisor;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: info['color'], width: 4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rep.numeroTicket ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(
                      (rep.fechaCreacion ?? '').split('T').first,
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
                EstadoBadge(estado: rep.estado),
              ],
            ),
            const SizedBox(height: 8),
            Text('Ciudadano: ${rep.nombres ?? ''} ${rep.apellidos ?? ''}', style: const TextStyle(fontSize: 13)),
            Text('Tipo: ${rep.tipoResiduo ?? ''}', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 4),
            Text(
              descripcion.length > 100 ? '${descripcion.substring(0, 100)}…' : descripcion,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            if (respuesta != null && respuesta.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                  border: const Border(left: BorderSide(color: Color(0xFF22C55E), width: 3)),
                ),
                child: Text('Respuesta: $respuesta', style: const TextStyle(fontSize: 11, color: Color(0xFF166534))),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _abrirGestionarReporte(rep),
                    icon: const Icon(Icons.message, size: 14),
                    label: Text(respuesta != null ? 'Ver / Editar' : 'Responder'),
                    style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
                  ),
                ),
                if (rep.estado != 'completado') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleCompletarReporte(rep),
                      icon: const Icon(Icons.check_circle, size: 14),
                      label: const Text('Completar'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E), foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCompletarReporte(Reporte rep) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Marcar ${rep.numeroTicket} como completado?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirmar')),
        ],
      ),
    );
    if (confirmar != true) return;
    final resp = await _controller.responderReporte(rep.id, {
      'respuesta_supervisor': rep.respuestaSupervisor ?? 'Incidencia atendida y resuelta.',
      'estado': 'completado',
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['mensaje'] ?? 'Reporte actualizado')));
    }
    await _cargarReportes();
  }

  Future<void> _abrirGestionarReporte(Reporte rep) async {
    final respuestaCtrl = TextEditingController(text: rep.respuestaSupervisor ?? '');
    String nuevoEstado = (rep.estado == 'enviado' || rep.estado == 'leido') ? 'en_proceso' : rep.estado!;
    bool enviando = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Gestionar Reporte — ${rep.numeroTicket}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ciudadano: ${rep.nombres} ${rep.apellidos}', style: const TextStyle(fontSize: 12)),
                      Text('Correo: ${rep.correo ?? '—'}', style: const TextStyle(fontSize: 12)),
                      Text('Tipo: ${rep.tipoResiduo ?? ''}', style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 6),
                      Text('Descripción: ${rep.descripcion ?? ''}', style: const TextStyle(fontSize: 12)),
                      if (rep.fotoUrl != null && rep.fotoUrl != 'https://via.placeholder.com/300') ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(rep.fotoUrl!, height: 140, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ],
                      if (rep.latitud != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Coordenadas: ${double.tryParse(rep.latitud.toString())?.toStringAsFixed(4)}, ${double.tryParse(rep.longitud.toString())?.toStringAsFixed(4)}',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Cambiar estado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                DropdownButtonFormField<String>(
                  value: nuevoEstado,
                  items: const [
                    DropdownMenuItem(value: 'en_proceso', child: Text('En Proceso')),
                    DropdownMenuItem(value: 'completado', child: Text('Completado')),
                    DropdownMenuItem(value: 'rechazado', child: Text('Rechazado')),
                  ],
                  onChanged: (v) => setDialogState(() => nuevoEstado = v!),
                ),
                const SizedBox(height: 14),
                const Text('Respuesta al ciudadano *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: respuestaCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Escribe la respuesta que recibirá el ciudadano...',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: enviando
                  ? null
                  : () async {
                      if (respuestaCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('La respuesta no puede estar vacía')));
                        return;
                      }
                      setDialogState(() => enviando = true);
                      final resp = await _controller.responderReporte(rep.id, {
                        'respuesta_supervisor': respuestaCtrl.text.trim(),
                        'estado': nuevoEstado,
                      });
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(resp['mensaje'] ?? 'Reporte actualizado')));
                      }
                      await _cargarReportes();
                    },
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
              child: Text(enviando ? 'Enviando...' : 'Enviar Respuesta'),
            ),
          ],
        ),
      ),
    );
  }
}
