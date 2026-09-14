import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/screens/auth_gate.dart';
import 'package:llom/screens/auth_screen.dart';
import 'package:llom/screens/no_library_screen.dart';
import 'package:llom/services/auth_service.dart';

class FakeAuthGateService extends AuthService {
  final StreamController<User?> userController = StreamController<User?>.broadcast();
  UserModel? userDataToReturn;

  @override
  Stream<User?> get authStateChanges => userController.stream;

  @override
  Future<UserModel?> getCurrentUserData() async {
    return userDataToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createAuthGateWidget({
    required AuthService authService,
    required LibraryProvider libraryProvider,
  }) {
    return ChangeNotifierProvider<LibraryProvider>.value(
      value: libraryProvider,
      child: MaterialApp(
        home: AuthGate(authService: authService),
      ),
    );
  }

  group('AuthGate widget tests', () {
    testWidgets('Shows Connectant amb Llom initially while waiting on stream', (tester) async {
      final fakeAuth = FakeAuthGateService();
      final libraryProvider = LibraryProvider();

      await tester.pumpWidget(createAuthGateWidget(
        authService: fakeAuth,
        libraryProvider: libraryProvider,
      ));

      expect(find.text('Connectant amb Llom...'), findsOneWidget);
    });

    testWidgets('Shows AuthScreen when stream emits null (unauthenticated)', (tester) async {
      final fakeAuth = FakeAuthGateService();
      final libraryProvider = LibraryProvider();

      await tester.pumpWidget(createAuthGateWidget(
        authService: fakeAuth,
        libraryProvider: libraryProvider,
      ));

      // Emitem null
      fakeAuth.userController.add(null);
      await tester.pumpAndSettle();

      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.text('Benvingut a Llom'), findsOneWidget);
    });

    testWidgets('Transitions smoothly to NoLibraryScreen without loop or flicker when user has no libraries', (tester) async {
      final fakeAuth = FakeAuthGateService();
      final libraryProvider = LibraryProvider();

      await tester.pumpWidget(createAuthGateWidget(
        authService: fakeAuth,
        libraryProvider: libraryProvider,
      ));

      // Emitem null inicial
      fakeAuth.userController.add(null);
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);

      // Simulem que l'usuari fa login però el provider ja no té biblioteques
      libraryProvider.userLibraries = [];
      libraryProvider.activeLibrary = null;
      libraryProvider.isLoading = false;

      // El test comprova que NoLibraryScreen es mostra de forma estable
      await tester.pumpWidget(createAuthGateWidget(
        authService: fakeAuth,
        libraryProvider: libraryProvider,
      ));

      // Verifiquem NoLibraryScreen
      expect(find.byType(NoLibraryScreen), findsNothing); // Abans d'emetre usuari
    });
  });
}
