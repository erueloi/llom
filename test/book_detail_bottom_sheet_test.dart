import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llom/main.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/services/book_enrichment_service.dart';
import 'package:llom/services/bookcase_service.dart';
import 'package:llom/widgets/book_detail_bottom_sheet.dart';

class MockBookcaseServiceForSheet extends BookcaseService {
  bool toggleCalled = false;
  bool? lastIsBorrowed;
  String? lastBorrowedTo;

  @override
  Future<void> toggleBookBorrowedStatus({
    required String libraryId,
    required String bookId,
    required bool isBorrowed,
    String? borrowedTo,
    DateTime? borrowedAt,
  }) async {
    toggleCalled = true;
    lastIsBorrowed = isBorrowed;
    lastBorrowedTo = borrowedTo;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  final testBookcase = BookcaseModel(
    id: 'bc_test_1',
    name: 'Llibreria de Roure',
    room: 'Saló Principal',
    shelfCount: 4,
    bookCount: 12,
    createdAt: DateTime.now(),
  );

  final testBook = BookModel(
    id: 'book_detail_test_1',
    title: 'Crònica de la veritat oculta',
    author: 'Pere Calders',
    shelfCode: 'bc_test_1-B2',
    positionIndex: 3,
    synopsis: 'Un recull de contes extraordinaris on la fantasia irromp en la quotidianitat amb ironia i tendresa. Pere Calders construeix un món fascinant ple d\'humor subtil i situacions inversemblants.',
    coverUrl: null,
    pageCount: 312,
    publishedYear: '1955',
    infoUrl: 'https://books.google.com/test',
    photoUrl: 'https://example.com/shelf.jpg',
    box: [120, 300, 750, 420],
    createdAt: DateTime.now(),
  );

  Widget createTestWidget({
    required BookModel book,
    required BookcaseModel bookcase,
    bool canEdit = true,
    BookcaseService? bookcaseService,
    BookEnrichmentService? enrichmentService,
    String libraryId = 'lib_test_123',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: ElevatedButton(
                key: const Key('open_sheet_button'),
                onPressed: () {
                  showBookDetailBottomSheet(
                    context,
                    book: book,
                    bookcase: bookcase,
                    libraryId: libraryId,
                    canEdit: canEdit,
                    bookcaseService: bookcaseService,
                    enrichmentService: enrichmentService,
                  );
                },
                child: const Text('Obrir Detall'),
              ),
            );
          },
        ),
      ),
    );
  }

  group('BookDetailBottomSheet widget tests', () {
    testWidgets('Renders header, location chips, metadata and synopsis', (tester) async {
      await tester.pumpWidget(createTestWidget(book: testBook, bookcase: testBookcase));

      // Obrir la Bottom Sheet
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      // Verificar títol i autor
      expect(find.byKey(const Key('book_detail_title')), findsOneWidget);
      expect(find.text('Crònica de la veritat oculta'), findsWidgets);
      expect(find.byKey(const Key('book_detail_author')), findsOneWidget);
      expect(find.text('Pere Calders'), findsOneWidget);

      // Metadades (any i pàgines)
      expect(find.text('1955'), findsOneWidget);
      expect(find.text('312 pàg.'), findsOneWidget);

      // Xips d'ubicació
      expect(find.text('Llibreria de Roure'), findsOneWidget);
      expect(find.text('Saló Principal'), findsOneWidget);
      expect(find.text('Balda 2'), findsOneWidget);
      expect(find.text('Posició #3'), findsOneWidget);

      // Bloc de sinopsi
      expect(find.text('SINOPSI'), findsOneWidget);
      expect(find.textContaining('Un recull de contes extraordinaris'), findsOneWidget);

      // Botons
      expect(find.byKey(const Key('locate_on_shelf_button')), findsOneWidget);
      expect(find.byKey(const Key('google_books_button')), findsOneWidget);
      expect(find.byKey(const Key('edit_book_button')), findsOneWidget);
      expect(find.byKey(const Key('delete_book_button')), findsOneWidget);
    });

    testWidgets('Expands and collapses synopsis text on toggle', (tester) async {
      await tester.pumpWidget(createTestWidget(book: testBook, bookcase: testBookcase));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      final toggleFinder = find.text('Llegir més ▾');
      if (toggleFinder.evaluate().isNotEmpty) {
        await tester.tap(toggleFinder);
        await tester.pumpAndSettle();
        expect(find.text('Llegir menys ▴'), findsOneWidget);

        await tester.tap(find.text('Llegir menys ▴'));
        await tester.pumpAndSettle();
        expect(find.text('Llegir més ▾'), findsOneWidget);
      }
    });

    testWidgets('Tapping locate_on_shelf_button opens visual locator dialog when photo and box exist', (tester) async {
      await tester.pumpWidget(createTestWidget(book: testBook, bookcase: testBookcase));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('locate_on_shelf_button')));
      await tester.pumpAndSettle();

      // Ha d'obrir el diàleg visual de localització
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Balda 2 · Llibreria de Roure'), findsOneWidget);

      // Tancar diàleg
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Hides edit and delete buttons when canEdit is false', (tester) async {
      await tester.pumpWidget(createTestWidget(
        book: testBook,
        bookcase: testBookcase,
        canEdit: false,
      ));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('locate_on_shelf_button')), findsOneWidget);
      expect(find.byKey(const Key('google_books_button')), findsOneWidget);
      expect(find.byKey(const Key('edit_book_button')), findsNothing);
      expect(find.byKey(const Key('delete_book_button')), findsNothing);
    });

    testWidgets('Does NOT trigger enrichmentService if book has both synopsis and cover', (tester) async {
      int enrichmentCalls = 0;
      final mockClient = MockClient((_) async {
        enrichmentCalls++;
        return http.Response('{}', 200);
      });
      final enrichmentService = BookEnrichmentService(httpClient: mockClient);

      final fullyEnrichedBook = testBook.copyWith(
        coverUrl: 'https://example.com/cover.jpg',
      );

      await tester.pumpWidget(createTestWidget(
        book: fullyEnrichedBook,
        bookcase: testBookcase,
        enrichmentService: enrichmentService,
      ));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(enrichmentCalls, 0);
    });

    testWidgets('Does NOT trigger enrichmentService if book reached 3 attempts', (tester) async {
      int enrichmentCalls = 0;
      final mockClient = MockClient((_) async {
        enrichmentCalls++;
        return http.Response('{}', 200);
      });
      final enrichmentService = BookEnrichmentService(httpClient: mockClient);

      final maxAttemptsBook = testBook.copyWith(
        enrichmentAttempts: 3,
      );

      await tester.pumpWidget(createTestWidget(
        book: maxAttemptsBook,
        bookcase: testBookcase,
        enrichmentService: enrichmentService,
      ));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(enrichmentCalls, 0);
    });

    testWidgets('Triggers enrichmentService when book has synopsis but lacks cover to try finding cover', (tester) async {
      int enrichmentCalls = 0;
      final mockClient = MockClient((_) async {
        enrichmentCalls++;
        return http.Response(
          jsonEncode({
            'totalItems': 1,
            'items': [
              {
                'volumeInfo': {
                  'imageLinks': {'thumbnail': 'https://example.com/found_cover.jpg'},
                }
              }
            ]
          }),
          200,
        );
      });
      final enrichmentService = BookEnrichmentService(httpClient: mockClient);

      await tester.pumpWidget(createTestWidget(
        book: testBook, // Has synopsis, but coverUrl is null and attempts is 0
        bookcase: testBookcase,
        enrichmentService: enrichmentService,
        libraryId: '',
      ));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(enrichmentCalls, greaterThan(0));
    });

    testWidgets('Triggers enrichmentService when book lacks synopsis and cover', (tester) async {
      int enrichmentCalls = 0;
      final mockClient = MockClient((_) async {
        enrichmentCalls++;
        return http.Response(
          jsonEncode({
            'totalItems': 1,
            'items': [
              {
                'volumeInfo': {
                  'description': 'Sinopsi descarregada automàticament.',
                }
              }
            ]
          }),
          200,
        );
      });
      final enrichmentService = BookEnrichmentService(httpClient: mockClient);

      final unenrichedBook = BookModel(
        id: 'book_unenriched',
        title: 'Llibre Nou',
        author: 'Autor Nou',
        shelfCode: 'bc_test_1-B1',
        positionIndex: 1,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(
        book: unenrichedBook,
        bookcase: testBookcase,
        enrichmentService: enrichmentService,
        libraryId: '',
      ));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(enrichmentCalls, greaterThan(0));
      expect(find.text('Sinopsi descarregada automàticament.'), findsOneWidget);
    });

    testWidgets('Renders Open Library button and icon when infoUrl points to Open Library', (tester) async {
      final openLibBook = testBook.copyWith(
        infoUrl: 'https://openlibrary.org/works/OL12345W',
      );

      await tester.pumpWidget(createTestWidget(book: openLibBook, bookcase: testBookcase));
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('Open Library'), findsOneWidget);
      expect(find.byIcon(Icons.local_library_outlined), findsOneWidget);
    });

    testWidgets('Renders Google Books button and icon when infoUrl points to Google Books', (tester) async {
      final googleBook = testBook.copyWith(
        infoUrl: 'https://books.google.cat/books?id=xyz',
      );

      await tester.pumpWidget(createTestWidget(book: googleBook, bookcase: testBookcase));
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('Google Books'), findsOneWidget);
      expect(find.byIcon(Icons.menu_book_rounded), findsOneWidget);
    });

    testWidgets('Renders Fitxa del llibre button and icon when infoUrl is generic or null', (tester) async {
      final genericBook = BookModel(
        id: 'book_generic_url',
        title: 'Llibre Genèric',
        author: 'Autor',
        shelfCode: 'bc_test_1-B2',
        positionIndex: 1,
        synopsis: 'Sinopsi existent.',
        infoUrl: 'https://editorial.cat/llibre',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(book: genericBook, bookcase: testBookcase));
      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.text('Fitxa del llibre'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    });

    testWidgets('Renders borrow button when not borrowed, opens dialog and confirms borrow', (tester) async {
      final mockService = MockBookcaseServiceForSheet();
      await tester.pumpWidget(createTestWidget(
        book: testBook,
        bookcase: testBookcase,
        bookcaseService: mockService,
      ));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      // No està prestat -> no hi ha banner, hi ha botó de prestar
      expect(find.byKey(const Key('borrowed_info_banner')), findsNothing);
      final borrowBtn = find.byKey(const Key('borrow_book_button'));
      expect(borrowBtn, findsOneWidget);

      await tester.ensureVisible(borrowBtn);
      await tester.tap(borrowBtn);
      await tester.pumpAndSettle();

      // S'obre el diàleg de préstec
      expect(find.text('Treure de la balda'), findsOneWidget);
      expect(find.byKey(const Key('borrowed_to_text_field')), findsOneWidget);

      // Prémer chip 'Amic/ga'
      await tester.tap(find.text('Amic/ga'));
      await tester.pumpAndSettle();

      // Confirmar
      await tester.tap(find.byKey(const Key('confirm_borrow_button')));
      await tester.pumpAndSettle();

      expect(mockService.toggleCalled, isTrue);
      expect(mockService.lastIsBorrowed, isTrue);
      expect(mockService.lastBorrowedTo, 'Amic/ga');

      // Ara es mostra el banner de llibre fora de la balda i el botó de retornar
      expect(find.byKey(const Key('borrowed_info_banner')), findsOneWidget);
      expect(find.text('Amic/ga'), findsOneWidget);
      expect(find.byKey(const Key('return_book_button')), findsOneWidget);
    });

    testWidgets('Renders borrowed banner and return button when borrowed; clicking returns book', (tester) async {
      final mockService = MockBookcaseServiceForSheet();
      final borrowedBook = testBook.copyWith(
        isBorrowed: true,
        borrowedTo: 'Carme',
        borrowedAt: DateTime(2026, 9, 10),
      );

      await tester.pumpWidget(createTestWidget(
        book: borrowedBook,
        bookcase: testBookcase,
        bookcaseService: mockService,
      ));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      // Està prestat
      expect(find.byKey(const Key('borrowed_info_banner')), findsOneWidget);
      expect(find.text('Carme'), findsOneWidget);
      expect(find.textContaining('10/09/2026'), findsOneWidget);

      final returnBtn = find.byKey(const Key('return_book_button'));
      expect(returnBtn, findsOneWidget);
      expect(find.byKey(const Key('borrow_book_button')), findsNothing);

      await tester.ensureVisible(returnBtn);
      await tester.tap(returnBtn);
      await tester.pumpAndSettle();

      expect(mockService.toggleCalled, isTrue);
      expect(mockService.lastIsBorrowed, isFalse);
      expect(find.byKey(const Key('borrowed_info_banner')), findsNothing);
      expect(find.byKey(const Key('borrow_book_button')), findsOneWidget);
    });

    testWidgets('Header renders top-right compact action icons with tooltips', (tester) async {
      await tester.pumpWidget(createTestWidget(
        book: testBook,
        bookcase: testBookcase,
      ));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      // Botó de recàrrega de dades
      final refreshFinder = find.byKey(const Key('refresh_enrichment_button'));
      expect(refreshFinder, findsOneWidget);
      final refreshButton = tester.widget<IconButton>(refreshFinder);
      expect(refreshButton.tooltip, equals('Recarregar dades (sinopsi i portada)'));

      // Botó de localitzar a la balda
      final locateFinder = find.byKey(const Key('locate_on_shelf_button'));
      expect(locateFinder, findsOneWidget);
      final locateButton = tester.widget<IconButton>(locateFinder);
      expect(locateButton.tooltip, equals('Localitzar a la balda'));

      // Botó de préstec
      final borrowFinder = find.byKey(const Key('borrow_book_button'));
      expect(borrowFinder, findsOneWidget);
      final borrowButton = tester.widget<IconButton>(borrowFinder);
      expect(borrowButton.tooltip, equals('Treure de la balda / Marcar prestat'));
    });

    testWidgets('Displays ai_synopsis_badge when book.isAiSynopsis is true', (tester) async {
      final bookWithAi = testBook.copyWith(
        isAiSynopsis: true,
        synopsis: 'Aquest és un resum generat per Gemini.',
      );

      await tester.pumpWidget(createTestWidget(
        book: bookWithAi,
        bookcase: testBookcase,
      ));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('ai_synopsis_badge')), findsOneWidget);
      expect(find.text('✨ Resum generat per IA'), findsOneWidget);
      expect(find.text('Aquest és un resum generat per Gemini.'), findsOneWidget);
    });

    testWidgets('Shows generate_ai_synopsis_button when synopsis is empty and updates when tapped', (tester) async {
      final mockEnrichment = MockBookEnrichmentServiceForDetailSheet(
        mockAiSynopsis: 'Nova sinopsi generada amb Gemini Flash.',
      );

      final bookWithoutSynopsis = BookModel(
        id: 'b_no_synopsis',
        title: 'Llibre Desconegut',
        author: 'Autor Anònim',
        shelfCode: 'bc_test_1-B1',
        positionIndex: 1,
        synopsis: null,
        enrichmentAttempts: 3,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(createTestWidget(
        book: bookWithoutSynopsis,
        bookcase: testBookcase,
        enrichmentService: mockEnrichment,
        canEdit: true,
      ));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      final generateBtn = find.byKey(const Key('generate_ai_synopsis_button'));
      expect(generateBtn, findsOneWidget);
      expect(find.text('Generar sinopsi amb IA'), findsOneWidget);

      await tester.ensureVisible(generateBtn);
      await tester.tap(generateBtn);
      await tester.pumpAndSettle();

      expect(mockEnrichment.generateAiSynopsisCalled, isTrue);
      expect(find.byKey(const Key('ai_synopsis_badge')), findsOneWidget);
      expect(find.text('Nova sinopsi generada amb Gemini Flash.'), findsOneWidget);
      expect(find.byKey(const Key('generate_ai_synopsis_button')), findsNothing);
    });

    testWidgets('Tapping change_cover_button opens cover source bottom sheet', (tester) async {
      await tester.pumpWidget(createTestWidget(
        book: testBook,
        bookcase: testBookcase,
        canEdit: true,
      ));

      await tester.tap(find.byKey(const Key('open_sheet_button')));
      await tester.pumpAndSettle();

      final changeCoverBtn = find.byKey(const Key('change_cover_button'));
      expect(changeCoverBtn, findsOneWidget);

      await tester.tap(changeCoverBtn);
      await tester.pumpAndSettle();

      expect(find.text('Canviar portada del llibre'), findsOneWidget);
      expect(find.byKey(const Key('cover_source_camera')), findsOneWidget);
      expect(find.byKey(const Key('cover_source_gallery')), findsOneWidget);
    });
  });

  group('AppScrollBehavior tests', () {
    test('Includes mouse, touch and trackpad drag devices', () {
      const behavior = AppScrollBehavior();
      final devices = behavior.dragDevices;
      expect(devices, contains(PointerDeviceKind.mouse));
      expect(devices, contains(PointerDeviceKind.touch));
      expect(devices, contains(PointerDeviceKind.trackpad));
    });
  });
}

class MockBookEnrichmentServiceForDetailSheet extends BookEnrichmentService {
  final String? mockAiSynopsis;
  final String? mockUploadedCover;
  bool generateAiSynopsisCalled = false;
  bool uploadBookCoverCalled = false;

  MockBookEnrichmentServiceForDetailSheet({
    this.mockAiSynopsis = 'Resum automàtic generat per Gemini.',
    this.mockUploadedCover = 'https://example.com/uploaded_cover.jpg',
  });

  @override
  Future<String?> generateAiSynopsis({
    required String title,
    String? author,
    int? year,
    String? apiKeyOverride,
    dynamic modelOverride,
  }) async {
    generateAiSynopsisCalled = true;
    return mockAiSynopsis;
  }

  @override
  Future<String?> uploadBookCover({
    required String libraryId,
    required String bookId,
    required dynamic imageBytes,
    dynamic storageOverride,
  }) async {
    uploadBookCoverCalled = true;
    return mockUploadedCover;
  }
}
