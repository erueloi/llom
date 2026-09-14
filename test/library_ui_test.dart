import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/screens/home_screen.dart';
import 'package:llom/screens/no_library_screen.dart';
import 'package:llom/widgets/library_dialogs.dart';
import 'package:llom/widgets/shelf_row_widget.dart';

void main() {
  final now = DateTime.now();

  final mockOwner = UserModel(
    uid: 'owner_1',
    email: 'owner@llom.cat',
    createdAt: now,
  );

  final mockViewer = UserModel(
    uid: 'viewer_1',
    email: 'viewer@llom.cat',
    createdAt: now,
  );

  final mockLib = LibraryModel(
    id: 'lib_test',
    name: 'Biblioteca Prova',
    ownerId: 'owner_1',
    inviteCode: 'TEST88',
    members: {'owner_1': 'owner', 'viewer_1': 'viewer'},
    memberUids: ['owner_1', 'viewer_1'],
    createdAt: now,
  );

  group('NoLibraryScreen tests', () {
    testWidgets('Renders header and action buttons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NoLibraryScreen(),
        ),
      );

      expect(find.text('Encara no tens cap biblioteca'), findsOneWidget);
      expect(find.text('Crear una biblioteca nova'), findsOneWidget);
      expect(find.text('Unir-me amb codi d\'invitació'), findsOneWidget);
    });

    testWidgets('Tapping Crear opens create dialog', (tester) async {
      final provider = LibraryProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: NoLibraryScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Crear una biblioteca nova'));
      await tester.pumpAndSettle();

      expect(find.text('Crear biblioteca'), findsOneWidget);
      expect(find.text('Cancel·lar'), findsOneWidget);
      expect(find.text('Crear'), findsOneWidget);
    });

    testWidgets('Tapping Unir-me opens join dialog', (tester) async {
      final provider = LibraryProvider();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: NoLibraryScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Unir-me amb codi d\'invitació'));
      await tester.pumpAndSettle();

      expect(find.text('Unir-se amb codi'), findsOneWidget);
      expect(find.text('Cancel·lar'), findsOneWidget);
      expect(find.text('Unir-me'), findsOneWidget);
    });
  });

  group('Role adaptation tests (canEdit / isViewerOnly)', () {
    testWidgets('HomeScreen hides FAB when user is viewer only', (tester) async {
      final provider = LibraryProvider();
      provider.activeLibrary = mockLib;
      provider.currentUser = mockViewer; // Viewer -> canEdit = false

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // El Floating Action Button ha d'estar amagat
      expect(find.text('Afegir balda / Foto'), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('HomeScreen shows FAB when user is owner', (tester) async {
      final provider = LibraryProvider();
      provider.activeLibrary = mockLib;
      provider.currentUser = mockOwner; // Owner -> canEdit = true

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // El Floating Action Button ha de ser visible
      expect(find.text('Afegir balda / Foto'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('ShelfRowWidget hides camera icon when canEdit is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShelfRowWidget(
              title: 'Balda 1',
              subtitle: '0 llibres',
              books: const [],
              canEdit: false,
              onBookTap: (_) {},
              onCameraTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt_outlined), findsNothing);
    });

    testWidgets('ShelfRowWidget shows camera icon when canEdit is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShelfRowWidget(
              title: 'Balda 1',
              subtitle: '0 llibres',
              books: const [],
              canEdit: true,
              onBookTap: (_) {},
              onCameraTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.camera_alt_outlined), findsOneWidget);
    });
  });

  group('showShareLibraryDialog tests', () {
    testWidgets('Renders library name, code and copy button', (tester) async {
      final provider = LibraryProvider();
      provider.activeLibrary = mockLib;
      provider.currentUser = mockOwner;

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () => showShareLibraryDialog(context),
                  child: const Text('Obrir'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Obrir'));
      await tester.pumpAndSettle();

      expect(find.text('Compartir Biblioteca Prova'), findsOneWidget);
      expect(find.text('TEST88'), findsOneWidget);
      expect(find.text('Copiar codi'), findsOneWidget);
      expect(find.text('Membres (2):'), findsOneWidget);
    });
  });
}
