import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/models/detected_book_spine.dart';
import 'package:llom/screens/shelf_review_screen.dart';
import 'package:llom/services/bookcase_service.dart';
import 'package:llom/services/book_enrichment_service.dart';

// Minimal 1x1 valid PNG bytes for testing image rendering
final Uint8List kTestPngBytes = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
  0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
  0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5,
  0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
]);

class MockEnrichmentServiceForReview extends BookEnrichmentService {
  String? mockAuthor;

  MockEnrichmentServiceForReview({this.mockAuthor});

  @override
  Future<String?> lookupAuthorByTitle(String title) async {
    return mockAuthor;
  }
}

class MockBookcaseServiceForReview extends BookcaseService {
  bool saveCatalogedShelfCalled = false;
  bool updateRetroactiveShelfCalled = false;
  bool? lastReplaceExisting;
  List<DetectedBookSpine> savedSpines = [];
  List<BookModel> existingShelfBooks = [];
  List<BookModel> lastRetroactiveUpdatedBooks = [];
  String? lastRetroactiveShelfCode;

  @override
  Future<List<BookModel>> updateRetroactiveShelf({
    required String libraryId,
    required String shelfCode,
    required List<BookModel> updatedBooks,
    String? bookcaseId,
  }) async {
    updateRetroactiveShelfCalled = true;
    lastRetroactiveShelfCode = shelfCode;
    lastRetroactiveUpdatedBooks = List.from(updatedBooks);
    return updatedBooks;
  }

  @override
  Future<List<BookModel>> getBooksForShelf(
    String libraryId,
    String bookcaseId,
    int shelfIndex,
  ) async {
    return existingShelfBooks;
  }

  @override
  Future<List<BookModel>> saveCatalogedShelf({
    required String libraryId,
    required BookcaseModel bookcase,
    required int shelfIndex,
    required Uint8List imageBytes,
    required List<DetectedBookSpine> detectedBooks,
    bool replaceExisting = false,
    FirebaseStorage? storageInstance,
  }) async {
    saveCatalogedShelfCalled = true;
    lastReplaceExisting = replaceExisting;
    savedSpines = List.from(detectedBooks);
    final now = DateTime(2026, 9, 16);
    return detectedBooks.asMap().entries.map((e) {
      return BookModel(
        id: 'book_${e.key}',
        title: e.value.title,
        author: e.value.author ?? '',
        shelfCode: '${bookcase.id}-B$shelfIndex',
        bookcaseId: bookcase.id,
        positionIndex: e.key + 1,
        box: e.value.box,
        createdAt: now,
      );
    }).toList();
  }
}

