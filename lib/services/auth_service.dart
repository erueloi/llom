import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:llom/models/user_model.dart';

/// Excepció personalitzada per a errors d'autenticació amb missatges entenedors en català
class AuthException implements Exception {
  final String message;
  final String? code;

  const AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Servei per gestionar l'autenticació i el perfil d'usuari a Firebase
class AuthService {
  final FirebaseAuth? _authInstance;
  final FirebaseFirestore? _firestoreInstance;
  final GoogleSignIn? _googleSignInInstance;

  AuthService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _authInstance = auth,
        _firestoreInstance = firestore,
        _googleSignInInstance = googleSignIn;

  FirebaseAuth get _auth => _authInstance ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;
  GoogleSignIn get _googleSignIn => _googleSignInInstance ?? GoogleSignIn();

  /// Stream per escoltar canvis d'estat a la sessió de l'usuari
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Usuari de Firebase Auth actualment autenticat (o null si no hi ha sessió)
  User? get currentUser => _auth.currentUser;

  /// Registra un nou usuari amb correu i contrasenya, i crea el seu document a Firestore
  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException("No s'ha pogut crear l'usuari.");
      }

      final trimmedName = name.trim();
      if (trimmedName.isNotEmpty) {
        await user.updateDisplayName(trimmedName);
      }

      final now = DateTime.now();
      final userModel = UserModel(
        uid: user.uid,
        email: email.trim(),
        displayName: trimmedName.isNotEmpty ? trimmedName : null,
        activeLibraryId: null,
        createdAt: now,
      );

      // Desa el document a la col·lecció 'users/{uid}'
      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        "S'ha produït un error inesperat durant el registre: ${e.toString()}",
      );
    }
  }

  /// Inicia sessió amb correu i contrasenya i recupera el document de 'users/{uid}'
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException("No s'ha pogut iniciar sessió.");
      }

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, user.uid);
      }

      // Si no existís el document a Firestore, creem un registre base
      final fallbackUser = UserModel(
        uid: user.uid,
        email: user.email ?? email.trim(),
        displayName: user.displayName,
        photoUrl: user.photoURL,
        activeLibraryId: null,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(fallbackUser.toMap());
      return fallbackUser;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        "S'ha produït un error inesperat en iniciar sessió: ${e.toString()}",
      );
    }
  }

  /// Inicia sessió o registra l'usuari mitjançant Google Sign-In
  Future<UserModel> signInWithGoogle() async {
    try {
      UserCredential userCredential;

      if (kIsWeb) {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        userCredential = await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw const AuthException(
            'Inici de sessió amb Google cancel·lat.',
            code: 'cancelled',
          );
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        userCredential = await _auth.signInWithCredential(credential);
      }

      final user = userCredential.user;
      if (user == null) {
        throw const AuthException(
          "No s'ha pogut obtenir la informació de l'usuari de Google.",
        );
      }

      // Comprovem si el document users/{uid} ja existeix a Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        // Usuari recurrent: respectem el seu activeLibraryId existent
        final existing = UserModel.fromMap(userDoc.data()!, user.uid);
        if (user.photoURL != null && existing.photoUrl != user.photoURL) {
          final updated = existing.copyWith(photoUrl: user.photoURL);
          await _firestore.collection('users').doc(user.uid).set(
            {'photoUrl': user.photoURL},
            SetOptions(merge: true),
          );
          return updated;
        }
        return existing;
      } else {
        // Nou registre amb Google
        final now = DateTime.now();
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          photoUrl: user.photoURL,
          activeLibraryId: null,
          createdAt: now,
        );

        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
        return newUser;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' || e.code == 'canceled') {
        throw const AuthException(
          'Inici de sessió amb Google cancel·lat.',
          code: 'cancelled',
        );
      }
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException(
        "S'ha produït un error en iniciar sessió amb Google: ${e.toString()}",
      );
    }
  }

  /// Tanca la sessió actual de l'usuari
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthException(
        "S'ha produït un error en tancar sessió: ${e.toString()}",
      );
    }
  }

  /// Recupera les dades completes de l'usuari actual des de Firestore
  Future<UserModel?> getCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, user.uid);
      }

      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        activeLibraryId: null,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      // Si la consulta a Firestore falla per xarxa o regles, retornem les dades bàsiques de sessió
      return UserModel(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName,
        photoUrl: user.photoURL,
        activeLibraryId: null,
        createdAt: DateTime.now(),
      );
    }
  }

  /// Mapeja els codis d'error de FirebaseAuth a missatges amigables en català
  static String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Aquest correu electrònic ja està registrat en un altre compte.';
      case 'invalid-email':
        return 'El format del correu electrònic no és vàlid.';
      case 'operation-not-allowed':
        return "Aquest mètode d'inici de sessió no està habilitat.";
      case 'weak-password':
        return 'La contrasenya és massa feble. Ha de tenir com a mínim 6 caràcters.';
      case 'user-disabled':
        return "Aquest compte d'usuari ha estat desactivat.";
      case 'user-not-found':
        return 'No hi ha cap usuari registrat amb aquest correu electrònic.';
      case 'wrong-password':
        return 'La contrasenya introduïda no és correcta.';
      case 'invalid-credential':
        return 'Les credencials introduïdes no són vàlides o han caducat.';
      case 'too-many-requests':
        return "S'han produït massa intents d'accés fallits. Torna-ho a provar d'aquí a uns minuts.";
      case 'network-request-failed':
        return 'Error de connexió a la xarxa. Comprova la connexió a internet.';
      default:
        return e.message ?? "S'ha produït un error en el procés d'autenticació.";
    }
  }
}
