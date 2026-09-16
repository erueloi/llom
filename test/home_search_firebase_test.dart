import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/screens/bookshelf_detail_screen.dart';
import 'package:llom/screens/home_screen.dart';
import 'package:llom/services/bookcase_service.dart';
import 'package:llom/services/update_service.dart';
import 'package:llom/widgets/book_card.dart';

class MockBookcaseServiceForSearch extends BookcaseService {
  final List<BookcaseModel> bookcases;
  final List<BookModel> books;

  MockBookcaseServiceForSearch({required this.bookcases, required this.books});

  @override
  Stream<List<BookcaseModel>> getBookcases(String libraryId) {
    return Stream.value(bookcases);
  }

  @override
  Stream<List<BookModel>> getAllBooks(String libraryId) {
    return Stream.value(books);
  }

  @override
  Stream<List<BookModel>> getBooksForBookcase(String libraryId, String bookcaseId) {
    return Stream.value(books.where((b) => b.bookcaseId == bookcaseId).toList());
  }
}

class MockUpdateServiceNone extends UpdateService {
  @override
  Future<UpdateInfo?> checkUpdate({String? currentVersionOverride}) async => null;
}

void main() {
  final now = DateTime(2026, 9, 16);
  final testUser = UserModel(
    uid: 'u_user',
    email: 'user@llom.cat',
    displayName: 'Usuari Llom',
    createdAt: now,
  );

  final testLib = LibraryModel(
    id: 'lib_search_test',
    name: 'Biblioteca Real',
    ownerId: 'u_user',
    inviteCode: 'REAL01',
    members: {'u_user': 'owner'},
    memberUids: ['u_user'],
    createdAt: now,
  );

  final testBookcase = BookcaseModel(
    id: 'bc_real_1',
    name: 'Estanteria Saló Real',
    room: 'Saló',
    shelfCount: 3,
    bookCount: 1,
    order: 0,
    createdAt: now,
  );

  final testBook = BookModel(
    id: 'b_real_1',
    title: 'Crònica de la veritat oculta',
    author: 'Pere Calders',
    shelfCode: 'bc_real_1-B2',
    bookcaseId: 'bc_real_1',
    positionIndex: 1,
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
          updateService: MockUpdateServiceNone(),
        ),
      ),
    );
  }

  group('HomeScreen Firestore Search Tests', () {
    testWidgets('Empty library search shows no books and friendly empty message', (tester) async {
      final mockService = MockBookcaseServiceForSearch(bookcases: [testBookcase], books: []);

      await tester.pumpWidget(createWidget(service: mockService));
      await tester.pumpAndSettle();

      // Cerca qualsevol paraula
      await tester.enterText(find.byType(TextField), 'Incerta');
      await tester.pump();

      // Ja no troba els llibres del mock antic
      expect(find.text('No s\'ha trobat cap llibre'), findsOneWidget);
      expect(find.text('Encara no hi ha cap llibre catalogat en aquesta biblioteca.'), findsOneWidget);
      expect(find.text('Incerta glòria'), findsNothing);
    });

    testWidgets('Real library search finds real book and navigates to BookshelfDetailScreen', (tester) async {
      final mockService = MockBookcaseServiceForSearch(bookcases: [testBookcase], books: [testBook]);

      await tester.pumpWidget(createWidget(service: mockService));
      await tester.pumpAndSettle();

      // Cerca pel llibre real
      await tester.enterText(find.byType(TextField), 'Calders');
      await tester.pump();

      expect(find.text('Trobat a Estanteria Saló Real'), findsOneWidget);
      expect(find.widgetWithText(BookCard, 'Crònica de la veritat oculta'), findsOneWidget);

      // Prem sobre la targeta del llibre
      await tester.tap(find.widgetWithText(BookCard, 'Crònica de la veritat oculta'));
      await tester.pumpAndSettle();

      // S'ha obert BookshelfDetailScreen (la pantalla real)
      expect(find.byType(BookshelfDetailScreen), findsOneWidget);
      expect(find.text('Estanteria Saló Real'), findsWidgets);
    });
  });

  group('BookshelfDetailScreen internal search tests', () {
    testWidgets('Internal search bar filters book spines and displays search hint', (tester) async {
      final mockService = MockBookcaseServiceForSearch(bookcases: [testBookcase], books: [testBook]);
      final provider = LibraryProvider();
      provider.currentUser = testUser;
      provider.activeLibrary = testLib;

      await tester.pumpWidget(
        ChangeNotifierProvider<LibraryProvider>.value(
          value: provider,
          child: MaterialApp(
            home: BookshelfDetailScreen(
              bookcase: testBookcase,
              libraryId: testLib.id,
              bookcaseService: mockService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cerca un llibre en aquesta estanteria...'), findsOneWidget);
      expect(find.text('Crònica de la veritat oculta'), findsOneWidget);

      // Cerca interna
      await tester.enterText(find.byType(TextField), 'Calders');
      await tester.pump();

      expect(find.text('Crònica de la veritat oculta'), findsOneWidget);
    });
  });
}
