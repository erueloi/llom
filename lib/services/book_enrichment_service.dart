import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';

/// Dades d'enriquiment recuperades de Google Books o Open Library
class BookEnrichmentData {
  final String? synopsis;
  final String? coverUrl;
  final int? pageCount;
  final String? publishedYear;
  final String? infoUrl;

  const BookEnrichmentData({
    this.synopsis,
    this.coverUrl,
    this.pageCount,
    this.publishedYear,
    this.infoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      if (synopsis != null) 'synopsis': synopsis,
      if (coverUrl != null) 'coverUrl': coverUrl,
      if (pageCount != null) 'pageCount': pageCount,
      if (publishedYear != null) 'publishedYear': publishedYear,
      if (infoUrl != null) 'infoUrl': infoUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookEnrichmentData &&
          runtimeType == other.runtimeType &&
          synopsis == other.synopsis &&
          coverUrl == other.coverUrl &&
          pageCount == other.pageCount &&
          publishedYear == other.publishedYear &&
          infoUrl == other.infoUrl;

  @override
  int get hashCode =>
      synopsis.hashCode ^
      coverUrl.hashCode ^
      pageCount.hashCode ^
      publishedYear.hashCode ^
      infoUrl.hashCode;
}

/// Servei per consultar les APIs de Google Books i Open Library per enriquir la informació dels llibres
class BookEnrichmentService {
  final http.Client _httpClient;
  final FirebaseFirestore? _firestore;
  final String _googleBooksApiKey;

  static final Map<String, BookEnrichmentData> _cache = {};

  BookEnrichmentService({
    http.Client? httpClient,
    FirebaseFirestore? firestore,
    String? apiKey,
    String? googleBooksApiKey,
  })  : _httpClient = httpClient ?? http.Client(),
        _firestore = firestore,
        _googleBooksApiKey = (googleBooksApiKey ??
                apiKey ??
                const String.fromEnvironment('GOOGLE_BOOKS_API_KEY'))
            .trim();

  /// Comprova si la clau de Google Books és vàlida (prefix 'AIzaSy...' i mai format d'AI Studio 'AQ.')
  bool get hasValidGoogleBooksApiKey {
    if (_googleBooksApiKey.isEmpty) return false;
    if (_googleBooksApiKey.startsWith('AQ.')) return false;
    return _googleBooksApiKey.startsWith('AIzaSy');
  }

  String get googleBooksApiKey => _googleBooksApiKey;

  static String _generateCacheKey(String title, String author) {
    return '${title.trim().toLowerCase()}_${author.trim().toLowerCase()}';
  }

  /// Neteja la memòria cau d'enriquiment en memòria (per a proves o recàrregues)
  static void clearCache() {
    _cache.clear();
  }

  /// Neteja caràcters de puntuació extres (comes, cometes, guions, etc.) abans d'enviar la consulta
  static String cleanSearchTerm(String text) {
    return text
        .replaceAll(RegExp(r'[,."\-_:;!?]'), ' ')
        .replaceAll("'", ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Neteja etiquetes HTML i entitats habituals d'una cadena de text
  static String cleanHtml(String text) {
    var cleaned = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
    cleaned = cleaned
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&#39;', "'");
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Assegura que l'URL utilitzi esquema HTTPS
  static String? normalizeCoverUrl(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    var normalized = url.trim();
    if (normalized.startsWith('http://')) {
      normalized = 'https://${normalized.substring(7)}';
    }
    return normalized;
  }

  /// Retorna una URL segura per a la visualització de la portada a qualsevol plataforma.
  /// A Flutter Web (`kIsWeb`), els servidors d'imatges de Google Books (`books.google.com` o
  /// `googleusercontent.com`) no afegeixen capçaleres CORS (`Access-Control-Allow-Origin: *`).
  /// Això fa que el navegador bloquegi la descàrrega amb un error de xarxa (`statusCode: 0`).
  /// Per evitar-ho a la Web, es canalitza a través del proxy d'imatges segur `images.weserv.nl`
  /// amb suport CORS complet i memòria cau CDN de Cloudflare.
  static String? getSafeDisplayCoverUrl(String? url, {bool? isWebOverride}) {
    if (url == null || url.trim().isEmpty) return null;
    final normalized = normalizeCoverUrl(url) ?? url.trim();
    final isWeb = isWebOverride ?? kIsWeb;
    if (isWeb &&
        !normalized.startsWith('https://images.weserv.nl') &&
        (normalized.contains('books.google.com') ||
            normalized.contains('googleusercontent.com'))) {
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(normalized)}';
    }
    return normalized;
  }

  /// Extreu l'any de publicació a partir de cadenes de data (ex: "2018-05-14" -> "2018")
  static String? extractPublishedYear(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;
    final match = RegExp(r'\b(\d{4})\b').firstMatch(dateStr);
    return match?.group(1) ?? dateStr.trim();
  }

  /// Consulta les APIs d'enriquiment:
  /// Pas 1: Consulta Google Books API amb la clau AIzaSy. Si retorna tant portada com sinopsi, finalitza.
  /// Pas 2: Si Google Books no conté ambdues dades (o retorna 401, 429 o 0 resultats), consulta Open Library per complementar les dades mancants.
  Future<BookEnrichmentData?> fetchEnrichmentData({
    required String title,
    required String author,
  }) async {
    final cleanTitle = cleanSearchTerm(title);
    final cleanAuthor = cleanSearchTerm(author);

    if (cleanTitle.isEmpty) return null;

    final cacheKey = _generateCacheKey(cleanTitle, cleanAuthor);
    if (_cache.containsKey(cacheKey)) {
      final cached = _cache[cacheKey];
      if (cached != null) {
        final hasBoth = (cached.synopsis != null && cached.synopsis!.isNotEmpty) &&
            (cached.coverUrl != null && cached.coverUrl!.isNotEmpty);
        if (hasBoth) {
          return cached;
        }
      }
    }

    final combinedFallback = cleanAuthor.isNotEmpty
        ? '$cleanTitle $cleanAuthor'
        : cleanTitle;
    final fallbackInfoUrl =
        'https://books.google.com/books?q=${Uri.encodeComponent(combinedFallback)}';

    // -------------------------------------------------------------------------
    // PAS 1: Consulta a Google Books API
    // -------------------------------------------------------------------------
    Map<String, dynamic>? volumeInfo;
    bool isGoogleBooksQuotaExhausted = false;

    // Intent 1 (precís): Cerca amb títol i autor nets entre cometes
    final query1 = cleanAuthor.isNotEmpty
        ? 'intitle:"$cleanTitle"+inauthor:"$cleanAuthor"'
        : 'intitle:"$cleanTitle"';

    final queryParams1 = {
      'q': query1,
      'maxResults': '3',
      'printType': 'books',
      if (hasValidGoogleBooksApiKey) 'key': _googleBooksApiKey,
    };
    final url1 = Uri.https('www.googleapis.com', '/books/v1/volumes', queryParams1);

    try {
      final response1 = await _httpClient
          .get(url1)
          .timeout(const Duration(seconds: 4));
      if (response1.statusCode == 429 || response1.statusCode == 401) {
        debugPrint('BookEnrichmentService: Quota o accés no autoritzat a Google Books (${response1.statusCode}).');
        isGoogleBooksQuotaExhausted = true;
      } else if (response1.statusCode == 200) {
        final Map<String, dynamic> data1 = jsonDecode(response1.body);
        final totalItems = (data1['totalItems'] as num?)?.toInt();
        final items = data1['items'] as List<dynamic>?;
        if ((totalItems == null || totalItems > 0) && items != null && items.isNotEmpty) {
          volumeInfo = items.first['volumeInfo'] as Map<String, dynamic>?;
        }
      }
    } catch (e) {
      debugPrint('BookEnrichmentService: Error a intent 1 per "$cleanTitle": $e');
    }

    // Intent 2 (tolerant): Si el primer intent no retorna resultats (totalItems == 0) i no estem bloquejats
    if (volumeInfo == null && !isGoogleBooksQuotaExhausted) {
      final queryParams2 = {
        'q': combinedFallback,
        'maxResults': '3',
        'printType': 'books',
        if (hasValidGoogleBooksApiKey) 'key': _googleBooksApiKey,
      };
      final url2 = Uri.https('www.googleapis.com', '/books/v1/volumes', queryParams2);

      try {
        final response2 = await _httpClient
            .get(url2)
            .timeout(const Duration(seconds: 4));
        if (response2.statusCode == 429 || response2.statusCode == 401) {
          debugPrint('BookEnrichmentService: Quota o accés no autoritzat a Google Books a intent 2 (${response2.statusCode}).');
          isGoogleBooksQuotaExhausted = true;
        } else if (response2.statusCode == 200) {
          final Map<String, dynamic> data2 = jsonDecode(response2.body);
          final items = data2['items'] as List<dynamic>?;
          if (items != null && items.isNotEmpty) {
            volumeInfo = items.first['volumeInfo'] as Map<String, dynamic>?;
          }
        }
      } catch (e) {
        debugPrint('BookEnrichmentService: Error a intent 2 per "$cleanTitle": $e');
      }
    }

    BookEnrichmentData? googleBooksData;
    if (volumeInfo != null) {
      final rawDesc = volumeInfo['description'] as String?;
      final synopsis = rawDesc != null ? cleanHtml(rawDesc) : null;

      final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
      final rawCover = (imageLinks?['thumbnail'] ?? imageLinks?['smallThumbnail']) as String?;
      final coverUrl = normalizeCoverUrl(rawCover);

      final pageCount = (volumeInfo['pageCount'] as num?)?.toInt();
      final publishedYear = extractPublishedYear(volumeInfo['publishedDate'] as String?);
      final rawInfoUrl = volumeInfo['infoLink'] as String?;
      final infoUrl = (rawInfoUrl != null && rawInfoUrl.trim().isNotEmpty)
          ? rawInfoUrl.trim()
          : fallbackInfoUrl;

      googleBooksData = BookEnrichmentData(
        synopsis: synopsis,
        coverUrl: coverUrl,
        pageCount: pageCount,
        publishedYear: publishedYear,
        infoUrl: infoUrl,
      );

      final hasBoth = (synopsis != null && synopsis.isNotEmpty) &&
          (coverUrl != null && coverUrl.isNotEmpty);

      // Si Google Books ja conté tant sinopsi com portada, finalitza directament
      if (hasBoth) {
        _cache[cacheKey] = googleBooksData;
        return googleBooksData;
      }
    }

    // -------------------------------------------------------------------------
    // PAS 2: Suport transparent amb Open Library si Google Books dóna 401, 429,
    //        0 resultats o li falta la portada o la sinopsi.
    // -------------------------------------------------------------------------
    try {
      final openLibData = await fetchFromOpenLibrary(cleanTitle, cleanAuthor);
      if (openLibData != null) {
        final merged = BookEnrichmentData(
          synopsis: (googleBooksData?.synopsis != null && googleBooksData!.synopsis!.isNotEmpty)
              ? googleBooksData.synopsis
              : openLibData.synopsis,
          coverUrl: (googleBooksData?.coverUrl != null && googleBooksData!.coverUrl!.isNotEmpty)
              ? googleBooksData.coverUrl
              : openLibData.coverUrl,
          pageCount: googleBooksData?.pageCount ?? openLibData.pageCount,
          publishedYear: googleBooksData?.publishedYear ?? openLibData.publishedYear,
          infoUrl: googleBooksData?.infoUrl ?? openLibData.infoUrl,
        );

        final hasAny = (merged.synopsis != null && merged.synopsis!.isNotEmpty) ||
            (merged.coverUrl != null && merged.coverUrl!.isNotEmpty);

        if (hasAny) {
          _cache[cacheKey] = merged;
          return merged;
        }
      }
    } catch (e) {
      debugPrint('BookEnrichmentService: Error a Open Library per "$cleanTitle": $e');
    }

    // Si Open Library tampoc ha trobat res, però Google Books tenia alguna dada bàsica
    if (googleBooksData != null) {
      _cache[cacheKey] = googleBooksData;
      return googleBooksData;
    }

    return null;
  }

  /// Consulta el servei alternatiu Open Library en cas de fallada o 429 a Google Books
  Future<BookEnrichmentData?> fetchFromOpenLibrary(String title, String author) async {
    final cleanTitle = cleanSearchTerm(title);
    final cleanAuthor = cleanSearchTerm(author);

    if (cleanTitle.isEmpty) return null;

    final queryParams = {
      'title': cleanTitle,
      if (cleanAuthor.isNotEmpty) 'author': cleanAuthor,
      'limit': '1',
    };

    final url = Uri.https('openlibrary.org', '/search.json', queryParams);

    try {
      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode != 200) {
        return null;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);
      final docs = data['docs'] as List<dynamic>?;
      if (docs == null || docs.isEmpty) {
        return null;
      }

      final doc = docs.first as Map<String, dynamic>;

      final coverI = doc['cover_i'];
      final coverUrl = coverI != null
          ? 'https://covers.openlibrary.org/b/id/$coverI-M.jpg'
          : null;

      final firstPublishYear = doc['first_publish_year']?.toString();
      final pageCount = (doc['number_of_pages_median'] as num?)?.toInt();

      final rawKey = doc['key'] as String?;
      final workKey = (rawKey != null && rawKey.startsWith('/works/'))
          ? rawKey
          : (rawKey != null ? '/works/$rawKey' : null);

      final infoUrl = workKey != null
          ? 'https://openlibrary.org$workKey'
          : 'https://openlibrary.org/search?q=${Uri.encodeComponent('$cleanTitle $cleanAuthor'.trim())}';

      String? synopsis;
      if (workKey != null) {
        try {
          final workUrl = Uri.https('openlibrary.org', '$workKey.json');
          final workResponse = await _httpClient
              .get(workUrl)
              .timeout(const Duration(seconds: 4));
          if (workResponse.statusCode == 200) {
            final workData = jsonDecode(workResponse.body);
            final desc = workData['description'];
            if (desc is String) {
              synopsis = cleanHtml(desc);
            } else if (desc is Map<String, dynamic> && desc['value'] is String) {
              synopsis = cleanHtml(desc['value'] as String);
            }
          }
        } catch (e) {
          debugPrint('BookEnrichmentService: Error obtenint descripció d\'Open Library: $e');
        }
      }

      return BookEnrichmentData(
        synopsis: synopsis,
        coverUrl: coverUrl,
        pageCount: pageCount,
        publishedYear: firstPublishYear,
        infoUrl: infoUrl,
      );
    } catch (e) {
      debugPrint('BookEnrichmentService: Error a Open Library per "$cleanTitle": $e');
      return null;
    }
  }

  /// Enriquir el llibre i desar les noves dades a Firestore si encara no estan persistides
  Future<BookModel> enrichAndPersistBook({
    required BookModel book,
    required String libraryId,
  }) async {
    final bool hasSynopsis = book.synopsis != null && book.synopsis!.isNotEmpty;
    final bool hasCover = book.coverUrl != null && book.coverUrl!.isNotEmpty;

    // 1. Si el llibre ja disposa tant de sinopsi com de portada, està 100% complet
    if (hasSynopsis && hasCover) {
      return book;
    }

    // 2. Si ja s'han assolit 3 intents o més per recuperar el que falta, ho deixem estar
    if (book.enrichmentAttempts >= 3) {
      return book;
    }

    final nextAttempts = book.enrichmentAttempts + 1;

    final enrichment = await fetchEnrichmentData(
      title: book.title,
      author: book.author,
    );

    final newSynopsis = hasSynopsis ? book.synopsis : (enrichment?.synopsis ?? book.synopsis);
    final newCoverUrl = hasCover ? book.coverUrl : (enrichment?.coverUrl ?? book.coverUrl);
    final newPageCount = book.pageCount ?? enrichment?.pageCount;
    final newPublishedYear = book.publishedYear ?? enrichment?.publishedYear;
    final newInfoUrl = book.infoUrl ?? enrichment?.infoUrl;

    final updatedBook = book.copyWith(
      synopsis: newSynopsis,
      coverUrl: newCoverUrl,
      pageCount: newPageCount,
      publishedYear: newPublishedYear,
      infoUrl: newInfoUrl,
      enrichmentAttempts: nextAttempts,
    );

    // Persistència a Cloud Firestore en segon pla si tenim libraryId i id
    if (libraryId.isNotEmpty && book.id.isNotEmpty) {
      try {
        final firestoreInstance = _firestore ?? FirebaseFirestore.instance;
        final updateMap = <String, dynamic>{
          'enrichmentAttempts': nextAttempts,
          if (!hasSynopsis && newSynopsis != null) 'synopsis': newSynopsis,
          if (!hasCover && newCoverUrl != null) 'coverUrl': newCoverUrl,
          if (book.pageCount == null && newPageCount != null) 'pageCount': newPageCount,
          if (book.publishedYear == null && newPublishedYear != null) 'publishedYear': newPublishedYear,
          if (book.infoUrl == null && newInfoUrl != null) 'infoUrl': newInfoUrl,
        };

        await firestoreInstance
            .collection('libraries')
            .doc(libraryId)
            .collection('books')
            .doc(book.id)
            .update(updateMap)
            .timeout(const Duration(seconds: 2));
      } catch (e) {
        debugPrint('BookEnrichmentService: No s\'ha pogut persistir a Firestore: $e');
      }
    }

    return updatedBook;
  }
}
