import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/providers/settings_provider.dart';
import 'package:llom/screens/profile_screen.dart';
import 'package:llom/widgets/release_notes_dialog.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('showReleaseNotesModal displays header and close button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showReleaseNotesModal(context),
              child: const Text('Obrir Notes'),
            ),
          ),
        ),
      ),
    );

    // Open bottom sheet
    await tester.tap(find.text('Obrir Notes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify header title and close button
    expect(find.text('Novetats de la versió'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    // Close bottom sheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Bottom sheet is dismissed
    expect(find.text('Novetats de la versió'), findsNothing);
  });

  testWidgets('ProfileScreen version tile opens release notes modal on tap',
      (WidgetTester tester) async {
    final settingsProvider = SettingsProvider();
    final libraryProvider = LibraryProvider();

    final testUser = UserModel(
      uid: 'u-123',
      email: 'test@example.com',
      displayName: 'Eloi Aymerich',
      activeLibraryId: 'lib-1',
      createdAt: DateTime.now(),
    );

    await libraryProvider.initialize(testUser);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<LibraryProvider>.value(value: libraryProvider),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify version row is present
    final versionTile = find.text('Versió de l\'aplicació');
    expect(versionTile, findsOneWidget);

    // Scroll into view and tap on version tile
    await tester.ensureVisible(versionTile);
    await tester.pumpAndSettle();
    await tester.tap(versionTile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    // Verify release notes bottom sheet appears
    expect(find.text('Novetats de la versió'), findsOneWidget);
  });
}
