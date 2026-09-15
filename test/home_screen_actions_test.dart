import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/screens/home_screen.dart';
import 'package:llom/services/bookcase_service.dart';
import 'package:llom/services/update_service.dart';

class MockBookcaseServiceForHomeActions extends BookcaseService {
  final List<BookcaseModel> bookcases;
  String? updatedBookcaseId;
  String? updatedBookcaseName;
  String? deletedBookcaseId;

  MockBookcaseServiceForHomeActions({required this.bookcases});

  @override
  Stream<List<BookcaseModel>> getBookcases(String libraryId) {
    return Stream.value(bookcases);
  }

  @override
  Future<void> updateBookcaseName(String libraryId, String bookcaseId, String newName) async {
    updatedBookcaseId = bookcaseId;
    updatedBookcaseName = newName;
  }

  @override
  Future<void> deleteBookcase(String libraryId, String bookcaseId) async {
    deletedBookcaseId = bookcaseId;
  }
}

class MockUpdateServiceForHomeActions extends UpdateService {
  @override
  Future<UpdateInfo?> checkUpdate({String? currentVersionOverride}) async {
    return null;
  }
}

void main() {
  final now = DateTime(2026, 9, 15);
  final testBookcase = BookcaseModel(
    id: 'bc_action_1',
    name: 'Estanteria Saló',
    room: 'Menjador',
    shelfCount: 4,
    bookCount: 20,
    order: 1,
    createdAt: now,
  );

  final testUser = UserModel(
    uid: 'u_owner',
    email: 'owner@llom.cat',
    displayName: 'Propietari Llom',
    createdAt: now,
  );

  final testLib = LibraryModel(
    id: 'lib_action_test',
    name: 'Biblioteca Piset',
    ownerId: 'u_owner',
    inviteCode: 'PISET1',
    members: {'u_owner': 'owner'},
    memberUids: ['u_owner'],
    createdAt: now,
  );

  Widget createWidget({required BookcaseService service}) {
    final provider = LibraryProvider();
    provider.currentUser = testUser;
    provider.activeLibrary = testLib;

    return ChangeNotifierProvider<LibraryProvider>.value(
      value: provider,
      child: MaterialApp(
        home: HomeScreen(
          bookcaseService: service,
          updateService: MockUpdateServiceForHomeActions(),
        ),
      ),
    );
  }

  group('HomeScreen Actions and Bookcase Options', () {
    testWidgets('FAB shows Afegir estanteria and opens showAddBookcaseDialog', (tester) async {
      final mockService = MockBookcaseServiceForHomeActions(bookcases: [testBookcase]);

      await tester.pumpWidget(createWidget(service: mockService));
      await tester.pumpAndSettle();

      final fab = find.byKey(const Key('add_bookcase_fab'));
      expect(fab, findsOneWidget);
      expect(find.text('Afegir estanteria'), findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Nova estanteria'), findsOneWidget);
      expect(find.text('Nom del moble'), findsOneWidget);
    });

    testWidgets('BookcaseCard options menu shows Editar nom and Eliminar estanteria', (tester) async {
      final mockService = MockBookcaseServiceForHomeActions(bookcases: [testBookcase]);

      await tester.pumpWidget(createWidget(service: mockService));
      await tester.pumpAndSettle();

      final optionsBtn = find.byKey(Key('bookcase_options_${testBookcase.id}'));
      expect(optionsBtn, findsOneWidget);

      await tester.tap(optionsBtn);
      await tester.pumpAndSettle();

      expect(find.text('Editar nom'), findsOneWidget);
      expect(find.text('Eliminar estanteria'), findsOneWidget);

      // Tap 'Editar nom'
      await tester.tap(find.text('Editar nom'));
      await tester.pumpAndSettle();

      expect(find.text('Escriu el nou nom per a aquesta estanteria:'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel·lar'));
      await tester.pumpAndSettle();

      // Open options again and tap 'Eliminar estanteria'
      await tester.tap(optionsBtn);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar estanteria'));
      await tester.pumpAndSettle();

      expect(find.text('Eliminar estanteria'), findsOneWidget);
      expect(
        find.text(
          'Segur que vols eliminar definitivament "Estanteria Saló"? Tots els llibres catalogats en aquesta estanteria també s\'esborraran.',
        ),
        findsOneWidget,
      );

      // Confirm deletion
      await tester.tap(find.byKey(const Key('confirm_delete_bookcase_button')));
      await tester.pumpAndSettle();

      expect(mockService.deletedBookcaseId, 'bc_action_1');
    });
  });
}
