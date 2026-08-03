import 'package:flutter/material.dart';
import 'views/landing_screen.dart';

void main() {
  runApp(const SmartAPkApp());
}

class SmartAPkApp extends StatelessWidget {
  const SmartAPkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartAPk',
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

