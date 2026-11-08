import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.authService});
  final AuthService authService;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _registrando = false;
  bool _ocupado = false;
  bool _ocultarContrasena = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _ocupado = true;
      _error = null;
    });
    try {
      if (_registrando) {
        await widget.authService.registrar(_email.text, _password.text);
      } else {
        await widget.authService.iniciarSesion(_email.text, _password.text);
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = _mensajeError(error.code));
    } catch (_) {
      setState(
        () => _error = _registrando
            ? 'No se pudo crear el perfil. Revisa la conexión e inténtalo de nuevo.'
            : 'No se pudo iniciar sesión. Revisa tu conexión e inténtalo de nuevo.',
      );
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  String _mensajeError(String code) => switch (code) {
    'invalid-email' => 'Escribe un correo válido.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Correo o contraseña incorrectos.',
    'email-already-in-use' => 'Ya existe una cuenta con ese correo.',
    'weak-password' => 'La contraseña debe tener al menos 6 caracteres.',
    'too-many-requests' =>
      'Hubo muchos intentos. Espera un momento e inténtalo de nuevo.',
    'network-request-failed' =>
      'No hay conexión. Revisa Internet e inténtalo de nuevo.',
    _ => 'No se pudo completar la operación. Inténtalo de nuevo.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _registrando ? 'Crear cuenta' : 'Solicitudes de insumos',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Escribe un correo válido.'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: _ocultarContrasena,
                    autofillHints: _registrando
                        ? const [AutofillHints.newPassword]
                        : const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _ocultarContrasena = !_ocultarContrasena,
                        ),
                        icon: Icon(
                          _ocultarContrasena
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.length < 6
                        ? 'Usa al menos 6 caracteres.'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _ocupado ? null : _enviar,
                    child: _ocupado
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_registrando ? 'Registrarme' : 'Iniciar sesión'),
                  ),
                  TextButton(
                    onPressed: _ocupado
                        ? null
                        : () => setState(() {
                            _registrando = !_registrando;
                            _error = null;
                          }),
                    child: Text(
                      _registrando
                          ? 'Ya tengo una cuenta'
                          : 'Crear cuenta de empleado',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
