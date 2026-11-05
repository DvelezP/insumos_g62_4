import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'firebase_options.dart';
import 'remote/solicitud_remote_data_source.dart';
import 'repositories/insumo_repository.dart';
import 'repositories/solicitud_repository.dart';
import 'screens/home_screen.dart';
import 'services/insumo_http_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Si Firebase no inicia, la app sigue funcionando con los datos locales.
  SolicitudRemoteDataSource? solicitudRemote;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    solicitudRemote = SolicitudRemoteDataSource(
      firestore: FirebaseFirestore.instance,
    );
  } catch (error) {
    debugPrint('No se pudo inicializar Firebase: $error');
  }

  final repository = InsumoRepository(
    service: InsumoHttpService(url: Uri.parse(kInsumosUrl)),
  );
  runApp(
    InsumosApp(
      repository: repository,
      solicitudRepository: SolicitudRepository(remote: solicitudRemote),
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
