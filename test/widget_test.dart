// Smoke test: verifica que la app arranca y muestra la pantalla de
// aterrizaje (login/registro), que es el punto de entrada real de SmartAPk.
import 'package:flutter_test/flutter_test.dart';

import 'package:smart_apk/main.dart';

void main() {
  testWidgets('SmartAPk arranca mostrando LandingScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartAPkApp());
    await tester.pump();

    expect(find.text('MUNI CUSCO'), findsOneWidget);
    expect(find.text('SmartAPk'), findsWidgets);
    expect(find.text('Acceso al Sistema'), findsOneWidget);
    expect(find.text('ENTRAR'), findsOneWidget);
  });
}
