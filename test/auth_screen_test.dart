import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/screens/auth_screen.dart';
import 'package:llom/services/auth_service.dart';
import 'package:llom/widgets/google_logo_widget.dart';

class FakeAuthService extends AuthService {
  bool googleSignInCalled = false;
  Completer<UserModel>? googleCompleter;
  AuthException? googleErrorToThrow;

  @override
  Future<UserModel> signInWithGoogle() async {
    googleSignInCalled = true;
    if (googleErrorToThrow != null) {
      throw googleErrorToThrow!;
    }
    if (googleCompleter != null) {
      return await googleCompleter!.future;
    }
    return UserModel(
      uid: 'google-user-123',
      email: 'test@google.com',
      displayName: 'Google Test User',
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  Widget createAuthScreen({AuthService? authService}) {
    return MaterialApp(
      home: AuthScreen(authService: authService),
    );
  }

  group('AuthScreen widget tests', () {
    testWidgets('Renders header, toggle tabs and login fields initially', (tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Capçalera
      expect(find.text('Benvingut a Llom'), findsOneWidget);
      expect(find.text('El catàleg visual dels teus llibres a casa'), findsOneWidget);

      // Tabs
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Crear compte'), findsOneWidget);

      // Camps inicials (mode login)
      expect(find.text('Correu electrònic'), findsOneWidget);
      expect(find.text('Contrasenya'), findsOneWidget);
      expect(find.text('El teu nom'), findsNothing);

      // Botó d'acció de login
      expect(find.text('Entrar a la meva biblioteca'), findsOneWidget);

      // Separador i botó de Google
      expect(find.text('o bé'), findsOneWidget);
      expect(find.text('Continua amb Google'), findsOneWidget);
      expect(find.byType(GoogleLogoWidget), findsOneWidget);
    });

    testWidgets('Switches to register mode when tapping Crear compte', (tester) async {
      await tester.pumpWidget(createAuthScreen());

      await tester.tap(find.text('Crear compte'));
      await tester.pumpAndSettle();

      // Camp nom ara és visible
      expect(find.text('El teu nom'), findsOneWidget);
      expect(find.text('Registrar-me'), findsOneWidget);
      expect(find.text('Entrar a la meva biblioteca'), findsNothing);

      // El botó de Google continua disponible a la part inferior
      expect(find.text('Continua amb Google'), findsOneWidget);

      // Tornem a mode Entrar
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();

      expect(find.text('El teu nom'), findsNothing);
      expect(find.text('Entrar a la meva biblioteca'), findsOneWidget);
    });

    testWidgets('Validates required fields in Catalan on submit', (tester) async {
      await tester.pumpWidget(createAuthScreen());

      // Premer el botó sense omplir res
      final buttonFinder = find.text('Entrar a la meva biblioteca');
      await tester.ensureVisible(buttonFinder);
      await tester.pumpAndSettle();
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle();

      expect(find.text('Si us plau, escriu el correu electrònic'), findsOneWidget);
      expect(find.text('Si us plau, escriu la contrasenya'), findsOneWidget);
    });

    testWidgets('Toggles password visibility with eye icon', (tester) async {
      await tester.pumpWidget(createAuthScreen());

      final visibilityFinder = find.byTooltip('Mostrar contrasenya');
      expect(visibilityFinder, findsOneWidget);

      await tester.tap(visibilityFinder);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Amagar contrasenya'), findsOneWidget);
    });

    testWidgets('Tapping Google sign-in calls signInWithGoogle and handles progress', (tester) async {
      final fakeAuth = FakeAuthService();
      final completer = Completer<UserModel>();
      fakeAuth.googleCompleter = completer;

      await tester.pumpWidget(createAuthScreen(authService: fakeAuth));

      final googleButtonFinder = find.text('Continua amb Google');
      await tester.ensureVisible(googleButtonFinder);
      await tester.pumpAndSettle();

      await tester.tap(googleButtonFinder);
      await tester.pump(); // Start async work

      expect(fakeAuth.googleSignInCalled, isTrue);
      // Progress indicator should be visible while loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete async operation
      completer.complete(UserModel(
        uid: 'user-google-1',
        email: 'user@google.com',
        createdAt: DateTime.now(),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Continua amb Google'), findsOneWidget);
    });

    testWidgets('Google sign-in cancellation does not show error banner', (tester) async {
      final fakeAuth = FakeAuthService();
      fakeAuth.googleErrorToThrow = const AuthException(
        'Inici de sessió amb Google cancel·lat.',
        code: 'cancelled',
      );

      await tester.pumpWidget(createAuthScreen(authService: fakeAuth));

      final googleButtonFinder = find.text('Continua amb Google');
      await tester.ensureVisible(googleButtonFinder);
      await tester.pumpAndSettle();

      await tester.tap(googleButtonFinder);
      await tester.pumpAndSettle();

      expect(fakeAuth.googleSignInCalled, isTrue);
      // Cancellation should NOT display the red error banner
      expect(find.text('Inici de sessió amb Google cancel·lat.'), findsNothing);
      expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
    });

    testWidgets('Google sign-in unexpected error shows Catalan error banner', (tester) async {
      final fakeAuth = FakeAuthService();
      fakeAuth.googleErrorToThrow = const AuthException(
        "S'ha produït un error de connexió.",
        code: 'network-request-failed',
      );

      await tester.pumpWidget(createAuthScreen(authService: fakeAuth));

      final googleButtonFinder = find.text('Continua amb Google');
      await tester.ensureVisible(googleButtonFinder);
      await tester.pumpAndSettle();

      await tester.tap(googleButtonFinder);
      await tester.pumpAndSettle();

      expect(fakeAuth.googleSignInCalled, isTrue);
      expect(find.text("S'ha produït un error de connexió."), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });
}
