import 'package:flutter/material.dart';
import '../controllers/guest_report_controller.dart';

class GuestReportScreen extends StatefulWidget {
  const GuestReportScreen({super.key});

  @override
  State<GuestReportScreen> createState() => _GuestReportScreenState();
}

class _GuestReportScreenState extends State<GuestReportScreen> {
  final _controller = GuestReportController();
  final _descripcionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final outcome = await _controller.submitReport(_descripcionController.text);
    if (!mounted) return;

    if (outcome.success) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reporte Enviado'),
          content: Text('Su reporte ha sido registrado con éxito. Ticket: ${outcome.message}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(outcome.message)));
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
                          onPressed: _controller.pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Evidencia (Foto)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: secondaryColor,
                          ),
                        ),
                        if (_controller.imageFile != null)
                          const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(Icons.check_circle, color: Colors.green),
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: _controller.isLoading ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _controller.isLoading
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
