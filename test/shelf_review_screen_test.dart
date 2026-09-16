import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/models/detected_book_spine.dart';
import 'package:llom/screens/shelf_review_screen.dart';
import 'package:llom/services/bookcase_service.dart';

// Minimal 1x1 valid PNG bytes for testing image rendering
final Uint8List kTestPngBytes = Uint8List.fromList([
  137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82,
  0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137,
  0, 0, 0, 10, 73, 68, 65, 84, 120, 156, 99, 0, 1, 0, 0, 5,
  0, 1, 13, 10, 45, 180, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
]);

class MockBookcaseServiceForReview extends BookcaseService {
  bool saveCatalogedShelfCalled = false;
  List<DetectedBookSpine> savedSpines = [];

  @override
  Future<List<BookModel>> saveCatalogedShelf({
    required String libraryId,
    required BookcaseModel bookcase,
    required int shelfIndex,
    required Uint8List imageBytes,
    required List<DetectedBookSpine> detectedBooks,
    FirebaseStorage? storageInstance,
  }) async {
    saveCatalogedShelfCalled = true;
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
  }) {
    return MaterialApp(
      home: ShelfReviewScreen(
        imageBytes: kTestPngBytes,
        initialDetectedSpines: spines ?? createTestSpines(),
        libraryId: 'lib_review_1',
        bookcase: testBookcase,
        shelfIndex: 2,
        bookcaseService: mockService,
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
  });
}
