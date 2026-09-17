import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/models/detected_book_spine.dart';
import 'package:llom/services/bookcase_service.dart';

void main() {
  group('BookcaseService validation tests', () {
    final service = BookcaseService();

    test('getBooksForShelf returns empty list if libraryId or bookcaseId is empty', () async {
      expect(await service.getBooksForShelf('', 'bc_1', 1), isEmpty);
      expect(await service.getBooksForShelf('   ', 'bc_1', 1), isEmpty);
      expect(await service.getBooksForShelf('lib_1', '', 1), isEmpty);
      expect(await service.getBooksForShelf('lib_1', '   ', 1), isEmpty);
    });

    test('clearShelf throws ArgumentError if libraryId or bookcaseId is empty', () async {
      expect(
        () => service.clearShelf('', 'bc_1', 1),
        throwsArgumentError,
      );
      expect(
        () => service.clearShelf('lib_1', '', 1),
        throwsArgumentError,
      );
    });

    test('saveCatalogedShelf throws ArgumentError if libraryId is empty', () async {
      final bookcase = BookcaseModel(
        id: 'bc_1',
        name: 'Llibreria',
        room: 'Estudi',
        shelfCount: 3,
        bookCount: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(
        () => service.saveCatalogedShelf(
          libraryId: '',
          bookcase: bookcase,
          shelfIndex: 1,
          imageBytes: Uint8List(0),
          detectedBooks: [
            DetectedBookSpine(
              id: 'sp_1',
              title: 'Llibre Test',
              box: [100, 100, 900, 200],
            ),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('addBookcase throws ArgumentError if libraryId is empty', () async {
      final bookcase = BookcaseModel(
        id: 'bc_1',
        name: 'Llibreria',
        room: 'Estudi',
        shelfCount: 3,
        bookCount: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      expect(
        () => service.addBookcase('', bookcase),
        throwsArgumentError,
      );
    });

    test('updateBookcase throws ArgumentError if libraryId, bookcaseId or name is empty', () async {
      expect(
        () => service.updateBookcase('', 'bc_1', name: 'Nou Nom'),
        throwsArgumentError,
      );
      expect(
        () => service.updateBookcase('lib_1', '', name: 'Nou Nom'),
        throwsArgumentError,
      );
      expect(
        () => service.updateBookcase('lib_1', 'bc_1', name: ''),
        throwsArgumentError,
      );
    });

    test('updateShelfBooksOrder validates libraryId and handles empty list gracefully', () async {
      expect(
        () => service.updateShelfBooksOrder(libraryId: '', books: []),
        throwsArgumentError,
      );
      expect(
        () => service.updateShelfBooksOrder(libraryId: '   ', books: []),
        throwsArgumentError,
      );

      // Empty books list returns without error
      await service.updateShelfBooksOrder(libraryId: 'lib_1', books: []);
    });

    test('updateRetroactiveShelf validates libraryId and shelfCode', () async {
      expect(
        () => service.updateRetroactiveShelf(
          libraryId: '',
          shelfCode: 'bc_1-B1',
          updatedBooks: [],
        ),
        throwsArgumentError,
      );
      expect(
        () => service.updateRetroactiveShelf(
          libraryId: '   ',
          shelfCode: 'bc_1-B1',
          updatedBooks: [],
        ),
        throwsArgumentError,
      );
      expect(
        () => service.updateRetroactiveShelf(
          libraryId: 'lib_1',
          shelfCode: '',
          updatedBooks: [],
        ),
        throwsArgumentError,
      );
      expect(
        () => service.updateRetroactiveShelf(
          libraryId: 'lib_1',
          shelfCode: '   ',
          updatedBooks: [],
        ),
        throwsArgumentError,
      );
    });

    test('toggleBookBorrowedStatus validates libraryId and bookId', () async {
      expect(
        () => service.toggleBookBorrowedStatus(
          libraryId: '',
          bookId: 'b_1',
          isBorrowed: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => service.toggleBookBorrowedStatus(
          libraryId: '   ',
          bookId: 'b_1',
          isBorrowed: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => service.toggleBookBorrowedStatus(
          libraryId: 'lib_1',
          bookId: '',
          isBorrowed: true,
        ),
        throwsArgumentError,
      );
      expect(
        () => service.toggleBookBorrowedStatus(
          libraryId: 'lib_1',
          bookId: '   ',
          isBorrowed: true,
        ),
        throwsArgumentError,
      );
    });
  });
}
