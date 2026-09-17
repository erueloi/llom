import '../models/book_model.dart';

/// Dades estadístiques consolidades d'una biblioteca o estanteria
class LibraryStats {
  final int totalBooks;
  final int borrowedBooksCount;
  final int totalPages;
  final int averagePages;
  final int? averageYear;
  final BookModel? oldestBook;
  final BookModel? longestBook;
  final List<MapEntry<String, int>> topAuthors;
  final Map<String, int> booksByDecade;
  final int enrichedBooksCount;

  const LibraryStats({
    required this.totalBooks,
    required this.borrowedBooksCount,
    required this.totalPages,
    required this.averagePages,
    this.averageYear,
    this.oldestBook,
    this.longestBook,
    required this.topAuthors,
    required this.booksByDecade,
    required this.enrichedBooksCount,
  });

  bool get isEmpty => totalBooks == 0;
}

/// Servei per calcular mètriques i distribucions d'una col·lecció de llibres
class LibraryStatsService {
  /// Calcula totes les mètriques a partir d'una llista de llibres
  static LibraryStats calculateStats(List<BookModel> books) {
    if (books.isEmpty) {
      return const LibraryStats(
        totalBooks: 0,
        borrowedBooksCount: 0,
        totalPages: 0,
        averagePages: 0,
        averageYear: null,
        oldestBook: null,
        longestBook: null,
        topAuthors: [],
        booksByDecade: {
          '<1980': 0,
          '1980-1989': 0,
          '1990-1999': 0,
          '2000-2009': 0,
          '2010-2019': 0,
          '2020+': 0,
        },
        enrichedBooksCount: 0,
      );
    }

    final totalBooks = books.length;
    final borrowedBooksCount = books.where((b) => b.isBorrowed).length;

    int totalPages = 0;
    int booksWithPages = 0;
    BookModel? longestBook;

    for (final book in books) {
      final pages = book.pageCount;
      if (pages != null && pages > 0) {
        totalPages += pages;
        booksWithPages++;
        if (longestBook == null || pages > (longestBook.pageCount ?? 0)) {
          longestBook = book;
        }
      }
    }

    final averagePages = booksWithPages > 0 ? (totalPages / booksWithPages).round() : 0;

    int totalYears = 0;
    int booksWithYear = 0;
    BookModel? oldestBook;
    int? minYear;

    final Map<String, int> booksByDecade = {
      '<1980': 0,
      '1980-1989': 0,
      '1990-1999': 0,
      '2000-2009': 0,
      '2010-2019': 0,
      '2020+': 0,
    };

    final yearRegex = RegExp(r'\b(1[0-9]{3}|20[0-9]{2})\b');
    final currentYear = DateTime.now().year;

    for (final book in books) {
      final yearStr = book.publishedYear?.trim();
      if (yearStr != null && yearStr.isNotEmpty) {
        final match = yearRegex.firstMatch(yearStr);
        if (match != null) {
          final year = int.tryParse(match.group(0)!);
          if (year != null && year >= 1000 && year <= currentYear + 1) {
            totalYears += year;
            booksWithYear++;

            if (minYear == null || year < minYear) {
              minYear = year;
              oldestBook = book;
            }

            if (year < 1980) {
              booksByDecade['<1980'] = (booksByDecade['<1980'] ?? 0) + 1;
            } else if (year <= 1989) {
              booksByDecade['1980-1989'] = (booksByDecade['1980-1989'] ?? 0) + 1;
            } else if (year <= 1999) {
              booksByDecade['1990-1999'] = (booksByDecade['1990-1999'] ?? 0) + 1;
            } else if (year <= 2009) {
              booksByDecade['2000-2009'] = (booksByDecade['2000-2009'] ?? 0) + 1;
            } else if (year <= 2019) {
              booksByDecade['2010-2019'] = (booksByDecade['2010-2019'] ?? 0) + 1;
            } else {
              booksByDecade['2020+'] = (booksByDecade['2020+'] ?? 0) + 1;
            }
          }
        }
      }
    }

    final averageYear = booksWithYear > 0 ? (totalYears / booksWithYear).round() : null;

    final Map<String, int> authorCounts = {};
    for (final book in books) {
      final author = book.author.trim();
      if (author.isNotEmpty &&
          author.toLowerCase() != 'sense autor' &&
          author.toLowerCase() != 'desconegut' &&
          author.toLowerCase() != 'desconeguda' &&
          author.toLowerCase() != 'anònim' &&
          author.toLowerCase() != 'anonim') {
        authorCounts[author] = (authorCounts[author] ?? 0) + 1;
      }
    }

    final sortedAuthors = authorCounts.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        if (cmp != 0) return cmp;
        return a.key.compareTo(b.key);
      });

    final topAuthors = sortedAuthors.take(5).toList();

    final enrichedBooksCount = books.where((b) =>
      (b.synopsis != null && b.synopsis!.trim().isNotEmpty) ||
      (b.coverUrl != null && b.coverUrl!.trim().isNotEmpty)
    ).length;

    return LibraryStats(
      totalBooks: totalBooks,
      borrowedBooksCount: borrowedBooksCount,
      totalPages: totalPages,
      averagePages: averagePages,
      averageYear: averageYear,
      oldestBook: oldestBook,
      longestBook: longestBook,
      topAuthors: topAuthors,
      booksByDecade: booksByDecade,
      enrichedBooksCount: enrichedBooksCount,
    );
  }
}
