import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/widgets/library_dialogs.dart';

class MockLibraryProviderForSafeguard extends LibraryProvider {
  bool deleteCalled = false;
  bool leaveCalled = false;
  String? lastLibraryId;

  @override
  Future<bool> deleteLibrary(String libraryId) async {
    deleteCalled = true;
    lastLibraryId = libraryId;
    return true;
  }

  @override
  Future<bool> leaveLibrary(String libraryId) async {
    leaveCalled = true;
    lastLibraryId = libraryId;
    return true;
  }
}

void main() {
  group('Library safeguards dialog tests', () {
    final testLibrary = LibraryModel(
      id: 'lib_test',
      name: 'Biblioteca Cal Jeroni',
      ownerId: 'user_1',
      inviteCode: 'TEST01',
      members: {'user_1': 'owner'},
      memberUids: ['user_1'],
      createdAt: DateTime.now(),
    );

    Widget createTestApp(LibraryProvider provider, Widget child) {
      return ChangeNotifierProvider<LibraryProvider>.value(
        value: provider,
        child: MaterialApp(
          home: Scaffold(
            body: child,
          ),
        ),
      );
    }

    testWidgets('showDeleteLibraryDialog keeps delete button disabled until exact library name is typed', (tester) async {
      final provider = MockLibraryProviderForSafeguard();

      await tester.pumpWidget(createTestApp(
        provider,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showDeleteLibraryDialog(context, testLibrary),
            child: const Text('Obrir'),
          ),
        ),
      ));

      // Obrir el diàleg
      await tester.tap(find.text('Obrir'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar biblioteca'), findsOneWidget);
      expect(find.text('Aquesta acció no es pot desfer. S\'eliminaran definitivament la biblioteca, totes les estanteries i tots els llibres catalogats.'), findsOneWidget);

      final deleteButtonFinder = find.widgetWithText(ElevatedButton, 'Eliminar definitivament');
      expect(deleteButtonFinder, findsOneWidget);

      // El botó d'eliminar ha d'estar inicialment deshabilitat amb fons gris
      ElevatedButton deleteButton = tester.widget(deleteButtonFinder);
      expect(deleteButton.onPressed, isNull);
      expect(deleteButton.style?.backgroundColor?.resolve({WidgetState.disabled}), Colors.grey.shade200);

      // Escrivim un nom incorrecte
      final textFieldFinder = find.byType(TextField);
      await tester.enterText(textFieldFinder, 'Altra biblioteca');
      await tester.pumpAndSettle();

      deleteButton = tester.widget(deleteButtonFinder);
      expect(deleteButton.onPressed, isNull);

      // Escrivim exactament el nom de la biblioteca
      await tester.enterText(textFieldFinder, 'Biblioteca Cal Jeroni');
      await tester.pumpAndSettle();

      deleteButton = tester.widget(deleteButtonFinder);
      expect(deleteButton.onPressed, isNotNull);
      expect(deleteButton.style?.backgroundColor?.resolve({}), Colors.red.shade600);

      // Premem el botó desbloquejat
      await tester.tap(deleteButtonFinder);
      await tester.pumpAndSettle();

      expect(provider.deleteCalled, isTrue);
      expect(provider.lastLibraryId, 'lib_test');
    });

    testWidgets('showLeaveLibraryDialog confirms and calls leaveLibrary', (tester) async {
      final provider = MockLibraryProviderForSafeguard();

      await tester.pumpWidget(createTestApp(
        provider,
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => showLeaveLibraryDialog(context, testLibrary),
            child: const Text('Obrir Sortir'),
          ),
        ),
      ));

      await tester.tap(find.text('Obrir Sortir'));
      await tester.pumpAndSettle();

      expect(find.text('Sortir de la biblioteca'), findsOneWidget);
      expect(find.text('Vols sortir de "${testLibrary.name}"?'), findsOneWidget);

      final confirmSortirFinder = find.widgetWithText(ElevatedButton, 'Sortir');
      await tester.tap(confirmSortirFinder);
      await tester.pumpAndSettle();

      expect(provider.leaveCalled, isTrue);
      expect(provider.lastLibraryId, 'lib_test');
    });
  });
}
