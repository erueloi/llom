import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../models/book_model.dart';
import 'shelf_vision_service.dart';

/// Dades d'enriquiment recuperades de Google Books o Open Library
class BookEnrichmentData {
  final String? author;
  final String? synopsis;
  final String? coverUrl;
  final int? pageCount;
  final String? publishedYear;
  final String? infoUrl;

  const BookEnrichmentData({
    this.author,
    this.synopsis,
    this.coverUrl,
    this.pageCount,
    this.publishedYear,
    this.infoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      if (author != null) 'author': author,
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
          author == other.author &&
          synopsis == other.synopsis &&
          coverUrl == other.coverUrl &&
          pageCount == other.pageCount &&
          publishedYear == other.publishedYear &&
          infoUrl == other.infoUrl;

  @override
  int get hashCode =>
      author.hashCode ^
      synopsis.hashCode ^
      coverUrl.hashCode ^
      pageCount.hashCode ^
      publishedYear.hashCode ^
      infoUrl.hashCode;
}

typedef AiSynopsisGenerator = Future<String?> Function({
  required String title,
  String? author,
  int? year,
});

/// Servei per consultar les APIs de Google Books i Open Library per enriquir la informació dels llibres
class BookEnrichmentService {
  final http.Client _httpClient;
  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;
  final GenerativeModel? _generativeModel;
  final AiSynopsisGenerator? _aiSynopsisGenerator;
  final String _googleBooksApiKey;

  static final Map<String, BookEnrichmentData> _cache = {};

  BookEnrichmentService({
    http.Client? httpClient,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    GenerativeModel? generativeModel,
    AiSynopsisGenerator? aiSynopsisGenerator,
    String? apiKey,
    String? googleBooksApiKey,
  })  : _httpClient = httpClient ?? http.Client(),
        _firestore = firestore,
        _storage = storage,
        _generativeModel = generativeModel,
        _aiSynopsisGenerator = aiSynopsisGenerator,
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
      final authorsList = volumeInfo['authors'] as List<dynamic>?;
      final author = (authorsList != null && authorsList.isNotEmpty)
          ? authorsList.first.toString().trim()
          : null;

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
        author: author,
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
          author: (googleBooksData?.author != null && googleBooksData!.author!.isNotEmpty)
              ? googleBooksData.author
              : openLibData.author,
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
      'limit': '5',
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

      String? authorName;
      String? coverUrl;
      String? firstPublishYear;
      int? pageCount;
      String? workKey;
      String? infoUrl;

      // Iterem sobre els resultats per trobar la millor combinació de portada i metadades
      for (final rawDoc in docs) {
        if (rawDoc is! Map<String, dynamic>) continue;

        if (authorName == null) {
          final authorsList = rawDoc['author_name'] as List<dynamic>?;
          if (authorsList != null && authorsList.isNotEmpty) {
            authorName = authorsList.first.toString().trim();
          }
        }

        if (coverUrl == null && rawDoc['cover_i'] != null) {
          final coverI = rawDoc['cover_i'];
          coverUrl = 'https://covers.openlibrary.org/b/id/$coverI-M.jpg';
        }

        firstPublishYear ??= rawDoc['first_publish_year']?.toString();
        pageCount ??= (rawDoc['number_of_pages_median'] as num?)?.toInt();

        if (workKey == null && rawDoc['key'] is String) {
          final rawKey = rawDoc['key'] as String;
          workKey = rawKey.startsWith('/works/') ? rawKey : '/works/$rawKey';
        }
      }

      infoUrl = workKey != null
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
        author: authorName,
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

  /// Cerca l'autor/a d'un llibre a partir exclusivament del seu títol mitjançant Google Books o Open Library
  Future<String?> lookupAuthorByTitle(String title) async {
    final cleanTitle = cleanSearchTerm(title);
    if (cleanTitle.isEmpty) return null;

    // 1. Memòria cau
    for (final entry in _cache.entries) {
      if (entry.key.startsWith('${cleanTitle.toLowerCase()}_') &&
          entry.value.author != null &&
          entry.value.author!.isNotEmpty) {
        return entry.value.author;
      }
    }

    // 2. Google Books API
    final queryParams = {
      'q': 'intitle:"$cleanTitle"',
      'maxResults': '3',
      'printType': 'books',
      if (hasValidGoogleBooksApiKey) 'key': _googleBooksApiKey,
    };
    final url = Uri.https('www.googleapis.com', '/books/v1/volumes', queryParams);

    try {
      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final items = data['items'] as List<dynamic>?;
        if (items != null && items.isNotEmpty) {
          for (final item in items) {
            final volumeInfo = item['volumeInfo'] as Map<String, dynamic>?;
            final authors = volumeInfo?['authors'] as List<dynamic>?;
            if (authors != null && authors.isNotEmpty) {
              final firstAuthor = authors.first.toString().trim();
              if (firstAuthor.isNotEmpty) {
                return firstAuthor;
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('BookEnrichmentService: Error a lookupAuthorByTitle (Google Books): $e');
    }

    // 3. Suport Open Library
    try {
      final openLibData = await fetchFromOpenLibrary(cleanTitle, '');
      if (openLibData?.author != null && openLibData!.author!.isNotEmpty) {
        return openLibData.author;
      }
    } catch (e) {
      debugPrint('BookEnrichmentService: Error a lookupAuthorByTitle (Open Library): $e');
    }

    return null;
  }

  /// Llista de models candidats de Gemini per a la generació de sinopsi per ordre de preferència
  static const List<String> candidateSynopsisModels = [
    'gemini-flash-latest',
    'gemini-3.8-flash',
    'gemini-3.7-flash',
    'gemini-3.5-flash',
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  /// Genera una sinopsi o context divulgatiu concís mitjançant Gemini Flash
  /// quan Google Books i Open Library no disposen de descripció
  Future<String?> generateAiSynopsis({
    required String title,
    String? author,
    int? year,
    String? apiKeyOverride,
    GenerativeModel? modelOverride,
  }) async {
    final cleanTitle = cleanSearchTerm(title);
    if (cleanTitle.isEmpty) return null;

    if (_aiSynopsisGenerator != null) {
      return _aiSynopsisGenerator(
        title: title,
        author: author,
        year: year,
      );
    }

    final key = apiKeyOverride ?? await ShelfVisionService.getEffectiveApiKey();
    if (key == null || key.trim().isEmpty) {
      debugPrint('BookEnrichmentService: No hi ha GEMINI_API_KEY disponible per generar la sinopsi.');
      return null;
    }

    final cleanAuthor = author != null ? cleanSearchTerm(author) : '';
    final authorPart = cleanAuthor.isNotEmpty ? ' de \'$cleanAuthor\'' : '';
    final yearPart = year != null ? ' ($year)' : '';

    final prompt = "Ets un bibliotecari expert. Genera un resum o context divulgatiu concís (màxim 2 paràgrafs) sobre l'obra o temàtica del llibre '$cleanTitle'$authorPart$yearPart. Fes-ho en el mateix idioma del títol (català o castellà). Si és una obra molt específica o desconeguda, descriu el context temàtic que suggereix el títol sense inventar dades.";

    if (modelOverride != null || _generativeModel != null) {
      try {
        final model = modelOverride ?? _generativeModel!;
        final response = await model.generateContent([Content.text(prompt)]);
        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) return cleanHtml(text);
      } catch (e) {
        debugPrint('BookEnrichmentService: Error generant sinopsi amb model injectat: $e');
      }
      return null;
    }

    // Prova la llista de models per ordre (gemini-flash-latest, gemini-3.8-flash, etc.)
    for (final modelName in candidateSynopsisModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: key.trim(),
        );

        final response = await model.generateContent([
          Content.text(prompt),
        ]);

        final text = response.text?.trim();
        if (text != null && text.isNotEmpty) {
          return cleanHtml(text);
        }
      } catch (e) {
        final errorStr = e.toString().toLowerCase();
        // Si el model no està disponible, no és suportat o dóna 404, prova el següent
        if (errorStr.contains('not found') ||
            errorStr.contains('404') ||
            errorStr.contains('not supported') ||
            errorStr.contains('unsupported')) {
          continue;
        }
        debugPrint('BookEnrichmentService: Error generant sinopsi amb $modelName: $e');
        break;
      }
    }
    return null;
  }

  /// Puja una imatge de portada a Firebase Storage al path:
  /// covers/{libraryId}/{bookId}.jpg
  /// i retorna la URL pública de descàrrega
  Future<String?> uploadBookCover({
    required String libraryId,
    required String bookId,
    required Uint8List imageBytes,
    FirebaseStorage? storageOverride,
  }) async {
    final cleanLibId = libraryId.trim();
    final cleanBookId = bookId.trim();
    if (cleanLibId.isEmpty || cleanBookId.isEmpty) {
      throw ArgumentError('libraryId i bookId són obligatoris per pujar la portada');
    }

    try {
      final storage = storageOverride ?? _storage ?? FirebaseStorage.instance;
      final ref = storage.ref().child('covers/$cleanLibId/$cleanBookId.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
      );

      final uploadTask = await ref.putData(imageBytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('BookEnrichmentService: Error pujant portada a Firebase Storage: $e');
      return null;
    }
  }

  /// Enriquir el llibre i desar les noves dades a Firestore si encara no estan persistides
  Future<BookModel> enrichAndPersistBook({
    required BookModel book,
    required String libraryId,
    bool force = false,
  }) async {
    final bool hasSynopsis = book.synopsis != null && book.synopsis!.isNotEmpty;
    final bool hasCover = book.coverUrl != null && book.coverUrl!.isNotEmpty;

    if (!force) {
      // 1. Si el llibre ja disposa tant de sinopsi com de portada, està 100% complet
      if (hasSynopsis && hasCover) {
        return book;
      }

      // 2. Si ja s'han assolit 3 intents o més per recuperar el que falta, ho deixem estar
      if (book.enrichmentAttempts >= 3) {
        return book;
      }
    } else {
      // Si és forçat per l'usuari, buidem la memòria cau per a aquest llibre
      final cleanTitle = cleanSearchTerm(book.title);
      final cleanAuthor = cleanSearchTerm(book.author);
      _cache.remove(_generateCacheKey(cleanTitle, cleanAuthor));
    }

    final nextAttempts = force ? 1 : (book.enrichmentAttempts + 1);

    final enrichment = await fetchEnrichmentData(
      title: book.title,
      author: book.author,
    );

    var finalSynopsis = (force && enrichment?.synopsis != null && enrichment!.synopsis!.isNotEmpty)
        ? enrichment.synopsis
        : (hasSynopsis ? book.synopsis : (enrichment?.synopsis ?? book.synopsis));
    var isAi = (force && enrichment?.synopsis != null && enrichment!.synopsis!.isNotEmpty)
        ? false
        : (hasSynopsis ? book.isAiSynopsis : false);

    // Fallback de Gemini Flash si ni Google Books ni Open Library tenen sinopsi
    if (finalSynopsis == null || finalSynopsis.trim().isEmpty) {
      final aiSynopsis = await generateAiSynopsis(
        title: book.title,
        author: book.author.isNotEmpty ? book.author : enrichment?.author,
        year: int.tryParse(enrichment?.publishedYear ?? book.publishedYear ?? ''),
      );
      if (aiSynopsis != null && aiSynopsis.isNotEmpty) {
        finalSynopsis = aiSynopsis;
        isAi = true;
      }
    }

    final newCoverUrl = (force && enrichment?.coverUrl != null && enrichment!.coverUrl!.isNotEmpty)
        ? enrichment.coverUrl
        : (hasCover ? book.coverUrl : (enrichment?.coverUrl ?? book.coverUrl));
    final newPageCount = (force && enrichment?.pageCount != null)
        ? enrichment!.pageCount
        : (enrichment?.pageCount ?? book.pageCount);
    final newPublishedYear = (force && enrichment?.publishedYear != null)
        ? enrichment!.publishedYear
        : (enrichment?.publishedYear ?? book.publishedYear);
    final newInfoUrl = (force && enrichment?.infoUrl != null)
        ? enrichment!.infoUrl
        : (enrichment?.infoUrl ?? book.infoUrl);

    final updatedBook = book.copyWith(
      synopsis: finalSynopsis,
      isAiSynopsis: isAi,
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
          if ((force || !hasSynopsis) && finalSynopsis != null) ...{
            'synopsis': finalSynopsis,
            'isAiSynopsis': isAi,
          },
          if ((force || !hasCover) && newCoverUrl != null) 'coverUrl': newCoverUrl,
          if ((force || book.pageCount == null) && newPageCount != null) 'pageCount': newPageCount,
          if ((force || book.publishedYear == null) && newPublishedYear != null) 'publishedYear': newPublishedYear,
          if ((force || book.infoUrl == null) && newInfoUrl != null) 'infoUrl': newInfoUrl,
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
