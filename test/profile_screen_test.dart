import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/providers/settings_provider.dart';
import 'package:llom/screens/home_screen.dart';
import 'package:llom/screens/profile_screen.dart';
import 'package:llom/services/auth_service.dart';
import 'package:llom/services/bookcase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAuthServiceForProfile extends AuthService {
  bool signOutCalled = false;

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

class MockLibraryProviderForProfile extends LibraryProvider {
  bool clearCalled = false;

  MockLibraryProviderForProfile({
    UserModel? user,
    LibraryModel? activeLib,
  }) {
    currentUser = user;
    activeLibrary = activeLib;
    if (activeLib != null) {
      userLibraries = [activeLib];
    }
  }

  @override
  void clear() {
    clearCalled = true;
    super.clear();
  }
}

void main() {
  final testUser = UserModel(
    uid: 'user_456',
    email: 'jeroni@llom.cat',
    displayName: 'Jeroni Calders',
    createdAt: DateTime(2025, 1, 1),
  );

  final testLibrary = LibraryModel(
    id: 'lib_test',
    name: 'Biblioteca Cal Jeroni',
    ownerId: 'user_456',
    inviteCode: 'CAL789',
    members: {'user_456': 'owner'},
    memberUids: ['user_456'],
    createdAt: DateTime(2025, 1, 1),
  );

  Widget createProfileTestApp({
    required LibraryProvider libraryProvider,
    required SettingsProvider settingsProvider,
    AuthService? authService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        home: ProfileScreen(authService: authService),
      ),
    );
  }

  group('ProfileScreen tests', () {
    testWidgets('Renders user info, initial avatar, role badge and app version', (tester) async {
      final libraryProvider = MockLibraryProviderForProfile(
        user: testUser,
        activeLib: testLibrary,
      );
      final settingsProvider = SettingsProvider();

      await tester.pumpWidget(createProfileTestApp(
        libraryProvider: libraryProvider,
        settingsProvider: settingsProvider,
      ));
      await tester.pumpAndSettle();

      // Capçalera
      expect(find.text('El teu perfil'), findsOneWidget);
      expect(find.text('Jeroni Calders'), findsOneWidget);
      expect(find.text('jeroni@llom.cat'), findsOneWidget);
      expect(find.text('J'), findsOneWidget); // Inicial a l'avatar
      expect(find.text('👑 Propietari/a a Biblioteca Cal Jeroni'), findsOneWidget);

      // Accessibilitat i Versió
      expect(find.text('Accessibilitat i Preferències'), findsOneWidget);
      expect(find.text('Mode text extra gran'), findsOneWidget);
      expect(find.text("Versió de l'aplicació"), findsOneWidget);
      expect(find.text('1.0.0 (v1)'), findsOneWidget);

      // Accions de compte
      expect(find.text('Gestió de Compte'), findsOneWidget);
      expect(find.text('Canviar de biblioteca activa'), findsOneWidget);
      expect(find.text('Tancar sessió'), findsOneWidget);
    });

    testWidgets('Toggles extra large text switch in SettingsProvider', (tester) async {
      final libraryProvider = MockLibraryProviderForProfile(
        user: testUser,
        activeLib: testLibrary,
      );
      final settingsProvider = SettingsProvider();

      await tester.pumpWidget(createProfileTestApp(
        libraryProvider: libraryProvider,
        settingsProvider: settingsProvider,
      ));
      await tester.pumpAndSettle();

      expect(settingsProvider.isExtraLargeText, isFalse);

      // Premer el SwitchListTile
      await tester.tap(find.text('Mode text extra gran'));
      await tester.pumpAndSettle();

      expect(settingsProvider.isExtraLargeText, isTrue);
      expect(settingsProvider.textScaleFactor, 1.25);

      // Desactivar de nou
      await tester.tap(find.text('Mode text extra gran'));
      await tester.pumpAndSettle();

      expect(settingsProvider.isExtraLargeText, isFalse);
      expect(settingsProvider.textScaleFactor, 1.0);
    });

    testWidgets('Sign out dialog allows cancel without signing out', (tester) async {
      final mockAuth = MockAuthServiceForProfile();
      final libraryProvider = MockLibraryProviderForProfile(
        user: testUser,
        activeLib: testLibrary,
      );
      final settingsProvider = SettingsProvider();

      await tester.pumpWidget(createProfileTestApp(
        libraryProvider: libraryProvider,
        settingsProvider: settingsProvider,
        authService: mockAuth,
      ));
      await tester.pumpAndSettle();

      // Desplaçar fins al botó de tancar sessió i prémer-lo
      final signOutBtn = find.byKey(const Key('profile_sign_out_button'));
      await tester.scrollUntilVisible(signOutBtn, 100);
      await tester.pumpAndSettle();
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      // Diàleg de confirmació obert
      expect(find.text('Segur que vols sortir del teu compte de Llom?'), findsOneWidget);

      // Prémer Cancel·lar
      await tester.tap(find.text('Cancel·lar'));
      await tester.pumpAndSettle();

      expect(mockAuth.signOutCalled, isFalse);
      expect(libraryProvider.clearCalled, isFalse);
    });

    testWidgets('Sign out dialog confirms, clears libraryProvider and signs out', (tester) async {
      final mockAuth = MockAuthServiceForProfile();
      final libraryProvider = MockLibraryProviderForProfile(
        user: testUser,
        activeLib: testLibrary,
      );
      final settingsProvider = SettingsProvider();

      await tester.pumpWidget(createProfileTestApp(
        libraryProvider: libraryProvider,
        settingsProvider: settingsProvider,
        authService: mockAuth,
      ));
      await tester.pumpAndSettle();

      // Desplaçar fins al botó de tancar sessió i prémer-lo
      final signOutBtn = find.byKey(const Key('profile_sign_out_button'));
      await tester.scrollUntilVisible(signOutBtn, 100);
      await tester.pumpAndSettle();
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      // Prémer Tancar sessió al diàleg
      final confirmBtn = find.byKey(const Key('confirm_sign_out_button'));
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(mockAuth.signOutCalled, isTrue);
      expect(libraryProvider.clearCalled, isTrue);
    });

    testWidgets('HomeScreen has profile avatar button and navigates to ProfileScreen', (tester) async {
      final libraryProvider = MockLibraryProviderForProfile(
        user: testUser,
        activeLib: testLibrary,
      );
      final settingsProvider = SettingsProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Inicial 'J' visible a l'avatar de la capçalera amb estil de 22sp bold
      expect(find.byTooltip('El teu perfil'), findsOneWidget);
      final headerInitialText = tester.widget<Text>(find.text('J'));
      expect(headerInitialText.style?.fontSize, 22);
      expect(headerInitialText.style?.fontWeight, FontWeight.bold);

      // Prémer l'avatar per anar a ProfileScreen
      await tester.tap(find.byTooltip('El teu perfil'));
      await tester.pumpAndSettle();

      expect(find.text('El teu perfil'), findsOneWidget);
      expect(find.text('Jeroni Calders'), findsOneWidget);

      // Inicial a ProfileScreen amb estil de 36sp bold
      final profileInitialText = tester.widget<Text>(find.text('J'));
      expect(profileInitialText.style?.fontSize, 36);
      expect(profileInitialText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('HomeScreen dynamic book badge updates and hides when 0 books', (tester) async {
      final libraryProvider = MockLibraryProviderForProfile(
        user: testUser,
        activeLib: testLibrary,
      );
      final settingsProvider = SettingsProvider();
      final mockBookcaseService = MockBookcaseServiceForBadge();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ],
          child: MaterialApp(
            home: HomeScreen(bookcaseService: mockBookcaseService),
          ),
        ),
      );
      await tester.pump();

      // Emitim 0 llibres -> El badge ha d'estar amagat
      mockBookcaseService.emit([]);
      await tester.pump();
      expect(find.byKey(const Key('book_count_badge')), findsNothing);

      // Emitim estanteries amb un total de 42 llibres -> Badge visible
      mockBookcaseService.emit([
        BookcaseModel(
          id: 'b1',
          name: 'Estudi',
          room: 'Estudi',
          shelfCount: 3,
          bookCount: 42,
          createdAt: DateTime(2025, 1, 1),
        ),
      ]);
      await tester.pump();
      expect(find.byKey(const Key('book_count_badge')), findsOneWidget);
      expect(find.text('42 llibres'), findsOneWidget);

      mockBookcaseService.dispose();
    });

    testWidgets('ProfileScreen renders Gemini key tile and allows configuring key', (tester) async {
      SharedPreferences.setMockInitialValues({});

      final libraryProvider = MockLibraryProviderForProfile(
        user: testUser,
        activeLib: testLibrary,
      );
      final settingsProvider = SettingsProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),
            ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final geminiTile = find.byKey(const Key('profile_gemini_key_tile'));
      expect(geminiTile, findsOneWidget);
      expect(find.text('Clau de Gemini (IA)'), findsOneWidget);

      // Tap on the tile to open the bottom sheet
      await tester.ensureVisible(geminiTile);
      await tester.pumpAndSettle();
      await tester.tap(geminiTile);
      await tester.pumpAndSettle();

      // Verify the bottom sheet opened
      expect(find.byKey(const Key('gemini_api_key_input')), findsOneWidget);
      expect(find.byKey(const Key('gemini_api_key_save_btn')), findsOneWidget);

      // Enter key and save
      await tester.enterText(find.byKey(const Key('gemini_api_key_input')), 'AIzaSy_TEST_KEY_123');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('gemini_api_key_save_btn')));
      await tester.pumpAndSettle();

      // Bottom sheet closed and tile updated
      expect(find.text('Configurada al dispositiu'), findsOneWidget);
    });
  });
}

class MockBookcaseServiceForBadge extends BookcaseService {
  final _controller = StreamController<List<BookcaseModel>>.broadcast();

  @override
  Stream<List<BookcaseModel>> getBookcases(String libraryId) => _controller.stream;

  void emit(List<BookcaseModel> list) {
    _controller.add(list);
  }

  void dispose() {
    _controller.close();
  }
}
