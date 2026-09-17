import 'package:flutter_test/flutter_test.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/services/library_stats_service.dart';

void main() {
  group('LibraryStatsService tests', () {
    test('calculateStats returns zeroed stats for empty list', () {
      final stats = LibraryStatsService.calculateStats([]);
      expect(stats.isEmpty, isTrue);
      expect(stats.totalBooks, 0);
      expect(stats.borrowedBooksCount, 0);
      expect(stats.totalPages, 0);
      expect(stats.averagePages, 0);
      expect(stats.averageYear, isNull);
      expect(stats.oldestBook, isNull);
      expect(stats.longestBook, isNull);
      expect(stats.topAuthors, isEmpty);
      expect(stats.enrichedBooksCount, 0);
      expect(stats.booksByDecade['<1980'], 0);
    });

    test('calculates pages, oldest book, longest book and borrowed count correctly', () {
      final books = [
        BookModel(
          id: 'b1',
          title: 'Tirant lo Blanc',
          author: 'Joanot Martorell',
          shelfCode: 'E1-B1',
          positionIndex: 1,
          pageCount: 840,
          publishedYear: '1490',
          isBorrowed: true,
          createdAt: DateTime(2026, 1, 1),
        ),
        BookModel(
          id: 'b2',
          title: 'Solitud',
          author: 'Víctor Català',
          shelfCode: 'E1-B1',
          positionIndex: 2,
          pageCount: 280,
          publishedYear: '1905',
          isBorrowed: false,
          createdAt: DateTime(2026, 1, 1),
        ),
        BookModel(
          id: 'b3',
          title: 'La plaça del Diamant',
          author: 'Mercè Rodoreda',
          shelfCode: 'E1-B2',
          positionIndex: 1,
          pageCount: 250,
          publishedYear: '1962',
          synopsis: 'La història de la Colometa.',
          isBorrowed: false,
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

      final stats = LibraryStatsService.calculateStats(books);
      expect(stats.isEmpty, isFalse);
      expect(stats.totalBooks, 3);
      expect(stats.borrowedBooksCount, 1);
      expect(stats.totalPages, 840 + 280 + 250); // 1370
      expect(stats.averagePages, (1370 / 3).round()); // 457
      expect(stats.longestBook?.id, 'b1');
      expect(stats.longestBook?.pageCount, 840);
      expect(stats.oldestBook?.id, 'b1');
      expect(stats.oldestBook?.publishedYear, '1490');
      expect(stats.enrichedBooksCount, 1);
    });

    test('calculates topAuthors filtering out empty/unknown and sorting descending', () {
      final books = [
        BookModel(id: '1', title: 'L1', author: 'Mercè Rodoreda', shelfCode: 'E1-B1', positionIndex: 1, createdAt: DateTime.now()),
        BookModel(id: '2', title: 'L2', author: 'Mercè Rodoreda', shelfCode: 'E1-B1', positionIndex: 2, createdAt: DateTime.now()),
        BookModel(id: '3', title: 'L3', author: 'Mercè Rodoreda', shelfCode: 'E1-B1', positionIndex: 3, createdAt: DateTime.now()),
        BookModel(id: '4', title: 'L4', author: 'Pere Calders', shelfCode: 'E1-B1', positionIndex: 4, createdAt: DateTime.now()),
        BookModel(id: '5', title: 'L5', author: 'Pere Calders', shelfCode: 'E1-B1', positionIndex: 5, createdAt: DateTime.now()),
        BookModel(id: '6', title: 'L6', author: 'Joan Fuster', shelfCode: 'E1-B1', positionIndex: 6, createdAt: DateTime.now()),
        BookModel(id: '7', title: 'L7', author: 'Sense autor', shelfCode: 'E1-B1', positionIndex: 7, createdAt: DateTime.now()),
        BookModel(id: '8', title: 'L8', author: 'Desconegut', shelfCode: 'E1-B1', positionIndex: 8, createdAt: DateTime.now()),
        BookModel(id: '9', title: 'L9', author: '', shelfCode: 'E1-B1', positionIndex: 9, createdAt: DateTime.now()),
      ];

      final stats = LibraryStatsService.calculateStats(books);
      expect(stats.topAuthors.length, 3);
      expect(stats.topAuthors[0].key, 'Mercè Rodoreda');
      expect(stats.topAuthors[0].value, 3);
      expect(stats.topAuthors[1].key, 'Pere Calders');
      expect(stats.topAuthors[1].value, 2);
      expect(stats.topAuthors[2].key, 'Joan Fuster');
      expect(stats.topAuthors[2].value, 1);
    });

    test('groups books correctly by decade and calculates averageYear', () {
      final books = [
        BookModel(id: '1', title: 'L1', author: 'A', shelfCode: 'E1-B1', positionIndex: 1, publishedYear: '1975', createdAt: DateTime.now()),
        BookModel(id: '2', title: 'L2', author: 'A', shelfCode: 'E1-B1', positionIndex: 2, publishedYear: '1984', createdAt: DateTime.now()),
        BookModel(id: '3', title: 'L3', author: 'A', shelfCode: 'E1-B1', positionIndex: 3, publishedYear: '1995-09-01', createdAt: DateTime.now()),
        BookModel(id: '4', title: 'L4', author: 'A', shelfCode: 'E1-B1', positionIndex: 4, publishedYear: '2005', createdAt: DateTime.now()),
        BookModel(id: '5', title: 'L5', author: 'A', shelfCode: 'E1-B1', positionIndex: 5, publishedYear: '2018', createdAt: DateTime.now()),
        BookModel(id: '6', title: 'L6', author: 'A', shelfCode: 'E1-B1', positionIndex: 6, publishedYear: '2023', createdAt: DateTime.now()),
      ];

      final stats = LibraryStatsService.calculateStats(books);
      expect(stats.booksByDecade['<1980'], 1);
      expect(stats.booksByDecade['1980-1989'], 1);
      expect(stats.booksByDecade['1990-1999'], 1);
      expect(stats.booksByDecade['2000-2009'], 1);
      expect(stats.booksByDecade['2010-2019'], 1);
      expect(stats.booksByDecade['2020+'], 1);

      // (1975 + 1984 + 1995 + 2005 + 2018 + 2023) / 6 = 12000 / 6 = 2000
      expect(stats.averageYear, 2000);
    });
  });
}
