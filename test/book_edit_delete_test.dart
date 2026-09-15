import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/screens/bookshelf_detail_screen.dart';
import 'package:llom/services/bookcase_service.dart';
import 'package:llom/widgets/add_manual_book_dialog.dart';

class MockBookcaseServiceForEditDelete extends BookcaseService {
  final List<BookcaseModel> bookcases;
  final List<BookModel> books;

  BookModel? lastUpdatedBook;
  String? lastUpdatedOldBookcaseId;
  String? lastDeletedBookId;

  MockBookcaseServiceForEditDelete({required this.bookcases, required this.books});

  @override
  Stream<List<BookcaseModel>> getBookcases(String libraryId) {
    return Stream.value(bookcases);
  }

  @override
  Stream<List<BookModel>> getBooksForBookcase(String libraryId, String bookcaseId) {
    return Stream.value(books.where((b) => b.bookcaseId == bookcaseId).toList());
  }

  @override
  Future<BookModel> updateBook(String libraryId, BookModel book, {String? oldBookcaseId}) async {
    lastUpdatedBook = book;
    lastUpdatedOldBookcaseId = oldBookcaseId;
    return book;
  }

  @override
  Future<void> deleteBook(String libraryId, String bookId, String bookcaseId) async {
    lastDeletedBookId = bookId;
  }
}

class MockLibraryProviderForEditDelete extends LibraryProvider {
  MockLibraryProviderForEditDelete({required UserModel user, required LibraryModel library}) {
    currentUser = user;
    activeLibrary = library;
  }
}

void main() {
  final now = DateTime(2026, 9, 15);
  final testBookcase = BookcaseModel(
    id: 'bc_1',
    name: 'Llibreria de Roure',
    room: 'Despatx',
    shelfCount: 3,
    bookCount: 1,
    order: 0,
    createdAt: now,
  );

  final testBook = BookModel(
    id: 'b1',
    title: 'Pedra de tartera',
    author: 'Maria Barbal',
    shelfCode: 'bc_1-B2',
    bookcaseId: 'bc_1',
    positionIndex: 1,
    createdAt: now,
  );

  final testUser = UserModel(
    uid: 'u_1',
    email: 'test@llom.cat',
    displayName: 'Usuari Test',
    createdAt: now,
  );

  final testLib = LibraryModel(
    id: 'lib_test',
    name: 'Biblioteca Central',
    ownerId: 'u_1',
    inviteCode: 'CENT12',
    members: {'u_1': 'owner'},
    memberUids: ['u_1'],
    createdAt: now,
  );

  Widget createDetailWidget({required BookcaseService service}) {
    return ChangeNotifierProvider<LibraryProvider>(
      create: (_) => MockLibraryProviderForEditDelete(user: testUser, library: testLib),
      child: MaterialApp(
        home: BookshelfDetailScreen(
          bookcase: testBookcase,
          libraryId: 'lib_test',
          bookcaseService: service,
        ),
      ),
    );
  }

  group('Book edit and delete bottom modal tests', () {
    testWidgets('showEditBookBottomSheet pre-fills book data and saves updates', (tester) async {
      final mockService = MockBookcaseServiceForEditDelete(
        bookcases: [testBookcase],
        books: [testBook],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showEditBookBottomSheet(
                      context,
                      libraryId: 'lib_test',
                      bookcase: testBookcase,
                      book: testBook,
                      bookcaseService: mockService,
                    );
                  },
                  child: const Text('Obrir Edició'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Obrir Edició'));
      await tester.pumpAndSettle();

      // Verify bottom sheet title and pre-filled data
      expect(find.text('Editar llibre'), findsOneWidget);
      expect(find.text('Moble: Llibreria de Roure'), findsOneWidget);
      expect(find.text('Pedra de tartera'), findsOneWidget);
      expect(find.text('Maria Barbal'), findsOneWidget);
      expect(find.text('Desar canvis'), findsOneWidget);

      // Edit title
      await tester.enterText(find.byKey(const Key('book_title_field')), 'Pedra de tartera (Edició especial)');
      await tester.pumpAndSettle();

      // Submit changes
      await tester.tap(find.byKey(const Key('submit_book_button')));
      await tester.pumpAndSettle();

      // Verify service called
      expect(mockService.lastUpdatedBook, isNotNull);
      expect(mockService.lastUpdatedBook!.title, 'Pedra de tartera (Edició especial)');
      expect(mockService.lastUpdatedBook!.author, 'Maria Barbal');
      expect(mockService.lastUpdatedBook!.shelfCode, 'bc_1-B2');
      expect(mockService.lastUpdatedOldBookcaseId, 'bc_1');
    });

    testWidgets('Tapping book in BookshelfDetailScreen opens bottom sheet with Editar and Eliminar', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForEditDelete(
        bookcases: [testBookcase],
        books: [testBook],
      );

      await tester.pumpWidget(createDetailWidget(service: mockService));
      await tester.pumpAndSettle();

      // Tap on the book spine
      final bookSpine = find.text('Pedra de tartera');
      expect(bookSpine, findsOneWidget);
      await tester.tap(bookSpine);
      await tester.pumpAndSettle();

      // Verify bottom sheet modal opened
      expect(find.byKey(const Key('edit_book_button')), findsOneWidget);
      expect(find.byKey(const Key('delete_book_button')), findsOneWidget);
      expect(
        find.descendant(of: find.byType(BottomSheet), matching: find.text('Balda 2')),
        findsOneWidget,
      );

      // Tap Editar
      await tester.tap(find.byKey(const Key('edit_book_button')));
      await tester.pumpAndSettle();

      // Verify edit sheet opened
      expect(find.text('Editar llibre'), findsOneWidget);
      expect(find.text('Desar canvis'), findsOneWidget);
    });

    testWidgets('Tapping Eliminar shows confirm dialog and calls deleteBook on confirmation', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForEditDelete(
        bookcases: [testBookcase],
        books: [testBook],
      );

      await tester.pumpWidget(createDetailWidget(service: mockService));
      await tester.pumpAndSettle();

      // Tap on book
      await tester.tap(find.text('Pedra de tartera'));
      await tester.pumpAndSettle();

      // Tap Eliminar
      await tester.tap(find.byKey(const Key('delete_book_button')));
      await tester.pumpAndSettle();

      // Verify confirmation dialog appeared
      expect(find.text('Eliminar llibre'), findsOneWidget);
      expect(find.text('Segur que vols eliminar "Pedra de tartera" d\'aquesta estanteria? Aquesta acció no es pot desfer.'), findsOneWidget);
      expect(find.byKey(const Key('confirm_delete_book_button')), findsOneWidget);

      // Confirm deletion
      await tester.tap(find.byKey(const Key('confirm_delete_book_button')));
      await tester.pumpAndSettle();

      // Verify service delete called
      expect(mockService.lastDeletedBookId, 'b1');
    });
  });
}
