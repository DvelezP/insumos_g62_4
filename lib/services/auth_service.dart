import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/perfil_usuario.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> get cambiosSesion => _auth.authStateChanges();
  User? get usuarioActual => _auth.currentUser;

  Future<void> iniciarSesion(String correo, String contrasena) async {
    await _auth.signInWithEmailAndPassword(
      email: correo.trim(),
      password: contrasena,
    );
  }

  Future<void> registrar(String correo, String contrasena) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: correo.trim(),
      password: contrasena,
    );
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase no devolvió el usuario creado.');
    }
    await _firestore.collection('usuarios').doc(user.uid).set({
      'uid': user.uid,
      'correo': user.email ?? correo.trim(),
      'rol': RolUsuario.empleado.name,
      'area': 'General',
      'creadoEn': FieldValue.serverTimestamp(),
    });
  }

  Future<PerfilUsuario> cargarPerfil(String uid) async {
    final snapshot = await _firestore.collection('usuarios').doc(uid).get();
    if (!snapshot.exists || snapshot.data() == null) {
      throw StateError(
        'Tu perfil no está configurado. Contacta al equipo del proyecto.',
      );
    }
    return PerfilUsuario.fromJson(uid, snapshot.data()!);
  }

  Stream<PerfilUsuario?> observarPerfil(String uid) =>
      _firestore.collection('usuarios').doc(uid).snapshots().map((snapshot) {
        if (!snapshot.exists || snapshot.data() == null) return null;
        return PerfilUsuario.fromJson(uid, snapshot.data()!);
      });

  Future<void> cerrarSesion() => _auth.signOut();
}