void main() {
  final now = DateTime(2026, 9, 16);
  final testBookcase = BookcaseModel(
    id: 'bc_test_1',
    name: 'Llibreria de Saló',
    room: 'Saló',
    shelfCount: 4,
    bookCount: 5,
    order: 0,
    createdAt: now,
  );

  List<DetectedBookSpine> createTestSpines() => [
    DetectedBookSpine(
      id: 'sp_1',
      title: 'Pedra de tartera',
      author: 'Maria Barbal',
      box: [150, 100, 850, 250],
    ),
    DetectedBookSpine(
      id: 'sp_2',
      title: 'La plaça del Diamant',
      author: 'Mercè Rodoreda',
      box: [120, 270, 880, 420],
    ),
  ];

  Widget createWidget({
    required MockBookcaseServiceForReview mockService,
    List<DetectedBookSpine>? spines,
    List<BookModel>? existingBooks,
    bool isRetroactiveEdit = false,
    Uint8List? imageBytes,
    String? photoUrl,
    BookEnrichmentService? enrichmentService,
  }) {
    return MaterialApp(
      home: ShelfReviewScreen(
        imageBytes: imageBytes ?? (photoUrl != null ? Uint8List(0) : kTestPngBytes),
        photoUrl: photoUrl,
        initialDetectedSpines: spines ?? (isRetroactiveEdit ? const [] : createTestSpines()),
        existingBooks: existingBooks,
        isRetroactiveEdit: isRetroactiveEdit,
        libraryId: 'lib_review_1',
        bookcase: testBookcase,
        shelfIndex: 2,
        bookcaseService: mockService,
        enrichmentService: enrichmentService,
      ),
    );
  }

  group('ShelfReviewScreen widget tests', () {
    testWidgets('Renders header, spine count subtitle and detected book boxes', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();

      await tester.pumpWidget(createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      // Verify title in AppBar
      expect(find.text('Revisió · Balda 2'), findsOneWidget);
      expect(find.text('Llibreria de Saló · 2 lloms detectats'), findsOneWidget);

      // Verify book boxes on image overlay
      expect(find.byKey(const Key('box_sp_1')), findsOneWidget);
      expect(find.byKey(const Key('box_sp_2')), findsOneWidget);
      expect(find.text('Pedra de tartera'), findsWidgets);
      expect(find.text('La plaça del Diamant'), findsWidgets);

      // Verify action button text
      expect(find.text('Desar balda (2 llibres)'), findsOneWidget);
    });

    testWidgets('Tapping a spine box opens edit modal, allows editing and updating', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();

      await tester.pumpWidget(createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      // Tap first spine box
      final firstBox = find.byKey(const Key('box_sp_1'));
      expect(firstBox, findsOneWidget);
      await tester.tap(firstBox);
      await tester.pumpAndSettle();

      // Modal bottom sheet should be open
      expect(find.text('Corregir llom detectat'), findsOneWidget);
      expect(find.text('Títol del llibre *'), findsOneWidget);
      expect(find.text('Autor / Autora (opcional)'), findsOneWidget);

      // Modify title
      final titleField = find.byKey(const Key('field_edit_spine_title'));
      await tester.enterText(titleField, 'Pedra de tartera (Edició Especial)');
      await tester.pumpAndSettle();

      // Tap save
      final saveButton = find.byKey(const Key('btn_save_spine_changes'));
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Modal closed, title updated on box
      expect(find.text('Pedra de tartera (Edició Especial)'), findsWidgets);
    });

    testWidgets('Tapping delete inside edit modal removes false positive spine', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();

      await tester.pumpWidget(createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      expect(find.text('Llibreria de Saló · 2 lloms detectats'), findsOneWidget);

      // Tap second spine box
      final secondBox = find.byKey(const Key('box_sp_2'));
      await tester.tap(secondBox);
      await tester.pumpAndSettle();

      // Tap delete button in modal
      final deleteButton = find.byKey(const Key('btn_delete_spine'));
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Now 1 book left
      expect(find.text('Llibreria de Saló · 1 lloms detectats'), findsOneWidget);
      expect(find.text('Desar balda (1 llibre)'), findsOneWidget);
      expect(find.byKey(const Key('box_sp_2')), findsNothing);
    });

    testWidgets('Adding a manual spine adds a new item to the shelf', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();

      await tester.pumpWidget(createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      final addSpineBtn = find.byKey(const Key('btn_add_spine_manual'));
      expect(addSpineBtn, findsOneWidget);

      await tester.tap(addSpineBtn);
      await tester.pumpAndSettle();

      // Sheet opens
      expect(find.text('Afegir llom manualment'), findsOneWidget);

      final titleField = find.byKey(const Key('field_add_spine_title'));
      final authorField = find.byKey(const Key('field_add_spine_author'));

      await tester.enterText(titleField, 'Tirant lo Blanc');
      await tester.enterText(authorField, 'Joanot Martorell');
      await tester.pumpAndSettle();

      final saveButton = find.byKey(const Key('btn_save_new_spine'));
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Now 3 books
      expect(find.text('Llibreria de Saló · 3 lloms detectats'), findsOneWidget);
      expect(find.text('Tirant lo Blanc'), findsWidgets);
    });

    testWidgets('Tapping Desar balda saves cataloged shelf via BookcaseService and returns true', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();

      await tester.pumpWidget(createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      final saveShelfButton = find.byKey(const Key('btn_save_cataloged_shelf'));
      expect(saveShelfButton, findsOneWidget);

      await tester.tap(saveShelfButton);
      await tester.pumpAndSettle();

      expect(mockService.saveCatalogedShelfCalled, isTrue);
      expect(mockService.savedSpines.length, 2);
      expect(mockService.savedSpines.first.title, 'Pedra de tartera');
      expect(mockService.savedSpines.last.title, 'La plaça del Diamant');
    });

    testWidgets('Renders with photoUrl when imageBytes is empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();

      await tester.pumpWidget(
        MaterialApp(
          home: ShelfReviewScreen(
            imageBytes: Uint8List(0),
            photoUrl: 'https://example.com/mock_shelf.jpg',
            initialDetectedSpines: createTestSpines(),
            libraryId: 'lib_review_1',
            bookcase: testBookcase,
            shelfIndex: 2,
            bookcaseService: mockService,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Revisió · Balda 2'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('Shows replace dialog when shelf has existing books and user chooses to replace', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();
      mockService.existingShelfBooks = [
        BookModel(
          id: 'prev_1',
          title: 'Llibre Antic',
          author: 'Autor',
          shelfCode: 'bc_test_1-B2',
          bookcaseId: 'bc_test_1',
          positionIndex: 1,
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      final saveShelfButton = find.byKey(const Key('btn_save_cataloged_shelf'));
      await tester.tap(saveShelfButton);
      await tester.pumpAndSettle();

      // Dialog should appear
      expect(find.text('Balda amb contingut previ'), findsOneWidget);
      expect(find.text('La balda ja té 1 llibre. Vols substituir-los amb aquesta nova captura o mantenir-los?'), findsOneWidget);

      // Choose to replace
      final replaceButton = find.byKey(const Key('replace_existing_shelf_books_button'));
      await tester.tap(replaceButton);
      await tester.pumpAndSettle();

      expect(mockService.saveCatalogedShelfCalled, isTrue);
      expect(mockService.lastReplaceExisting, isTrue);
    });

    testWidgets('Shows replace dialog when shelf has existing books and user chooses to keep and add', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();
      mockService.existingShelfBooks = [
        BookModel(
          id: 'prev_1',
          title: 'Llibre Antic',
          author: 'Autor',
          shelfCode: 'bc_test_1-B2',
          bookcaseId: 'bc_test_1',
          positionIndex: 1,
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      final saveShelfButton = find.byKey(const Key('btn_save_cataloged_shelf'));
      await tester.tap(saveShelfButton);
      await tester.pumpAndSettle();

      // Choose to keep and add
      final keepButton = find.byKey(const Key('keep_existing_shelf_books_button'));
      await tester.tap(keepButton);
      await tester.pumpAndSettle();

      expect(mockService.saveCatalogedShelfCalled, isTrue);
      expect(mockService.lastReplaceExisting, isFalse);
    });

    testWidgets('Cancelling replace dialog stops saving', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();
      mockService.existingShelfBooks = [
        BookModel(
          id: 'prev_1',
          title: 'Llibre Antic',
          author: 'Autor',
          shelfCode: 'bc_test_1-B2',
          bookcaseId: 'bc_test_1',
          positionIndex: 1,
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      final saveShelfButton = find.byKey(const Key('btn_save_cataloged_shelf'));
      await tester.tap(saveShelfButton);
      await tester.pumpAndSettle();

      // Tap Cancel·lar
      await tester.tap(find.text('Cancel·lar'));
      await tester.pumpAndSettle();

      expect(mockService.saveCatalogedShelfCalled, isFalse);
    });

    testWidgets('Toggling drawing mode button activates drawing layer and updates banner', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();

      await tester.pumpWidget(createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      // Initially, drawing gesture detector is not present
      expect(find.byKey(const Key('gesture_draw_spine')), findsNothing);
      expect(find.textContaining('Toca qualsevol llom per corregir'), findsOneWidget);

      // Tap draw mode toggle button
      final drawBtn = find.byKey(const Key('btn_draw_spine_mode'));
      expect(drawBtn, findsOneWidget);
      await tester.tap(drawBtn);
      await tester.pumpAndSettle();

      // Now drawing layer and banner are active
      expect(find.byKey(const Key('gesture_draw_spine')), findsOneWidget);
      expect(find.textContaining('Mode dibuix actiu'), findsWidgets);

      // Tap again to deactivate
      await tester.tap(drawBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('gesture_draw_spine')), findsNothing);
    });

    testWidgets('Drawing on image in drawing mode triggers add manual spine dialog with coordinates', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();

      await tester.pumpWidget(createWidget(mockService: mockService));
      await tester.pumpAndSettle();

      // Enable drawing mode
      await tester.tap(find.byKey(const Key('btn_draw_spine_mode')));
      await tester.pumpAndSettle();

      final gestureLayer = find.byKey(const Key('gesture_draw_spine'));
      expect(gestureLayer, findsOneWidget);

      // Perform drag gesture on the drawing layer
      await tester.drag(gestureLayer, const Offset(60, 200));
      await tester.pumpAndSettle();

      // Modal bottom sheet should open with title "Catalogar llom marcat"
      expect(find.text('Catalogar llom marcat'), findsOneWidget);
      expect(find.byKey(const Key('field_add_spine_title')), findsOneWidget);
      expect(find.byKey(const Key('field_add_spine_author')), findsOneWidget);

      // Enter book details and save
      await tester.enterText(find.byKey(const Key('field_add_spine_title')), 'Llibre Dibuixat');
      await tester.enterText(find.byKey(const Key('field_add_spine_author')), 'Autor Dibuixat');
      await tester.tap(find.byKey(const Key('btn_save_new_spine')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Modal closed, drawing mode turned off automatically, new spine exists with (Manual)
      expect(find.text('Catalogar llom marcat'), findsNothing);
      expect(find.text('Llibre Dibuixat'), findsWidgets);
      expect(find.text('(Manual)'), findsWidgets);
      expect(find.textContaining('afegit a la posició'), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Adding manual spine interpolates physical order by xmin and renders review chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();

      // Spines at xmin: 100 and xmin: 500
      final initialSpines = [
        DetectedBookSpine(
          id: 'sp_left',
          title: 'Llibre Esquerre',
          author: 'Autor A',
          box: [100, 100, 900, 200],
        ),
        DetectedBookSpine(
          id: 'sp_right',
          title: 'Llibre Dret',
          author: 'Autor B',
          box: [100, 500, 900, 600],
        ),
      ];

      await tester.pumpWidget(createWidget(mockService: mockService, spines: initialSpines));
      await tester.pumpAndSettle();

      // Initial review chips
      expect(find.byKey(const Key('chip_spine_sp_left')), findsOneWidget);
      expect(find.byKey(const Key('chip_spine_sp_right')), findsOneWidget);

      // Tap manual add spine button (default box has xmin: 100, let's open dialog)
      await tester.tap(find.byKey(const Key('btn_add_spine_manual')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('field_add_spine_title')), 'Nou Manual');
      await tester.tap(find.byKey(const Key('btn_save_new_spine')));
      await tester.pumpAndSettle();

      // Verify that the list of spines has 3 items now
      expect(find.text('Desar balda (3 llibres)'), findsOneWidget);
      expect(find.text('(Manual)'), findsWidgets);
    });

    testWidgets('Magic wand in add manual spine auto-fills author via BookEnrichmentService', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();
      final mockEnrichment = MockEnrichmentServiceForReview(mockAuthor: 'Mercè Rodoreda');

      await tester.pumpWidget(createWidget(
        mockService: mockService,
        enrichmentService: mockEnrichment,
      ));
      await tester.pumpAndSettle();

      // Open manual add dialog
      await tester.tap(find.byKey(const Key('btn_add_spine_manual')));
      await tester.pumpAndSettle();

      // Enter title
      await tester.enterText(find.byKey(const Key('field_add_spine_title')), 'Mirall Trencat');

      // Tap auto-fill wand button
      final wandButton = find.byKey(const Key('auto_fill_spine_author'));
      expect(wandButton, findsOneWidget);
      await tester.tap(wandButton);
      await tester.pumpAndSettle();

      // Author field should now be filled with 'Mercè Rodoreda'
      final authorField = tester.widget<TextField>(find.byKey(const Key('field_add_spine_author')));
      expect(authorField.controller?.text, 'Mercè Rodoreda');
      expect(find.textContaining('Mercè Rodoreda'), findsWidgets);
    });

    testWidgets('Retroactive edit mode renders existing books, photoUrl and Desar canvis button', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();
      final existingBooks = [
        BookModel(
          id: 'existing_b1',
          title: 'Incerta glòria',
          author: 'Joan Sales',
          shelfCode: 'bc_test_1-B2',
          bookcaseId: 'bc_test_1',
          positionIndex: 1,
          photoUrl: 'https://example.com/mock_shelf.jpg',
          box: [100, 150, 900, 300],
          createdAt: now,
        ),
        BookModel(
          id: 'existing_b2',
          title: 'Solitud',
          author: 'Víctor Català',
          shelfCode: 'bc_test_1-B2',
          bookcaseId: 'bc_test_1',
          positionIndex: 2,
          photoUrl: 'https://example.com/mock_shelf.jpg',
          box: [100, 320, 900, 480],
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(createWidget(
        mockService: mockService,
        existingBooks: existingBooks,
        isRetroactiveEdit: true,
        photoUrl: 'https://example.com/mock_shelf.jpg',
      ));
      await tester.pumpAndSettle();

      // Capçalera adaptada
      expect(find.text('Edició balda 2'), findsOneWidget);
      expect(find.text('Llibreria de Saló · 2 llibres a la balda'), findsOneWidget);

      // Botó de confirmació
      expect(find.text('Desar canvis a la balda'), findsOneWidget);

      // Llibres existents visibles
      expect(find.text('Incerta glòria'), findsWidgets);
      expect(find.text('Solitud'), findsWidgets);

      // Prémer Desar canvis a la balda
      await tester.tap(find.byKey(const Key('btn_save_cataloged_shelf')));
      await tester.pumpAndSettle();

      // Ha de cridar updateRetroactiveShelf i NO saveCatalogedShelf
      expect(mockService.updateRetroactiveShelfCalled, isTrue);
      expect(mockService.saveCatalogedShelfCalled, isFalse);
      expect(mockService.lastRetroactiveShelfCode, 'bc_test_1-B2');
      expect(mockService.lastRetroactiveUpdatedBooks.length, 2);
      expect(mockService.lastRetroactiveUpdatedBooks[0].id, 'existing_b1');
      expect(mockService.lastRetroactiveUpdatedBooks[1].id, 'existing_b2');
    });

    testWidgets('Retroactive edit mode allows deleting existing book and adding a new manual spine', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForReview();
      final existingBooks = [
        BookModel(
          id: 'existing_b1',
          title: 'Incerta glòria',
          author: 'Joan Sales',
          shelfCode: 'bc_test_1-B2',
          bookcaseId: 'bc_test_1',
          positionIndex: 1,
          photoUrl: 'https://example.com/mock_shelf.jpg',
          box: [100, 150, 900, 300],
          createdAt: now,
        ),
        BookModel(
          id: 'existing_b2',
          title: 'Solitud',
          author: 'Víctor Català',
          shelfCode: 'bc_test_1-B2',
          bookcaseId: 'bc_test_1',
          positionIndex: 2,
          photoUrl: 'https://example.com/mock_shelf.jpg',
          box: [100, 320, 900, 480],
          createdAt: now,
        ),
      ];

      await tester.pumpWidget(createWidget(
        mockService: mockService,
        existingBooks: existingBooks,
        isRetroactiveEdit: true,
        photoUrl: 'https://example.com/mock_shelf.jpg',
      ));
      await tester.pumpAndSettle();

      // Esborrar 'Incerta glòria' obrint el modal de la seva caixa
      await tester.tap(find.byKey(const Key('box_existing_b1')));
      await tester.pumpAndSettle();

      final deleteBtn = find.byKey(const Key('btn_delete_spine'));
      expect(deleteBtn, findsOneWidget);
      await tester.tap(deleteBtn);
      await tester.pumpAndSettle();

      // Afegir un nou llom manual
      await tester.tap(find.byKey(const Key('btn_add_spine_manual')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('field_add_spine_title')), 'Nou Llibre Manual');
      await tester.enterText(find.byKey(const Key('field_add_spine_author')), 'Autor Nou');
      await tester.tap(find.byKey(const Key('btn_save_new_spine')));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      // Desar els canvis a la balda
      await tester.tap(find.byKey(const Key('btn_save_cataloged_shelf')));
      await tester.pumpAndSettle();

      expect(mockService.updateRetroactiveShelfCalled, isTrue);
      final updated = mockService.lastRetroactiveUpdatedBooks;
      expect(updated.length, 2);

      // Comprovar que 'existing_b1' ja no hi és i que 'existing_b2' i el nou sí
      expect(updated.any((b) => b.id == 'existing_b1'), isFalse);
      expect(updated.any((b) => b.id == 'existing_b2'), isTrue);
      expect(updated.any((b) => b.title == 'Nou Llibre Manual'), isTrue);
    });
  });
}
