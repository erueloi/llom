import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/services/book_enrichment_service.dart';
import 'package:llom/services/bookcase_service.dart';
import 'package:llom/widgets/add_manual_book_dialog.dart';

class MockBookcaseServiceForAddBook extends BookcaseService {
  BookModel? lastAddedBook;
  String? lastLibraryId;

  @override
  Future<BookModel> addBook(String libraryId, BookModel book) async {
    lastLibraryId = libraryId;
    lastAddedBook = book.copyWith(id: 'saved_book_123');
    return lastAddedBook!;
  }
}

void main() {
  final testBookcase = BookcaseModel(
    id: 'bc_test_1',
    name: 'Estanteria Saló',
    room: 'Menjador',
    shelfCount: 4,
    bookCount: 10,
    order: 0,
    createdAt: DateTime(2026, 1, 1),
  );

  group('AddManualBookDialog tests', () {
    testWidgets('Validates title is required', (tester) async {
      final mockService = MockBookcaseServiceForAddBook();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAddManualBookDialog(
                      context,
                      libraryId: 'lib_1',
                      bookcase: testBookcase,
                      bookcaseService: mockService,
                    );
                  },
                  child: const Text('Obrir'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Obrir'));
      await tester.pumpAndSettle();

      expect(find.text('Afegir llibre'), findsOneWidget);
      expect(find.text('Moble: Estanteria Saló'), findsOneWidget);

      // Try submitting without title
      await tester.tap(find.byKey(const Key('submit_book_button')));
      await tester.pumpAndSettle();

      expect(find.text('El títol del llibre és obligatori.'), findsOneWidget);
      expect(mockService.lastAddedBook, isNull);
    });

    testWidgets('Submits book with title, author and selected shelf', (tester) async {
      final mockService = MockBookcaseServiceForAddBook();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAddManualBookDialog(
                      context,
                      libraryId: 'lib_1',
                      bookcase: testBookcase,
                      initialShelfIndex: 3,
                      bookcaseService: mockService,
                    );
                  },
                  child: const Text('Obrir'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Obrir'));
      await tester.pumpAndSettle();

      // Fill in title and author
      await tester.enterText(find.byKey(const Key('book_title_field')), 'Tirant lo Blanc');
      await tester.enterText(find.byKey(const Key('book_author_field')), 'Joanot Martorell');

      // Verify shelf 3 is selected by default from initialShelfIndex
      expect(find.text('Balda 3'), findsOneWidget);

      await tester.tap(find.byKey(const Key('submit_book_button')));
      await tester.pumpAndSettle();

      expect(mockService.lastLibraryId, 'lib_1');
      expect(mockService.lastAddedBook, isNotNull);
      expect(mockService.lastAddedBook!.title, 'Tirant lo Blanc');
      expect(mockService.lastAddedBook!.author, 'Joanot Martorell');
      expect(mockService.lastAddedBook!.shelfCode, 'bc_test_1-B3');
      expect(mockService.lastAddedBook!.bookcaseId, 'bc_test_1');

      // SnackBar verification
      expect(find.text('Llibre "Tirant lo Blanc" afegit a la balda 3!'), findsOneWidget);
    });

    testWidgets('Magic wand warns if title is empty', (tester) async {
      final mockEnrichment = MockBookEnrichmentServiceForAuthor(returnedAuthor: 'Mercè Rodoreda');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAddManualBookDialog(
                      context,
                      libraryId: 'lib_1',
                      bookcase: testBookcase,
                      enrichmentService: mockEnrichment,
                    );
                  },
                  child: const Text('Obrir'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Obrir'));
      await tester.pumpAndSettle();

      // Tap magic wand with empty title
      await tester.tap(find.byKey(const Key('auto_fill_author_button')));
      await tester.pumpAndSettle();

      expect(find.text('Escriu primer el títol del llibre per cercar-ne l\'autor/a.'), findsOneWidget);
    });

    testWidgets('Magic wand auto-fills author when found', (tester) async {
      final mockEnrichment = MockBookEnrichmentServiceForAuthor(returnedAuthor: 'Mercè Rodoreda');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showAddManualBookDialog(
                      context,
                      libraryId: 'lib_1',
                      bookcase: testBookcase,
                      enrichmentService: mockEnrichment,
                    );
                  },
                  child: const Text('Obrir'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Obrir'));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(find.byKey(const Key('book_title_field')), 'La plaça del Diamant');

      // Tap magic wand
      await tester.tap(find.byKey(const Key('auto_fill_author_button')));
      await tester.pumpAndSettle();

      // Verify author field is updated
      final authorFormField = tester.widget<TextFormField>(find.byKey(const Key('book_author_field')));
      expect(authorFormField.controller!.text, 'Mercè Rodoreda');
      expect(find.text('S\'ha trobat l\'autor/a: "Mercè Rodoreda"'), findsOneWidget);
    });
  });
}

class MockBookEnrichmentServiceForAuthor extends BookEnrichmentService {
  final String? returnedAuthor;
  MockBookEnrichmentServiceForAuthor({this.returnedAuthor});

  @override
  Future<String?> lookupAuthorByTitle(String title) async {
    return returnedAuthor;
  }
}
