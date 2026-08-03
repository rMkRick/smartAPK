import 'package:flutter/material.dart';
import '../controllers/admin_controller.dart';
import '../models/camion.dart';
import '../models/conductor.dart';
import 'format_utils.dart';
import 'landing_screen.dart';

const _kPrimary = Color(0xFFF97316);
const _kSecondary = Color(0xFF0F172A);

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _controller = AdminController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _controller.addListener(_onChanged);
    _controller.loadUser();
    _controller.cargarTodo();
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
    final conductores = _controller.conductores;
    final camiones = _controller.camiones;
    final rutas = _controller.rutas;
    final usuario = _controller.usuario;

    final conductoresActivos = conductores.where((c) => c.conductorEstado == 'activo').length;
    final enRutaHoy = conductores.where((c) => c.rutaActual != null).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Admin${usuario?.nombre != null ? ' · ${usuario!.nombre}' : ''}'),
        backgroundColor: _kSecondary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _cargarTodo, icon: const Icon(Icons.refresh)),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _kPrimary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Conductores'),
            Tab(text: 'Camiones'),
            Tab(text: 'Rutas'),
          ],
        ),
      ),
      body: _controller.cargando
          ? const Center(child: CircularProgressIndicator(color: _kPrimary))
          : Column(
              children: [
                _buildStatsRow(conductoresActivos, enRutaHoy, camiones.length, rutas.length),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildConductoresTab(conductores),
                      _buildCamionesTab(camiones),
                      _buildRutasTab(rutas),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) {
          if (_tabController.index != 0) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            onPressed: () => _abrirFormularioConductor(null),
            backgroundColor: _kPrimary,
            icon: const Icon(Icons.add),
            label: const Text('Nuevo Conductor'),
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(int conductoresActivos, int enRutaHoy, int totalCamiones, int totalRutas) {
    final stats = [
      {'label': 'Conductores activos', 'val': conductoresActivos, 'color': _kPrimary},
      {'label': 'Camiones', 'val': totalCamiones, 'color': const Color(0xFF22C55E)},
      {'label': 'Rutas', 'val': totalRutas, 'color': const Color(0xFF8B5CF6)},
      {'label': 'En ruta hoy', 'val': enRutaHoy, 'color': const Color(0xFF0EA5E9)},
    ];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        height: 96,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: stats.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final s = stats[i];
            return Container(
              width: 130,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border(top: BorderSide(color: s['color'] as Color, width: 4)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${s['val']}',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: s['color'] as Color)),
                  const SizedBox(height: 4),
                  Text('${s['label']}', style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── TAB: CONDUCTORES ────────────────────────────────────────────
  Future<void> _handleCambiarEstadoConductor(Conductor c) async {
    final nuevoEstado = c.conductorEstado == 'activo' ? 'inactivo' : 'activo';
    final resp = await _controller.cambiarEstadoConductor(c.id, nuevoEstado);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['mensaje'] ?? 'Estado actualizado')));
    }
    await _cargarTodo();
  }

  Widget _buildConductoresTab(List<Conductor> conductores) {
    if (conductores.isEmpty) return const Center(child: Text('No hay conductores registrados'));
    return RefreshIndicator(
      onRefresh: _cargarTodo,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 90),
        itemCount: conductores.length,
        itemBuilder: (context, i) {
          final c = conductores[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12),
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
                            Text('${c.apellidos}, ${c.nombres}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            Text(c.correo ?? '', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                          ],
                        ),
                      ),
                      EstadoBadge(estado: c.conductorEstado),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Lic: ${c.licencia ?? '—'} (${c.categoriaLicencia ?? '—'}) · ${c.telefono ?? '—'}',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Ruta hoy: ${c.rutaActual ?? 'Sin asignar'}${c.camionActual != null ? ' · ${c.camionActual}' : ''}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _abrirAsignarRuta(c),
                          icon: const Icon(Icons.alt_route, size: 15),
                          label: const Text('Asignar'),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _abrirFormularioConductor(c),
                          icon: const Icon(Icons.edit, size: 15),
                          label: const Text('Editar'),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF3B82F6)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(
                          c.conductorEstado == 'activo' ? Icons.person_off : Icons.person,
                          color: c.conductorEstado == 'activo' ? Colors.red : Colors.green,
                        ),
                        onPressed: () => _handleCambiarEstadoConductor(c),
                      ),
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

  Future<void> _abrirFormularioConductor(Conductor? conductor) async {
    final esNuevo = conductor == null;
    final nombresCtrl = TextEditingController(text: conductor?.nombres ?? '');
    final apellidosCtrl = TextEditingController(text: conductor?.apellidos ?? '');
    final dniCtrl = TextEditingController(text: conductor?.dni ?? '');
    final correoCtrl = TextEditingController(text: conductor?.correo ?? '');
    final contrasenaCtrl = TextEditingController();
    final telefonoCtrl = TextEditingController(text: conductor?.telefono ?? '');
    final licenciaCtrl = TextEditingController(text: conductor?.licencia ?? '');
    String categoria = conductor?.categoriaLicencia ?? 'BIIIC';
    String estado = conductor?.conductorEstado ?? 'activo';
    DateTime? fechaIngreso = conductor?.fechaIngreso != null
        ? DateTime.tryParse(conductor!.fechaIngreso!)
        : null;
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(esNuevo ? 'Nuevo Conductor' : 'Editar Conductor'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nombresCtrl, decoration: const InputDecoration(labelText: 'Nombres *')),
                TextField(controller: apellidosCtrl, decoration: const InputDecoration(labelText: 'Apellidos *')),
                TextField(controller: dniCtrl, decoration: const InputDecoration(labelText: 'DNI')),
                TextField(controller: correoCtrl, decoration: const InputDecoration(labelText: 'Correo *'), keyboardType: TextInputType.emailAddress),
                if (esNuevo)
                  TextField(controller: contrasenaCtrl, decoration: const InputDecoration(labelText: 'Contraseña *'), obscureText: true),
                TextField(controller: telefonoCtrl, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
                TextField(controller: licenciaCtrl, decoration: const InputDecoration(labelText: 'N° Licencia *')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: categoria,
                  decoration: const InputDecoration(labelText: 'Categoría'),
                  items: kCategorias.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setDialogState(() => categoria = v!),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final nueva = await showDatePicker(
                      context: context,
                      initialDate: fechaIngreso ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (nueva != null) setDialogState(() => fechaIngreso = nueva);
                  },
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(fechaIngreso != null ? fmtFecha(fechaIngreso!) : 'Fecha de ingreso'),
                ),
                if (!esNuevo) ...[
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: estado,
                    decoration: const InputDecoration(labelText: 'Estado'),
                    items: const [
                      DropdownMenuItem(value: 'activo', child: Text('Activo')),
                      DropdownMenuItem(value: 'inactivo', child: Text('Inactivo')),
                      DropdownMenuItem(value: 'suspendido', child: Text('Suspendido')),
                    ],
                    onChanged: (v) => setDialogState(() => estado = v!),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      if (nombresCtrl.text.trim().isEmpty ||
                          apellidosCtrl.text.trim().isEmpty ||
                          correoCtrl.text.trim().isEmpty ||
                          licenciaCtrl.text.trim().isEmpty ||
                          (esNuevo && contrasenaCtrl.text.trim().isEmpty)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Completa los campos obligatorios (*)')));
                        return;
                      }
                      setDialogState(() => guardando = true);
                      final datos = {
                        'nombres': nombresCtrl.text.trim(),
                        'apellidos': apellidosCtrl.text.trim(),
                        'dni': dniCtrl.text.trim(),
                        'correo': correoCtrl.text.trim(),
                        'telefono': telefonoCtrl.text.trim(),
                        'licencia': licenciaCtrl.text.trim(),
                        'categoria_licencia': categoria,
                        'fecha_ingreso': fechaIngreso != null ? fmtFecha(fechaIngreso!) : null,
                        if (esNuevo) 'contrasena': contrasenaCtrl.text.trim(),
                        if (!esNuevo) 'estado': estado,
                      };
                      final resp = esNuevo
                          ? await _controller.crearConductor(datos)
                          : await _controller.actualizarConductor(conductor.id, datos);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(resp['mensaje'] ?? 'Listo')));
                      }
                      await _cargarTodo();
                    },
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
              child: Text(guardando ? 'Guardando...' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _abrirAsignarRuta(Conductor conductor) async {
    int? rutaId;
    int? camionId;
    DateTime fecha = DateTime.now();
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Asignar Ruta'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF0F9FF), borderRadius: BorderRadius.circular(8)),
                  child: Text('${conductor.apellidos}, ${conductor.nombres} · Lic: ${conductor.licencia}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(height: 14),
                const Text('Ruta *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                DropdownButtonFormField<int>(
                  value: rutaId,
                  isExpanded: true,
                  hint: const Text('— Seleccionar ruta —'),
                  items: _controller.rutas.map<DropdownMenuItem<int>>((r) => DropdownMenuItem(value: r.id, child: Text(r.nombre ?? ''))).toList(),
                  onChanged: (v) => setDialogState(() => rutaId = v),
                ),
                const SizedBox(height: 14),
                const Text('Camión * (solo disponibles)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                DropdownButtonFormField<int>(
                  value: camionId,
                  isExpanded: true,
                  hint: const Text('— Seleccionar camión —'),
                  items: _controller.camiones
                      .where((c) => c.estado == 'disponible')
                      .map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c.id, child: Text('${c.placa} — ${c.modelo}')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => camionId = v),
                ),
                const SizedBox(height: 14),
                const Text('Fecha', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                OutlinedButton.icon(
                  onPressed: () async {
                    final nueva = await showDatePicker(
                      context: context, initialDate: fecha,
                      firstDate: DateTime(fecha.year - 1), lastDate: DateTime(fecha.year + 1),
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
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      if (rutaId == null || camionId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Selecciona ruta y camión')));
                        return;
                      }
                      setDialogState(() => guardando = true);
                      final resp = await _controller.asignarRuta({
                        'ruta_id': rutaId,
                        'camion_id': camionId,
                        'operador_id': conductor.usuarioId,
                        'fecha_asignacion': fmtFecha(fecha),
                      });
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(resp['mensaje'] ?? 'Listo')));
                      }
                      await _cargarTodo();
                    },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
              child: Text(guardando ? 'Asignando...' : 'Asignar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB: CAMIONES ───────────────────────────────────────────────
  Future<void> _handleCambiarEstadoCamion(Camion camion, String estado) async {
    final resp = await _controller.cambiarEstadoCamion(camion.id, estado);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(resp['mensaje'] ?? 'Estado actualizado')));
    }
    await _cargarTodo();
  }

  Widget _buildCamionesTab(List<Camion> camiones) {
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
                    onSelected: (v) {
                      if (v == '__editar__') {
                        _abrirEditarCamion(cam);
                      } else {
                        _handleCambiarEstadoCamion(cam, v);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'disponible', child: Text('Disponible')),
                      PopupMenuItem(value: 'en_ruta', child: Text('En ruta')),
                      PopupMenuItem(value: 'mantenimiento', child: Text('Mantenimiento')),
                      PopupMenuItem(value: 'de_baja', child: Text('Dado de baja')),
                      PopupMenuDivider(),
                      PopupMenuItem(value: '__editar__', child: Text('Editar camión')),
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

  Future<void> _abrirEditarCamion(Camion camion) async {
    final placaCtrl = TextEditingController(text: camion.placa ?? '');
    final modeloCtrl = TextEditingController(text: camion.modelo ?? '');
    final capacidadCtrl = TextEditingController(text: '${camion.capacidadKg ?? ''}');
    String estado = camion.estado ?? 'disponible';
    bool guardando = false;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Editar Camión'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: placaCtrl, decoration: const InputDecoration(labelText: 'Placa *')),
                TextField(controller: modeloCtrl, decoration: const InputDecoration(labelText: 'Modelo')),
                TextField(
                  controller: capacidadCtrl,
                  decoration: const InputDecoration(labelText: 'Capacidad (kg)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: estado,
                  decoration: const InputDecoration(labelText: 'Estado'),
                  items: const [
                    DropdownMenuItem(value: 'disponible', child: Text('Disponible')),
                    DropdownMenuItem(value: 'en_ruta', child: Text('En ruta')),
                    DropdownMenuItem(value: 'mantenimiento', child: Text('Mantenimiento')),
                    DropdownMenuItem(value: 'de_baja', child: Text('Dado de baja')),
                  ],
                  onChanged: (v) => setDialogState(() => estado = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: guardando
                  ? null
                  : () async {
                      if (placaCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('La placa es obligatoria')));
                        return;
                      }
                      setDialogState(() => guardando = true);
                      final resp = await _controller.actualizarCamion(camion.id, {
                        'placa': placaCtrl.text.trim(),
                        'modelo': modeloCtrl.text.trim(),
                        'capacidad_kg': double.tryParse(capacidadCtrl.text.trim()) ?? 0,
                        'estado': estado,
                      });
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(resp['mensaje'] ?? 'Listo')));
                      }
                      await _cargarTodo();
                    },
              style: ElevatedButton.styleFrom(backgroundColor: _kPrimary, foregroundColor: Colors.white),
              child: Text(guardando ? 'Guardando...' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  // ── TAB: RUTAS (solo lectura) ───────────────────────────────────
  Widget _buildRutasTab(List rutas) {
    if (rutas.isEmpty) return const Center(child: Text('No hay rutas registradas'));
    return RefreshIndicator(
      onRefresh: _cargarTodo,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: rutas.length,
        itemBuilder: (context, i) {
          final r = rutas[i];
          final puntos = r.waypoints?.length ?? 0;
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(r.nombre ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${r.zonaNombre ?? ''} · $puntos pts GPS'),
              trailing: Text(
                r.placa ?? '—',
                style: TextStyle(fontWeight: FontWeight.bold, color: r.placa != null ? const Color(0xFF22C55E) : Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
