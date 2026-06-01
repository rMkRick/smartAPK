import 'package:flutter/material.dart';
import 'screens/landing_screen.dart';

void main() {
  runApp(const SmartWasteApp());
}

class SmartWasteApp extends StatelessWidget {
  const SmartWasteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartWaste Cusco',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF97316),
          primary: const Color(0xFFF97316),
          secondary: const Color(0xFF0F172A),
        ),
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      home: const LandingScreen(),
    );
  }
}
