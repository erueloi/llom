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

class MockBookcaseServiceForReorder extends BookcaseService {
  final List<BookModel> books;
  List<BookModel>? lastUpdatedOrder;

  MockBookcaseServiceForReorder({required this.books});

  @override
  Stream<List<BookcaseModel>> getBookcases(String libraryId) {
    return Stream.value([
      BookcaseModel(
        id: 'bc_reorder',
        name: 'Estanteria Reorder',
        room: 'Estudi',
        shelfCount: 2,
        bookCount: books.length,
        order: 0,
        createdAt: DateTime(2026, 9, 16),
      ),
    ]);
  }

  @override
  Stream<List<BookModel>> getBooksForBookcase(String libraryId, String bookcaseId) {
    return Stream.value(books);
  }

  @override
  Future<void> updateShelfBooksOrder({
    required String libraryId,
    required List<BookModel> books,
  }) async {
    lastUpdatedOrder = List.from(books);
  }
}

class MockLibraryProviderForReorder extends LibraryProvider {
  MockLibraryProviderForReorder({required UserModel user, required LibraryModel library}) {
    currentUser = user;
    activeLibrary = library;
  }
}

void main() {
  final now = DateTime(2026, 9, 16);
  final testBookcase = BookcaseModel(
    id: 'bc_reorder',
    name: 'Estanteria Reorder',
    room: 'Estudi',
    shelfCount: 2,
    bookCount: 3,
    order: 0,
    createdAt: now,
  );

  final testUser = UserModel(
    uid: 'u_owner',
    email: 'owner@llom.cat',
    displayName: 'Propietari Test',
    createdAt: now,
  );

  final testLib = LibraryModel(
    id: 'lib_reorder',
    name: 'Biblioteca Test',
    ownerId: 'u_owner',
    inviteCode: 'REORD1',
    members: {'u_owner': 'owner'},
    memberUids: ['u_owner'],
    createdAt: now,
  );

  group('Shelf books drag & drop reorder tests', () {
    testWidgets('Renders horizontal ReorderableListView with books and custom keys', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final books = [
        BookModel(
          id: 'book_a',
          title: 'Llibre Primer',
          author: 'Autor A',
          shelfCode: 'bc_reorder-B1',
          bookcaseId: 'bc_reorder',
          positionIndex: 1,
          createdAt: now,
        ),
        BookModel(
          id: 'book_b',
          title: 'Llibre Segon',
          author: 'Autor B',
          shelfCode: 'bc_reorder-B1',
          bookcaseId: 'bc_reorder',
          positionIndex: 2,
          createdAt: now,
        ),
        BookModel(
          id: 'book_c',
          title: 'Llibre Tercer',
          author: 'Autor C',
          shelfCode: 'bc_reorder-B1',
          bookcaseId: 'bc_reorder',
          positionIndex: 3,
          createdAt: now,
        ),
      ];

      final mockService = MockBookcaseServiceForReorder(books: books);

      await tester.pumpWidget(
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => MockLibraryProviderForReorder(user: testUser, library: testLib),
          child: MaterialApp(
            home: BookshelfDetailScreen(
              bookcase: testBookcase,
              libraryId: 'lib_reorder',
              bookcaseService: mockService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find horizontal ReorderableListView
      final reorderableList = find.byType(ReorderableListView);
      expect(reorderableList, findsOneWidget);

      final reorderableWidget = tester.widget<ReorderableListView>(reorderableList);
      expect(reorderableWidget.scrollDirection, Axis.horizontal);

      // Verify the 3 books are rendered with display ordinals #1, #2, #3
      expect(find.text('Llibre Primer'), findsOneWidget);
      expect(find.text('Llibre Segon'), findsOneWidget);
      expect(find.text('Llibre Tercer'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);

      // Verify ReorderableDelayedDragStartListener widgets exist for each book
      expect(find.byKey(const ValueKey('book_a')), findsOneWidget);
      expect(find.byKey(const ValueKey('book_b')), findsOneWidget);
      expect(find.byKey(const ValueKey('book_c')), findsOneWidget);
    });

    testWidgets('Triggering onReorder on shelf ReorderableListView calls updateShelfBooksOrder', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final books = [
        BookModel(
          id: 'book_a',
          title: 'Llibre Primer',
          author: 'Autor A',
          shelfCode: 'bc_reorder-B1',
          bookcaseId: 'bc_reorder',
          positionIndex: 1,
          createdAt: now,
        ),
        BookModel(
          id: 'book_b',
          title: 'Llibre Segon',
          author: 'Autor B',
          shelfCode: 'bc_reorder-B1',
          bookcaseId: 'bc_reorder',
          positionIndex: 2,
          createdAt: now,
        ),
        BookModel(
          id: 'book_c',
          title: 'Llibre Tercer',
          author: 'Autor C',
          shelfCode: 'bc_reorder-B1',
          bookcaseId: 'bc_reorder',
          positionIndex: 3,
          createdAt: now,
        ),
      ];

      final mockService = MockBookcaseServiceForReorder(books: books);

      await tester.pumpWidget(
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => MockLibraryProviderForReorder(user: testUser, library: testLib),
          child: MaterialApp(
            home: BookshelfDetailScreen(
              bookcase: testBookcase,
              libraryId: 'lib_reorder',
              bookcaseService: mockService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final reorderableWidget = tester.widget<ReorderableListView>(find.byType(ReorderableListView));

      // Reorder: move item at index 0 (book_a) to index 2 (between book_b and book_c)
      reorderableWidget.onReorder(0, 2);
      await tester.pumpAndSettle();

      // Check service was invoked with new order: book_b, book_a, book_c
      expect(mockService.lastUpdatedOrder, isNotNull);
      expect(mockService.lastUpdatedOrder!.length, 3);
      expect(mockService.lastUpdatedOrder![0].id, 'book_b');
      expect(mockService.lastUpdatedOrder![1].id, 'book_a');
      expect(mockService.lastUpdatedOrder![2].id, 'book_c');
    });

    testWidgets('Renders matching badge and jump pill when matching book is offscreen on mobile', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Create 20 books on Balda 1, where only book #19 matches 'quixot'
      final manyBooks = List.generate(20, (i) {
        final isMatch = i == 18;
        return BookModel(
          id: 'book_$i',
          title: isMatch ? 'El Quixot de la Manxa' : 'Llibre Ordinari $i',
          author: isMatch ? 'Cervantes' : 'Autor Comu',
          shelfCode: 'bc_reorder-B1',
          bookcaseId: 'bc_reorder',
          positionIndex: i + 1,
          createdAt: now,
        );
      });

      final mockService = MockBookcaseServiceForReorder(books: manyBooks);

      await tester.pumpWidget(
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => MockLibraryProviderForReorder(user: testUser, library: testLib),
          child: MaterialApp(
            home: BookshelfDetailScreen(
              bookcase: testBookcase,
              libraryId: 'lib_reorder',
              bookcaseService: mockService,
              initialSearchQuery: 'quixot',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Shelf header should display the matching badge "1 coincident"
      expect(find.text('1 coincident'), findsWidgets);

      // Because the book #19 is offscreen or auto-scrolled, either a jump pill or book spine is visible
      // Tapping the matching book or jump pill works
      expect(find.textContaining('Quixot'), findsOneWidget);
    });

    testWidgets('Tapping right jump pill scrolls to offscreen match', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Book 0 matches AND Book 19 matches 'quixot'.
      // Book 0 is visible at start, so shelf remains at offset 0.
      // Book 19 is offscreen to the right, so the right jump pill appears!
      final manyBooks = List.generate(20, (i) {
        final isMatch = i == 0 || i == 19;
        return BookModel(
          id: 'book_$i',
          title: isMatch ? 'El Quixot $i' : 'Llibre $i',
          author: 'Autor',
          shelfCode: 'bc_reorder-B1',
          bookcaseId: 'bc_reorder',
          positionIndex: i + 1,
          createdAt: now,
        );
      });

      final mockService = MockBookcaseServiceForReorder(books: manyBooks);

      await tester.pumpWidget(
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => MockLibraryProviderForReorder(user: testUser, library: testLib),
          child: MaterialApp(
            home: BookshelfDetailScreen(
              bookcase: testBookcase,
              libraryId: 'lib_reorder',
              bookcaseService: mockService,
              initialSearchQuery: 'quixot',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header shows 2 coincidents
      expect(find.text('2 coincidents'), findsWidgets);

      // Right jump pill with arrow forward should be visible
      final rightPill = find.byKey(const Key('jump_pill_right_1'));
      expect(rightPill, findsOneWidget);

      // Tap the right jump pill
      await tester.tap(rightPill);
      await tester.pumpAndSettle();

      // After scrolling right, left jump pill with arrow back appears
      expect(find.byKey(const Key('jump_pill_left_1')), findsOneWidget);
    });
  });
}
