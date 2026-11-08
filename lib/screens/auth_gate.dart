import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/perfil_usuario.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    required this.authService,
    required this.homeBuilder,
  });

  final AuthService authService;
  final Widget Function(PerfilUsuario perfil) homeBuilder;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.cambiosSesion,
      builder: (context, session) {
        if (session.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = session.data;
        if (user == null) return LoginScreen(authService: authService);
        return StreamBuilder<PerfilUsuario?>(
          stream: authService.observarPerfil(user.uid),
          builder: (context, profile) {
            if (profile.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (profile.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_off_outlined, size: 52),
                        const SizedBox(height: 12),
                        const Text(
                          'No se pudo cargar tu perfil. Revisa tu conexión o la configuración del rol.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: authService.cerrarSesion,
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            if (!profile.hasData || profile.data == null) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.pending_outlined, size: 44),
                        const SizedBox(height: 16),
                        const Text(
                          'Este usuario aún no tiene perfil o rol en Firestore. Un encargado debe configurar el documento usuarios/{uid}.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: authService.cerrarSesion,
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return homeBuilder(profile.data!);
          },
        );
      },
    );
  }
}
