import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const InsumosApp());
}

class InsumosApp extends StatelessWidget {
  const InsumosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solicitudes de insumos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
