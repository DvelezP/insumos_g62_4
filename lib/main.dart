import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'repositories/insumo_repository.dart';
import 'repositories/solicitud_repository.dart';
import 'screens/home_screen.dart';
import 'services/insumo_http_service.dart';

void main() {
  final repository = InsumoRepository(
    service: InsumoHttpService(url: Uri.parse(kInsumosUrl)),
  );
  runApp(
    InsumosApp(
      repository: repository,
      solicitudRepository: SolicitudRepository(),
    ),
  );
}

class InsumosApp extends StatelessWidget {
  const InsumosApp({
    super.key,
    required this.repository,
    required this.solicitudRepository,
  });

  final InsumoRepository repository;
  final SolicitudRepository solicitudRepository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solicitudes de insumos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: HomeScreen(
        repository: repository,
        solicitudRepository: solicitudRepository,
      ),
    );
  }
}
