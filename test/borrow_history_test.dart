import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/models/loan_record.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/services/bookcase_service.dart';
import 'package:llom/widgets/book_detail_bottom_sheet.dart';
import 'package:provider/provider.dart';

class MockLibraryProviderForBorrow extends ChangeNotifier implements LibraryProvider {
  @override
  UserModel? currentUser;

  @override
  LibraryModel? activeLibrary;

  MockLibraryProviderForBorrow({
    this.currentUser,
    this.activeLibrary,
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  group('LoanRecord model tests', () {
    test('durationInDays calculates correct difference for completed loans', () {
      final record = LoanRecord(
        id: 'rec_1',
        borrowedTo: 'Anna',
        borrowedAt: DateTime(2026, 9, 1),
        returnedAt: DateTime(2026, 9, 6),
      );

      expect(record.durationInDays, equals(5));
      expect(record.borrowedTo, equals('Anna'));
    });

    test('durationInDays returns non-negative days for active loan', () {
      final record = LoanRecord(
        id: 'rec_2',
        borrowedTo: 'Marc',
        borrowedAt: DateTime.now().subtract(const Duration(days: 3)),
        returnedAt: null,
      );

      expect(record.durationInDays, greaterThanOrEqualTo(3));
    });

    test('toMap and fromMap serialize and deserialize accurately', () {
      final now = DateTime(2026, 9, 17, 10, 30);
      final record = LoanRecord(
        id: 'rec_3',
        borrowedTo: 'Clara',
        borrowedAt: now,
        returnedAt: now.add(const Duration(days: 10)),
      );

      final map = record.toMap();
      expect(map['id'], equals('rec_3'));
      expect(map['borrowedTo'], equals('Clara'));
      expect(map['borrowedAt'], isA<Timestamp>());
      expect(map['returnedAt'], isA<Timestamp>());

      final deserialized = LoanRecord.fromMap(map, 'rec_3');
      expect(deserialized.id, equals(record.id));
      expect(deserialized.borrowedTo, equals(record.borrowedTo));
      expect(deserialized.borrowedAt, equals(record.borrowedAt));
      expect(deserialized.returnedAt, equals(record.returnedAt));
    });

    test('fromMap tolerates legacy formats and missing returnedAt', () {
      final map = {
        'id': 'rec_legacy',
        'borrowedTo': 'Pere',
        'borrowedAt': '2026-09-10T12:00:00Z',
      };

      final record = LoanRecord.fromMap(map);
      expect(record.id, equals('rec_legacy'));
      expect(record.borrowedTo, equals('Pere'));
      expect(record.returnedAt, isNull);
    });

    test('copyWith works as expected', () {
      final record = LoanRecord(
        id: 'rec_orig',
        borrowedTo: 'Jordi',
        borrowedAt: DateTime(2026, 9, 1),
      );

      final returnDate = DateTime(2026, 9, 5);
      final updated = record.copyWith(returnedAt: returnDate);

      expect(updated.id, equals('rec_orig'));
      expect(updated.borrowedTo, equals('Jordi'));
      expect(updated.returnedAt, equals(returnDate));
    });
  });

  group('BookModel & LibraryModel with loan fields', () {
    test('BookModel serializes and parses loanHistory', () {
      final loan = LoanRecord(
        id: 'loan_1',
        borrowedTo: 'Laura',
        borrowedAt: DateTime(2026, 9, 1),
        returnedAt: DateTime(2026, 9, 7),
      );

      final book = BookModel(
        id: 'b1',
        title: 'Tirant lo Blanc',
        author: 'Joanot Martorell',
        shelfCode: 'bc1-B1',
        positionIndex: 1,
        loanHistory: [loan],
        createdAt: DateTime(2026, 9, 1),
      );

      final map = book.toMap();
      expect(map['loanHistory'], isA<List>());
      expect((map['loanHistory'] as List).length, equals(1));

      final restored = BookModel.fromMap(map, 'b1');
      expect(restored.loanHistory.length, equals(1));
      expect(restored.loanHistory.first.borrowedTo, equals('Laura'));
      expect(restored.loanHistory.first.durationInDays, equals(6));
    });

    test('BookModel backward compatibility when loanHistory is absent', () {
      final map = {
        'title': 'Llibre Antic',
        'author': 'Autor',
        'shelfCode': 'bc1-B1',
        'positionIndex': 0,
        'createdAt': DateTime(2026, 1, 1),
      };

      final book = BookModel.fromMap(map, 'b_legacy');
      expect(book.loanHistory, isEmpty);
    });

    test('LibraryModel parses frequentBorrowers', () {
      final map = {
        'id': 'lib_1',
        'name': 'Biblioteca Familiar',
        'ownerId': 'u1',
        'inviteCode': 'ABC123',
        'members': {'u1': 'owner'},
        'memberUids': ['u1'],
        'frequentBorrowers': ['Maria', 'Joan', 'Pol'],
        'createdAt': DateTime(2026, 1, 1),
      };

      final lib = LibraryModel.fromMap(map, 'lib_1');
      expect(lib.frequentBorrowers, equals(['Maria', 'Joan', 'Pol']));

      final exported = lib.toMap();
      expect(exported['frequentBorrowers'], equals(['Maria', 'Joan', 'Pol']));
    });
  });

  group('BookcaseService toggleBookBorrowedStatus validation', () {
    test('throws ArgumentError on empty IDs', () {
      final service = BookcaseService();
      expect(
        () => service.toggleBookBorrowedStatus(
          libraryId: '',
          bookId: 'b1',
          isBorrowed: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => service.toggleBookBorrowedStatus(
          libraryId: 'lib1',
          bookId: '   ',
          isBorrowed: false,
        ),
        throwsArgumentError,
      );
    });
  });

  group('UI: Borrow Dialog & Loan History BottomSheet', () {
    final testBookcase = BookcaseModel(
      id: 'bc1',
      name: 'Llibreria Saló',
      room: 'Saló',
      shelfCount: 4,
      bookCount: 1,
      createdAt: DateTime(2026, 1, 1),
    );

    testWidgets('shows Loan History button when loanHistory is not empty and opens sheet', (tester) async {
      final completedLoan = LoanRecord(
        id: 'hist_1',
        borrowedTo: 'Arnau',
        borrowedAt: DateTime(2026, 8, 1),
        returnedAt: DateTime(2026, 8, 8),
      );

      final bookWithHistory = BookModel(
        id: 'book_hist',
        title: 'Història de la Literatura',
        author: 'Martí de Riquer',
        shelfCode: 'bc1-B1',
        positionIndex: 1,
        isBorrowed: false,
        loanHistory: [completedLoan],
        createdAt: DateTime(2026, 8, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookDetailBottomSheet(
              book: bookWithHistory,
              bookcase: testBookcase,
              libraryId: 'lib_test',
              canEdit: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Botó visible
      final historyButton = find.byKey(const Key('loan_history_button'));
      expect(historyButton, findsOneWidget);
      expect(find.text('Historial de préstecs (1)'), findsOneWidget);

      // Prémer el botó per obrir el modal
      await tester.tap(historyButton);
      await tester.pumpAndSettle();

      // Verificar contingut del modal d'historial
      expect(find.byKey(const Key('loan_history_sheet')), findsOneWidget);
      expect(find.text('Arnau'), findsOneWidget);
      expect(find.text('7 dies'), findsOneWidget);

      // Tancar el modal
      await tester.tap(find.byKey(const Key('close_loan_history_button')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('loan_history_sheet')), findsNothing);
    });

    testWidgets('borrow dialog renders suggestion chips and updates textfield on tap', (tester) async {
      final testBook = BookModel(
        id: 'book_simple',
        title: 'La plaça del Diamant',
        author: 'Mercè Rodoreda',
        shelfCode: 'bc1-B1',
        positionIndex: 1,
        isBorrowed: false,
        createdAt: DateTime(2026, 9, 1),
      );

      final mockProvider = MockLibraryProviderForBorrow(
        currentUser: UserModel(
          uid: 'u_tester',
          email: 'test@llom.cat',
          displayName: 'Enric Tester',
          createdAt: DateTime(2026, 1, 1),
        ),
        activeLibrary: LibraryModel(
          id: 'lib_test',
          name: 'Biblioteca Central',
          ownerId: 'u_tester',
          inviteCode: 'TEST99',
          members: {'u_tester': 'owner'},
          memberUids: ['u_tester'],
          frequentBorrowers: ['Berta', 'Jofre'],
          createdAt: DateTime(2026, 1, 1),
        ),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<LibraryProvider>.value(
          value: mockProvider,
          child: MaterialApp(
            home: Scaffold(
              body: BookDetailBottomSheet(
                book: testBook,
                bookcase: testBookcase,
                libraryId: 'lib_test',
                canEdit: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Obrir diàleg de préstec
      final borrowButton = find.byKey(const Key('borrow_book_button'));
      expect(borrowButton, findsOneWidget);
      await tester.tap(borrowButton);
      await tester.pumpAndSettle();

      // Verificar camps del diàleg
      expect(find.byKey(const Key('borrowed_to_text_field')), findsOneWidget);
      expect(find.byKey(const Key('borrow_date_picker_button')), findsOneWidget);
      expect(find.byKey(const Key('confirm_borrow_button')), findsOneWidget);

      // Verificar xips de suggeriments (frequentBorrowers i currentUser)
      expect(find.byKey(const Key('borrow_chip_Berta')), findsOneWidget);
      expect(find.byKey(const Key('borrow_chip_Jofre')), findsOneWidget);
      expect(find.byKey(const Key('borrow_chip_Enric Tester')), findsOneWidget);

      // Prémer el xip 'Berta'
      await tester.tap(find.byKey(const Key('borrow_chip_Berta')));
      await tester.pumpAndSettle();

      // Comprovar que el camp s'ha omplert amb 'Berta'
      final textField = tester.widget<TextField>(find.byKey(const Key('borrowed_to_text_field')));
      expect(textField.controller?.text, equals('Berta'));

      // Cancel·lar diàleg
      await tester.tap(find.text('Cancel·lar'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('borrowed_to_text_field')), findsNothing);
    });

    testWidgets('borrow dialog date picker button opens calendar dialog', (tester) async {
      final testBook = BookModel(
        id: 'book_date_test',
        title: 'Mirall trencat',
        author: 'Mercè Rodoreda',
        shelfCode: 'bc1-B1',
        positionIndex: 1,
        isBorrowed: false,
        createdAt: DateTime(2026, 9, 1),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BookDetailBottomSheet(
              book: testBook,
              bookcase: testBookcase,
              libraryId: 'lib_test',
              canEdit: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('borrow_book_button')));
      await tester.pumpAndSettle();

      // Clicar botó de data i hora
      await tester.tap(find.byKey(const Key('borrow_date_picker_button')));
      await tester.pumpAndSettle();

      // Es mostra el diàleg de selecció de data (DatePicker)
      expect(find.byType(DatePickerDialog), findsOneWidget);

      // Cancel·lar el selector de data
      final cancelDatePicker = find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('Cancel·lar'),
      );
      await tester.tap(cancelDatePicker);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsNothing);
      expect(find.byKey(const Key('confirm_borrow_button')), findsOneWidget);
    });
  });
}
