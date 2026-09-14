import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/services/library_service.dart';

class LibraryProvider extends ChangeNotifier {
  static const String activeLibraryKey = 'active_library_id';

  final LibraryService _libraryService;
  final FirebaseFirestore? _firestoreInstance;
  final SharedPreferences? _prefsInstance;

  StreamSubscription<List<LibraryModel>>? _librariesSubscription;

  LibraryProvider({
    LibraryService? libraryService,
    FirebaseFirestore? firestore,
    SharedPreferences? prefs,
  })  : _libraryService = libraryService ?? LibraryService(firestore: firestore),
        _firestoreInstance = firestore,
        _prefsInstance = prefs;

  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;

  // Propietats d'estat
  UserModel? currentUser;
  LibraryModel? activeLibrary;
  List<LibraryModel> userLibraries = [];
  bool isLoading = false;
  String? errorMessage;

  // Getters útils d'accessibilitat i rols
  bool get hasActiveLibrary => activeLibrary != null;

  String get currentRole {
    final uid = currentUser?.uid;
    if (uid == null || activeLibrary == null) return 'viewer';
    return activeLibrary!.members[uid] ??
        (activeLibrary!.ownerId == uid ? 'owner' : 'viewer');
  }

  bool get isOwner => currentRole == 'owner';

  bool get canEdit => currentRole == 'owner' || currentRole == 'editor';

  /// Mode sènior / consulta estricta
  bool get isViewerOnly => currentRole == 'viewer';

  /// Inicialitza el proveïdor per a l'usuari donat
  Future<void> initialize(UserModel user) async {
    currentUser = user;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // Cancel·lem subscripció prèvia si existís
    await _librariesSubscription?.cancel();

    try {
      final prefs = _prefsInstance ?? await SharedPreferences.getInstance();
      String? savedLibraryId = prefs.getString(activeLibraryKey);
      if (savedLibraryId == null || savedLibraryId.isEmpty) {
        savedLibraryId = user.activeLibraryId;
      }

      // Escoltem el Stream de biblioteques de l'usuari en temps real
      final completer = Completer<void>();
      bool isFirstEmission = true;

      _librariesSubscription = _libraryService
          .getUserLibraries(user.uid)
          .listen((libraries) {
        userLibraries = libraries;

        // Si tenim un ID guardat i l'usuari encara hi té accés, el seleccionem
        if (savedLibraryId != null &&
            libraries.any((lib) => lib.id == savedLibraryId)) {
          activeLibrary = libraries.firstWhere((lib) => lib.id == savedLibraryId);
        } else if (libraries.isNotEmpty) {
          // Si no n'hi ha cap de guardada o ja no és vàlida, seleccionem la primera
          activeLibrary = libraries.first;
          prefs.setString(activeLibraryKey, activeLibrary!.id);
        } else {
          activeLibrary = null;
        }

        if (isFirstEmission) {
          isFirstEmission = false;
          isLoading = false;
          if (!completer.isCompleted) {
            completer.complete();
          }
        }

        notifyListeners();
      }, onError: (error) {
        errorMessage = error.toString();
        isLoading = false;
        if (!completer.isCompleted) {
          completer.complete();
        }
        notifyListeners();
      });

      // Esperem la primera emissió amb un timeout de seguretat
      await completer.future.timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          isLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
    }
  }

  /// Canvia la biblioteca activa seleccionada
  Future<void> switchLibrary(LibraryModel library) async {
    activeLibrary = library;
    notifyListeners();

    try {
      final prefs = _prefsInstance ?? await SharedPreferences.getInstance();
      await prefs.setString(activeLibraryKey, library.id);

      // Actualitzem en segon pla el camp activeLibraryId a users/$uid
      final uid = currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).set(
          {'activeLibraryId': library.id},
          SetOptions(merge: true),
        );
      }
    } catch (_) {
      // Els errors d'actualització en segon pla no bloquegen l'experiència d'usuari
    }

    notifyListeners();
  }

  /// Crea una biblioteca nova i la selecciona immediatament com a activa
  Future<bool> createAndSelectLibrary(String name) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      errorMessage = "No hi ha cap usuari autenticat per crear la biblioteca.";
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final newLibrary = await _libraryService.createLibrary(
        name: name,
        ownerUid: uid,
      );

      if (!userLibraries.any((lib) => lib.id == newLibrary.id)) {
        userLibraries.insert(0, newLibrary);
      }

      await switchLibrary(newLibrary);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// S'uneix a una biblioteca mitjançant el codi d'invitació i la selecciona
  Future<bool> joinAndSelectLibrary(String inviteCode) async {
    final uid = currentUser?.uid;
    if (uid == null) {
      errorMessage = "No hi ha cap usuari autenticat per unir-se a la biblioteca.";
      notifyListeners();
      return false;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final joinedLibrary = await _libraryService.joinLibraryByCode(
        inviteCode: inviteCode,
        uid: uid,
      );

      final index = userLibraries.indexWhere((lib) => lib.id == joinedLibrary.id);
      if (index >= 0) {
        userLibraries[index] = joinedLibrary;
      } else {
        userLibraries.insert(0, joinedLibrary);
      }

      await switchLibrary(joinedLibrary);

      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _librariesSubscription?.cancel();
    super.dispose();
  }
}
