import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_apk/models/ruta.dart';
import 'package:smart_apk/views/format_utils.dart';

void main() {
  group('fmtFecha', () {
    test('formatea con ceros a la izquierda', () {
      expect(fmtFecha(DateTime(2026, 3, 5)), '2026-03-05');
    });
  });

  group('hora', () {
    test('recorta segundos de un valor HH:mm:ss', () {
      expect(hora('09:00:00'), '09:00');
    });

    test('devuelve vacío si es null', () {
      expect(hora(null), '');
    });
  });

  group('capacidadKg', () {
    test('formatea un num sin decimales', () {
      expect(capacidadKg(5000.0), '5000');
    });

    test('parsea un string numérico', () {
      expect(capacidadKg('3200'), '3200');
    });

    test('cae al toString cuando no es parseable', () {
      expect(capacidadKg('n/a'), 'n/a');
    });

    test('devuelve — cuando es null', () {
      expect(capacidadKg(null), '—');
    });
  });

  group('estadoInfo', () {
    test('reconoce un estado conocido', () {
      final info = estadoInfo('disponible');
      expect(info['label'], 'Disponible');
    });

    test('cae a un valor por defecto para estados desconocidos', () {
      final info = estadoInfo('rara_vez_visto');
      expect(info['label'], 'rara_vez_visto');
    });

    test('usa — como label cuando el estado es null', () {
      final info = estadoInfo(null);
      expect(info['label'], '—');
    });
  });

  group('EstadoBadge', () {
    testWidgets('renderiza el label del estado', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EstadoBadge(estado: 'activo'))),
      );
      expect(find.text('Activo'), findsOneWidget);
    });
  });

  group('slotsDisponibles', () {
    test('Centro Histórico solo tiene el turno nocturno', () {
      final ruta = Ruta.fromJson({'id': 1, 'zona_nombre': 'Centro Histórico'});
      final slots = slotsDisponibles(ruta);
      expect(slots, hasLength(1));
      expect(slots.first['inicio'], '20:00');
    });

    test('otras zonas usan los turnos diurnos', () {
      final ruta = Ruta.fromJson({'id': 1, 'zona_nombre': 'Wanchaq'});
      final slots = slotsDisponibles(ruta);
      expect(slots.length, greaterThan(1));
    });
  });
}
