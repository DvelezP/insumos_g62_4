import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'firebase_options.dart';
import 'remote/solicitud_remote_data_source.dart';
import 'repositories/insumo_repository.dart';
import 'repositories/solicitud_repository.dart';
import 'screens/home_screen.dart';
import 'screens/auth_gate.dart';
import 'services/insumo_http_service.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Si Firebase no inicia, la app sigue funcionando con los datos locales.
  SolicitudRemoteDataSource? solicitudRemote;
  AuthService? authService;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    solicitudRemote = SolicitudRemoteDataSource(
      firestore: FirebaseFirestore.instance,
    );
    authService = AuthService();
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
      );
      return true;
    };
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
      authService: authService,
      firebaseUnavailable: authService == null,
    ),
  );
}

class InsumosApp extends StatelessWidget {
  const InsumosApp({
    super.key,
    required this.repository,
    required this.solicitudRepository,
    this.authService,
    this.firebaseUnavailable = false,
  });

  final InsumoRepository repository;
  final SolicitudRepository solicitudRepository;
  final AuthService? authService;
  final bool firebaseUnavailable;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solicitudes de insumos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: firebaseUnavailable
          ? const _FirebaseUnavailableScreen()
          : authService == null
          ? HomeScreen(
              repository: repository,
              solicitudRepository: solicitudRepository,
            )
          : AuthGate(
              authService: authService!,
              homeBuilder: (perfil) => HomeScreen(
                repository: repository,
                solicitudRepository: solicitudRepository,
                perfil: perfil,
                authService: authService!,
              ),
            ),
    );
  }
}

class _FirebaseUnavailableScreen extends StatelessWidget {
  const _FirebaseUnavailableScreen();

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No se pudo conectar con Firebase. Revisa la configuración de Android e inténtalo de nuevo.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}
