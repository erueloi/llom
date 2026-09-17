import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/screens/bookshelf_detail_screen.dart';
import 'package:llom/screens/shelf_review_screen.dart';
import 'package:llom/services/bookcase_service.dart';

class MockBookcaseServiceForDetail extends BookcaseService {
  final List<BookcaseModel> bookcases;
  final List<BookModel> books;
  int? lastClearedShelfIndex;

  MockBookcaseServiceForDetail({required this.bookcases, required this.books});

  @override
  Stream<List<BookcaseModel>> getBookcases(String libraryId) {
    return Stream.value(bookcases);
  }

  @override
  Stream<List<BookModel>> getBooksForBookcase(String libraryId, String bookcaseId) {
    return Stream.value(books.where((b) => b.bookcaseId == bookcaseId).toList());
  }

  @override
  Future<void> clearShelf(String libraryId, String bookcaseId, int shelfIndex) async {
    lastClearedShelfIndex = shelfIndex;
  }
}

class MockLibraryProviderForDetail extends LibraryProvider {
  MockLibraryProviderForDetail({required UserModel user, required LibraryModel library}) {
    currentUser = user;
    activeLibrary = library;
  }
}

void main() {
  final now = DateTime(2026, 9, 15);
  final testBookcase = BookcaseModel(
    id: 'bc_detail_1',
    name: 'Llibreria de Roure',
    room: 'Despatx',
    shelfCount: 3,
    bookCount: 2,
    order: 0,
    createdAt: now,
  );

  final testBooks = [
    BookModel(
      id: 'b1',
      title: 'Pedra de tartera',
      author: 'Maria Barbal',
      shelfCode: 'bc_detail_1-B1',
      bookcaseId: 'bc_detail_1',
      positionIndex: 1,
      createdAt: now,
    ),
    BookModel(
      id: 'b2',
      title: 'La plaça del Diamant',
      author: 'Mercè Rodoreda',
      shelfCode: 'bc_detail_1-B2',
      bookcaseId: 'bc_detail_1',
      positionIndex: 1,
      createdAt: now,
    ),
  ];

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

  Widget createWidget({required BookcaseService service}) {
    return ChangeNotifierProvider<LibraryProvider>(
      create: (_) => MockLibraryProviderForDetail(user: testUser, library: testLib),
      child: MaterialApp(
        home: BookshelfDetailScreen(
          bookcase: testBookcase,
          libraryId: 'lib_test',
          bookcaseService: service,
        ),
      ),
    );
  }

  group('BookshelfDetailScreen tests', () {
    testWidgets('Renders bookcase title, vertical shelves and books', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForDetail(
        bookcases: [testBookcase],
        books: testBooks,
      );

      await tester.pumpWidget(createWidget(service: mockService));
      await tester.pumpAndSettle();

      // Verify title and room info
      expect(find.text('Llibreria de Roure'), findsOneWidget);
      expect(find.text('Despatx · 3 baldes · 2 llibres'), findsOneWidget);

      // Verify 3 shelves are listed vertically with clean headers and positions
      expect(find.text('Balda 1 · Superior'), findsOneWidget);
      expect(find.text('Balda 2 · Intermèdia'), findsOneWidget);
      expect(find.text('Balda 3 · Inferior'), findsOneWidget);

      // Shelf 1 and 2 have 1 book each, Shelf 3 has 0 llibres
      expect(find.text('1 llibre'), findsNWidgets(2));
      expect(find.text('0 llibres'), findsOneWidget);

      // Books should be visible
      expect(find.text('Pedra de tartera'), findsOneWidget);
      expect(find.text('La plaça del Diamant'), findsOneWidget);

      // Empty shelf has ghost spine
      expect(find.byKey(const Key('ghost_spine_3')), findsOneWidget);
      expect(find.text('Afegir llibre / foto'), findsOneWidget);
    });

    testWidgets('FAB opens actions sheet with Fotografiar balda and Afegir llibre manualment', (tester) async {
      final mockService = MockBookcaseServiceForDetail(
        bookcases: [testBookcase],
        books: testBooks,
      );

      await tester.pumpWidget(createWidget(service: mockService));
      await tester.pumpAndSettle();

      final fab = find.byKey(const Key('bookshelf_actions_fab'));
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('Afegir contingut a l\'estanteria'), findsOneWidget);
      expect(find.text('Fotografiar balda'), findsOneWidget);
      expect(find.text('Afegir llibre manualment'), findsOneWidget);

      // Tap 'Afegir llibre manualment'
      await tester.tap(find.byKey(const Key('action_manual_book')));
      await tester.pumpAndSettle();

      // Verify AddManualBookDialog appears
      expect(find.text('Afegir llibre'), findsOneWidget);
      expect(find.text('Títol del llibre *'), findsOneWidget);
    });

    testWidgets('FAB Fotografiar balda opens shelf selection and capture source sheet', (tester) async {
      final mockService = MockBookcaseServiceForDetail(
        bookcases: [testBookcase],
        books: testBooks,
      );

      await tester.pumpWidget(createWidget(service: mockService));
      await tester.pumpAndSettle();

      final fab = find.byKey(const Key('bookshelf_actions_fab'));
      await tester.tap(fab);
      await tester.pumpAndSettle();

      // Tap Fotografiar balda
      await tester.tap(find.byKey(const Key('action_camera_shelf')));
      await tester.pumpAndSettle();

      // Since shelfCount is 3, shelf selection sheet should appear
      expect(find.text('Quina balda vols fotografiar?'), findsOneWidget);
      expect(find.byKey(const Key('select_shelf_camera_1')), findsOneWidget);
      expect(find.byKey(const Key('select_shelf_camera_2')), findsOneWidget);
      expect(find.byKey(const Key('select_shelf_camera_3')), findsOneWidget);

      // Select Balda 2
      await tester.tap(find.byKey(const Key('select_shelf_camera_2')));
      await tester.pumpAndSettle();

      // Capture source sheet should appear
      expect(find.text('Fotografiar Balda 2'), findsOneWidget);
      expect(find.text('Fer foto amb la càmera'), findsOneWidget);
      expect(find.text('Triar de la galeria'), findsOneWidget);
    });

    testWidgets('Shelf header camera button directly opens capture source sheet for that shelf', (tester) async {
      final mockService = MockBookcaseServiceForDetail(
        bookcases: [testBookcase],
        books: testBooks,
      );

      await tester.pumpWidget(createWidget(service: mockService));
      await tester.pumpAndSettle();

      // Tap camera button on Balda 1
      final shelfCamBtn = find.byKey(const Key('shelf_camera_button_1'));
      expect(shelfCamBtn, findsOneWidget);

      await tester.tap(shelfCamBtn);
      await tester.pumpAndSettle();

      expect(find.text('Fotografiar Balda 1'), findsOneWidget);
      expect(find.byKey(const Key('capture_option_camera')), findsOneWidget);
      expect(find.byKey(const Key('capture_option_gallery')), findsOneWidget);
    });

    testWidgets('Shelf photo button is displayed when shelf has photoUrl and opens viewer dialog', (tester) async {
      final booksWithPhoto = [
        BookModel(
          id: 'b1_photo',
          title: 'Pedra de tartera',
          author: 'Maria Barbal',
          shelfCode: 'bc_detail_1-B1',
          bookcaseId: 'bc_detail_1',
          positionIndex: 1,
          photoUrl: 'https://example.com/balda1_full.jpg',
          createdAt: now,
        ),
        BookModel(
          id: 'b2_no_photo',
          title: 'La plaça del Diamant',
          author: 'Mercè Rodoreda',
          shelfCode: 'bc_detail_1-B2',
          bookcaseId: 'bc_detail_1',
          positionIndex: 1,
          createdAt: now,
        ),
      ];

      final mockService = MockBookcaseServiceForDetail(
        bookcases: [testBookcase],
        books: booksWithPhoto,
      );

      await tester.pumpWidget(createWidget(service: mockService));
      await tester.pumpAndSettle();

      // Balda 1 té llibre amb photoUrl -> ha de mostrar el botó de veure fotografia
      final photoBtn1 = find.byKey(const Key('shelf_photo_button_1'));
      expect(photoBtn1, findsOneWidget);

      // Balda 2 NO té cap llibre amb photoUrl -> no ha de mostrar el botó
      final photoBtn2 = find.byKey(const Key('shelf_photo_button_2'));
      expect(photoBtn2, findsNothing);

      // Prémer el botó de veure fotografia de la Balda 1
      await tester.tap(photoBtn1);
      await tester.pump(); // Inicia obertura de diàleg

      // Comprovar elements del diàleg de visor de fotografia de balda
      expect(find.text('Balda 1 · Superior'), findsWidgets);
      expect(find.text('Llibreria de Roure'), findsWidgets);
      expect(find.byType(InteractiveViewer), findsOneWidget);

      final editDetectionBtn = find.byKey(const Key('btn_edit_shelf_detection'));
      expect(editDetectionBtn, findsOneWidget);
      expect(find.text('Editar detecció / Afegir llibre'), findsOneWidget);

      final closeBtn = find.byKey(const Key('close_shelf_photo_dialog'));
      expect(closeBtn, findsOneWidget);

      // Tancar el diàleg
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('close_shelf_photo_dialog')), findsNothing);
    });

    testWidgets('Tapping Editar detecció / Afegir llibre in shelf photo viewer navigates to ShelfReviewScreen in retroactive edit mode', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final booksWithPhoto = [
        testBooks[0].copyWith(photoUrl: 'https://example.com/shelf1.jpg'),
        testBooks[1],
      ];

      final mockService = MockBookcaseServiceForDetail(
        bookcases: [testBookcase],
        books: booksWithPhoto,
      );

      await tester.pumpWidget(createWidget(service: mockService));
      await tester.pumpAndSettle();

      // Tap shelf photo button to open dialog
      await tester.tap(find.byKey(const Key('shelf_photo_button_1')));
      await tester.pumpAndSettle();

      final editBtn = find.byKey(const Key('btn_edit_shelf_detection'));
      expect(editBtn, findsOneWidget);

      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Verify ShelfReviewScreen opened in retroactive mode
      expect(find.byType(ShelfReviewScreen), findsOneWidget);
      expect(find.text('Desar canvis a la balda'), findsOneWidget);
      expect(find.text('Edició balda 1'), findsOneWidget);
    });

    testWidgets('Tapping ghost spine opens empty shelf options sheet and provides options to capture or add manual book', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForDetail(
        bookcases: [testBookcase],
        books: testBooks, // Balda 1 té b1, Balda 2 té b2, Balda 3 és buida
      );

      await tester.pumpWidget(createWidget(service: mockService));
      await tester.pumpAndSettle();

      // Balda 3 és buida, té ghost spine
      final ghostSpine3 = find.byKey(const Key('ghost_spine_3'));
      expect(ghostSpine3, findsOneWidget);

      await tester.tap(ghostSpine3);
      await tester.pumpAndSettle();

      expect(find.text('Afegir a la Balda 3'), findsOneWidget);
      expect(find.byKey(const Key('empty_shelf_option_camera_3')), findsOneWidget);
      expect(find.byKey(const Key('empty_shelf_option_manual_3')), findsOneWidget);
    });

    testWidgets('Shelf clear button is shown on non-empty shelf, opens confirmation dialog and clears shelf', (tester) async {
      tester.view.physicalSize = const Size(1200, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockService = MockBookcaseServiceForDetail(
        bookcases: [testBookcase],
        books: testBooks, // Balda 1 i 2 tenen llibres, Balda 3 buida
      );

      await tester.pumpWidget(createWidget(service: mockService));
      await tester.pumpAndSettle();

      // Balda 1 té llibres -> botó de buidar visible
      final clearBtn1 = find.byKey(const Key('shelf_clear_button_1'));
      expect(clearBtn1, findsOneWidget);

      // Balda 3 és buida -> botó de buidar NO ha de ser-hi
      final clearBtn3 = find.byKey(const Key('shelf_clear_button_3'));
      expect(clearBtn3, findsNothing);

      // Prémer botó de buidar balda 1
      await tester.tap(clearBtn1);
      await tester.pumpAndSettle();

      expect(find.text('Buidar Balda 1'), findsOneWidget);
      expect(find.text('Vols buidar la Balda 1? S\'eliminaran els 1 llibre d\'aquest prestatge.'), findsOneWidget);

      // Confirmar buidat
      final confirmBtn = find.byKey(const Key('confirm_clear_shelf_button'));
      expect(confirmBtn, findsOneWidget);

      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      expect(mockService.lastClearedShelfIndex, 1);
      expect(find.text('S\'ha buidat la Balda 1.'), findsOneWidget);
    });
  });
}

