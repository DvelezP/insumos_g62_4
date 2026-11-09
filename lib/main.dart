import 'dart:async';
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  runApp(const _AppStartup());
}

class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  late final InsumoRepository _repository = InsumoRepository(
    service: InsumoHttpService(url: Uri.parse(kInsumosUrl)),
  );
  SolicitudRepository? _solicitudRepository;
  AuthService? _authService;
  bool _firebaseUnavailable = false;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final remote = SolicitudRemoteDataSource(
        firestore: FirebaseFirestore.instance,
      );
      _solicitudRepository = SolicitudRepository(remote: remote);
      _authService = AuthService();

      // Crashlytics está disponible en Android/iOS, no en web.
      if (!kIsWeb) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        ui.PlatformDispatcher.instance.onError = (error, stack) {
          unawaited(
            FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
          );
          return true;
        };

        // Crashlytics no debe retrasar la primera pantalla de la aplicación.
        unawaited(
          FirebaseCrashlytics.instance
              .setCrashlyticsCollectionEnabled(true)
              .catchError((Object error) {
                debugPrint('No se pudo activar Crashlytics: $error');
              }),
        );
      }
    } catch (error) {
      debugPrint('No se pudo inicializar Firebase (${kIsWeb ? 'web' : 'Android'}): $error');
      _firebaseUnavailable = true;
    }

    if (mounted) setState(() => _initializing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return MaterialApp(
        title: 'Solicitudes de insumos',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
          useMaterial3: true,
        ),
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Iniciando la aplicación...'),
              ],
            ),
          ),
        ),
      );
    }

    return InsumosApp(
      repository: _repository,
      solicitudRepository: _solicitudRepository ?? SolicitudRepository(),
      authService: _authService,
      firebaseUnavailable: _firebaseUnavailable,
    );
  }
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
