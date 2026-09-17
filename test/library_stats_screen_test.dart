import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/screens/bookshelf_detail_screen.dart';
import 'package:llom/screens/library_stats_screen.dart';
import 'package:llom/services/bookcase_service.dart';

class MockBookcaseServiceForStats extends BookcaseService {
  final List<BookModel> books;

  MockBookcaseServiceForStats({required this.books});

  @override
  Stream<List<BookModel>> getAllBooks(String libraryId) {
    return Stream.value(books);
  }

  @override
  Stream<List<BookModel>> getBooksForBookcase(String libraryId, String bookcaseId) {
    return Stream.value(books.where((b) => b.bookcaseId == bookcaseId).toList());
  }

  @override
  Stream<List<BookcaseModel>> getBookcases(String libraryId) {
    return Stream.value([
      BookcaseModel(
        id: 'bc_1',
        name: 'Llibreria Saló',
        room: 'Saló',
        shelfCount: 2,
        bookCount: books.length,
        order: 0,
        createdAt: DateTime(2026, 1, 1),
      ),
    ]);
  }
}

class MockLibraryProviderForStats extends LibraryProvider {
  MockLibraryProviderForStats({required UserModel user, required LibraryModel library}) {
    currentUser = user;
    activeLibrary = library;
  }
}

void main() {
  final now = DateTime(2026, 9, 17);

  final testBooks = [
    BookModel(
      id: 'b1',
      title: 'Tirant lo Blanc',
      author: 'Joanot Martorell',
      shelfCode: 'bc_1-B1',
      bookcaseId: 'bc_1',
      positionIndex: 1,
      pageCount: 850,
      publishedYear: '1490',
      isBorrowed: true,
      createdAt: now,
    ),
    BookModel(
      id: 'b2',
      title: 'La plaça del Diamant',
      author: 'Mercè Rodoreda',
      shelfCode: 'bc_1-B1',
      bookcaseId: 'bc_1',
      positionIndex: 2,
      pageCount: 250,
      publishedYear: '1962',
      synopsis: 'Història de la Natàlia.',
      isBorrowed: false,
      createdAt: now,
    ),
    BookModel(
      id: 'b3',
      title: 'Mirall trencat',
      author: 'Mercè Rodoreda',
      shelfCode: 'bc_1-B2',
      bookcaseId: 'bc_1',
      positionIndex: 1,
      pageCount: 380,
      publishedYear: '1974',
      isBorrowed: false,
      createdAt: now,
    ),
    BookModel(
      id: 'b4',
      title: 'Crònica de la veritat oculta',
      author: 'Pere Calders',
      shelfCode: 'bc_1-B2',
      bookcaseId: 'bc_1',
      positionIndex: 2,
      pageCount: 190,
      publishedYear: '1955',
      isBorrowed: false,
      createdAt: now,
    ),
  ];

  group('LibraryStatsScreen tests', () {
    testWidgets('Renders empty state when no books exist', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LibraryStatsScreen(
            libraryName: 'Biblioteca Buida',
            initialBooks: [],
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estadístiques'), findsOneWidget);
      expect(find.text('Biblioteca Buida'), findsOneWidget);
      expect(find.text('Encara no hi ha estadístiques'), findsOneWidget);
      expect(find.byIcon(Icons.insights_rounded), findsOneWidget);
    });

    testWidgets('Renders KPI cards, top authors, singular books and decade distribution', (tester) async {
      tester.view.physicalSize = const Size(1000, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: LibraryStatsScreen(
            libraryName: 'Biblioteca Familiar',
            initialBooks: testBooks,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Capçalera
      expect(find.text('Estadístiques'), findsOneWidget);
      expect(find.text('Biblioteca Familiar'), findsOneWidget);

      // Targetes KPI
      expect(find.byKey(const Key('kpi_total_books')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('kpi_total_books')),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('kpi_total_pages')), findsOneWidget);
      expect(find.text('1.670'), findsOneWidget); // 850+250+380+190 = 1670
      expect(find.byKey(const Key('kpi_borrowed_books')), findsOneWidget);
      expect(find.text('1'), findsWidgets); // 1 borrowed
      expect(find.byKey(const Key('kpi_average_year')), findsOneWidget);

      // Top Autors
      expect(find.byKey(const Key('top_authors_container')), findsOneWidget);
      expect(find.text('Top autors de la col·lecció'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('top_authors_container')),
          matching: find.text('Mercè Rodoreda'),
        ),
        findsOneWidget,
      );
      expect(find.text('2 títols'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('top_authors_container')),
          matching: find.text('Joanot Martorell'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('top_authors_container')),
          matching: find.text('Pere Calders'),
        ),
        findsOneWidget,
      );

      // Llibres singulars
      expect(find.byKey(const Key('singular_oldest_book')), findsOneWidget);
      expect(find.text('El veterà'), findsOneWidget);
      expect(find.text('Edició de l\'any 1490'), findsOneWidget);

      expect(find.byKey(const Key('singular_longest_book')), findsOneWidget);
      expect(find.text('El gegant'), findsOneWidget);
      expect(find.text('850 pàgines de volum'), findsOneWidget);

      // Dècades
      expect(find.byKey(const Key('decades_distribution_container')), findsOneWidget);
      expect(find.text('Distribució per dècades'), findsOneWidget);
      expect(find.text('<1980'), findsOneWidget);
      expect(find.text('1980-1989'), findsOneWidget);
      expect(find.text('2020+'), findsOneWidget);
    });

    testWidgets('Renders with StreamBuilder when libraryId is provided', (tester) async {
      final mockService = MockBookcaseServiceForStats(books: testBooks);

      await tester.pumpWidget(
        MaterialApp(
          home: LibraryStatsScreen(
            libraryId: 'lib_test_stream',
            libraryName: 'Biblioteca Streaming',
            bookcaseService: mockService,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Estadístiques'), findsOneWidget);
      expect(find.text('Biblioteca Streaming'), findsOneWidget);
      expect(find.byKey(const Key('kpi_total_books')), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('kpi_total_books')),
          matching: find.text('4'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Tapping bookcase_stats_button in BookshelfDetailScreen navigates to LibraryStatsScreen', (tester) async {
      final bookcase = BookcaseModel(
        id: 'bc_1',
        name: 'Llibreria Saló',
        room: 'Saló',
        shelfCount: 2,
        bookCount: 4,
        order: 0,
        createdAt: now,
      );

      final user = UserModel(
        uid: 'u1',
        email: 'test@llom.cat',
        displayName: 'Usuari Test',
        createdAt: now,
      );

      final lib = LibraryModel(
        id: 'lib_1',
        name: 'Biblioteca Central',
        ownerId: 'u1',
        inviteCode: 'CENT12',
        members: {'u1': 'owner'},
        memberUids: ['u1'],
        createdAt: now,
      );

      final mockService = MockBookcaseServiceForStats(books: testBooks);

      await tester.pumpWidget(
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => MockLibraryProviderForStats(user: user, library: lib),
          child: MaterialApp(
            home: BookshelfDetailScreen(
              bookcase: bookcase,
              libraryId: 'lib_1',
              bookcaseService: mockService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final statsButton = find.byKey(const Key('bookcase_stats_button'));
      expect(statsButton, findsOneWidget);

      await tester.tap(statsButton);
      await tester.pumpAndSettle();

      expect(find.byType(LibraryStatsScreen), findsOneWidget);
      expect(find.text('Llibreria Saló'), findsOneWidget);
      expect(find.byKey(const Key('kpi_total_books')), findsOneWidget);
    });
  });
}
