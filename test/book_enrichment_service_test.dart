import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/services/book_enrichment_service.dart';

void main() {
  group('BookEnrichmentService helper functions', () {
    test('cleanHtml removes tags and decodes common entities', () {
      const htmlText = '<p>Un llibre <b>magnífic</b> &amp; indispensable per a tothom. &quot;Obra mestra&quot;.</p>';
      final cleaned = BookEnrichmentService.cleanHtml(htmlText);
      expect(cleaned, 'Un llibre magnífic & indispensable per a tothom. "Obra mestra".');
    });


    test('cleanSearchTerm removes commas, periods, quotes and dashes', () {
      expect(
        BookEnrichmentService.cleanSearchTerm('Lejos, más lejos: "Segona part" - Vol. 1.'),
        'Lejos más lejos Segona part Vol 1',
      );
      expect(
        BookEnrichmentService.cleanSearchTerm('  ,.,  '),
        '',
      );
    });

    test('normalizeCoverUrl converts http to https', () {
      expect(
        BookEnrichmentService.normalizeCoverUrl('http://books.google.com/books/content?id=123'),
        'https://books.google.com/books/content?id=123',
      );
      expect(
        BookEnrichmentService.normalizeCoverUrl('https://secure.example.com/cover.jpg'),
        'https://secure.example.com/cover.jpg',
      );
      expect(BookEnrichmentService.normalizeCoverUrl(null), isNull);
      expect(BookEnrichmentService.normalizeCoverUrl(''), isNull);
    });

    test('getSafeDisplayCoverUrl handles CORS for Google Books images on Web', () {
      const gBooksUrl = 'https://books.google.com/books/content?id=SzPOSAAACAAJ&printsec=frontcover&img=1&zoom=1&source=gbs_api';
      const openLibUrl = 'https://covers.openlibrary.org/b/id/998877-M.jpg';

      // On Web: Google Books URLs are proxied through images.weserv.nl with CORS headers
      expect(
        BookEnrichmentService.getSafeDisplayCoverUrl(gBooksUrl, isWebOverride: true),
        'https://images.weserv.nl/?url=${Uri.encodeComponent(gBooksUrl)}',
      );
      // On Web: http is converted to https and proxied
      expect(
        BookEnrichmentService.getSafeDisplayCoverUrl('http://books.google.com/books/content?id=123', isWebOverride: true),
        'https://images.weserv.nl/?url=${Uri.encodeComponent("https://books.google.com/books/content?id=123")}',
      );
      // On Web: Open Library already has CORS, so it is NOT proxied
      expect(
        BookEnrichmentService.getSafeDisplayCoverUrl(openLibUrl, isWebOverride: true),
        openLibUrl,
      );
      // On Web: already proxied URL is NOT double proxied
      final proxied = 'https://images.weserv.nl/?url=${Uri.encodeComponent(gBooksUrl)}';
      expect(
        BookEnrichmentService.getSafeDisplayCoverUrl(proxied, isWebOverride: true),
        proxied,
      );

      // On Mobile/Desktop (not Web): direct URL is preserved without proxy
      expect(
        BookEnrichmentService.getSafeDisplayCoverUrl(gBooksUrl, isWebOverride: false),
        gBooksUrl,
      );
      expect(
        BookEnrichmentService.getSafeDisplayCoverUrl(openLibUrl, isWebOverride: false),
        openLibUrl,
      );

      // Null and empty checks
      expect(BookEnrichmentService.getSafeDisplayCoverUrl(null), isNull);
      expect(BookEnrichmentService.getSafeDisplayCoverUrl(''), isNull);
    });

    test('extractPublishedYear extracts 4-digit year correctly', () {
      expect(BookEnrichmentService.extractPublishedYear('2018-04-23'), '2018');
      expect(BookEnrichmentService.extractPublishedYear('1962'), '1962');
      expect(BookEnrichmentService.extractPublishedYear(null), isNull);
    });
  });

  group('BookEnrichmentService API fetch & cache', () {
    test('Queries Google Books first and finishes without calling Open Library when valid data is found', () async {
      final List<String> requestedHosts = [];
      final mockClient = MockClient((request) async {
        requestedHosts.add(request.url.host);
        if (request.url.host == 'www.googleapis.com') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'volumeInfo': {
                    'title': 'Llibre Prioritari Google',
                    'description': 'Sinopsi des de Google Books.',
                    'imageLinks': {'thumbnail': 'https://books.google.com/cover.jpg'},
                    'pageCount': 300,
                    'publishedDate': '2015',
                    'infoLink': 'https://books.google.com/books?id=123',
                  }
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = BookEnrichmentService(httpClient: mockClient);
      final data = await service.fetchEnrichmentData(
        title: 'Llibre Prioritari Google',
        author: 'Autor',
      );

      expect(data, isNotNull);
      expect(data!.synopsis, 'Sinopsi des de Google Books.');
      expect(data.coverUrl, 'https://books.google.com/cover.jpg');
      expect(data.pageCount, 300);
      expect(data.publishedYear, '2015');
      expect(data.infoUrl, 'https://books.google.com/books?id=123');

      // Google Books was called, Open Library was NOT called
      expect(requestedHosts.where((h) => h.contains('googleapis.com')), isNotEmpty);
      expect(requestedHosts.where((h) => h.contains('openlibrary.org')), isEmpty);
    });

    test('Fetches and parses Google Books volume info correctly and uses cache', () async {
      int requestCount = 0;

      final mockClient = MockClient((request) async {
        requestCount++;
        expect(request.url.host, 'www.googleapis.com');
        expect(request.url.path, '/books/v1/volumes');

        final responseBody = {
          'items': [
            {
              'volumeInfo': {
                'title': 'La plaça del Diamant',
                'authors': ['Mercè Rodoreda'],
                'description': '<p>Una de les novel·les més cèlebres de la literatura catalana.</p>',
                'imageLinks': {
                  'smallThumbnail': 'http://books.google.com/small.jpg',
                  'thumbnail': 'http://books.google.com/thumbnail.jpg',
                },
                'pageCount': 288,
                'publishedDate': '1962-01-01',
                'infoLink': 'https://books.google.cat/books?id=diamant',
              }
            }
          ]
        };

        return http.Response(jsonEncode(responseBody), 200, headers: {
          'content-type': 'application/json; charset=utf-8',
        });
      });

      final service = BookEnrichmentService(httpClient: mockClient);

      final data = await service.fetchEnrichmentData(
        title: 'La plaça del Diamant',
        author: 'Mercè Rodoreda',
      );

      expect(data, isNotNull);
      expect(data!.synopsis, 'Una de les novel·les més cèlebres de la literatura catalana.');
      expect(data.coverUrl, 'https://books.google.com/thumbnail.jpg');
      expect(data.pageCount, 288);
      expect(data.publishedYear, '1962');
      expect(data.infoUrl, 'https://books.google.cat/books?id=diamant');
      expect(requestCount, 1); // 1 sola crida a Google Books

      // Segona crida: ha de venir de la memòria cau sense fer petició HTTP nova
      final cachedData = await service.fetchEnrichmentData(
        title: 'La plaça del Diamant',
        author: 'Mercè Rodoreda',
      );
      expect(cachedData, equals(data));
      expect(requestCount, 1);
    });

    test('Returns null gracefully on empty items or HTTP error', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'openlibrary.org') {
          return http.Response(jsonEncode({'docs': []}), 200);
        }
        if (request.url.query.contains('Error500')) {
          return http.Response('Internal Error', 500);
        }
        return http.Response(jsonEncode({'totalItems': 0, 'items': []}), 200);
      });

      final service = BookEnrichmentService(httpClient: mockClient);

      final notFound = await service.fetchEnrichmentData(
        title: 'Llibre Inexistent 999999',
        author: 'Autor Desconegut',
      );
      expect(notFound, isNull);

      final errorRes = await service.fetchEnrichmentData(
        title: 'Error500',
        author: 'Test',
      );
      expect(errorRes, isNull);
    });

    test('enrichAndPersistBook updates BookModel with fetched data', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'openlibrary.org') {
          return http.Response(jsonEncode({'docs': []}), 200);
        }
        return http.Response(
          jsonEncode({
            'items': [
              {
                'volumeInfo': {
                  'description': 'Sinopsi enrichida per a test.',
                  'imageLinks': {'thumbnail': 'https://example.com/cover.jpg'},
                  'pageCount': 350,
                  'publishedDate': '2021',
                  'infoLink': 'https://example.com/info',
                }
              }
            ]
          }),
          200,
        );
      });

      final service = BookEnrichmentService(httpClient: mockClient);

      final book = BookModel(
        id: 'book_enrich_1',
        title: 'Tirant lo Blanc',
        author: 'Joanot Martorell',
        shelfCode: 'E1-B1',
        positionIndex: 1,
        createdAt: DateTime.now(),
      );

      final enriched = await service.enrichAndPersistBook(
        book: book,
        libraryId: '', // Buida per evitar tocar Firestore real
      );

      expect(enriched.synopsis, 'Sinopsi enrichida per a test.');
      expect(enriched.coverUrl, 'https://example.com/cover.jpg');
      expect(enriched.pageCount, 350);
      expect(enriched.publishedYear, '2021');
      expect(enriched.infoUrl, 'https://example.com/info');
    });

    test('enrichAndPersistBook skips fetch if both synopsis and coverUrl already exist', () async {
      int calls = 0;
      final mockClient = MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      });

      final service = BookEnrichmentService(httpClient: mockClient);

      final fullyEnrichedBook = BookModel(
        id: 'book_fully_enriched',
        title: 'Complet',
        author: 'Autor',
        shelfCode: 'E1-B1',
        positionIndex: 1,
        synopsis: 'Aquesta sinopsi ja existeix.',
        coverUrl: 'https://example.com/portada.jpg',
        createdAt: DateTime.now(),
      );

      final result = await service.enrichAndPersistBook(
        book: fullyEnrichedBook,
        libraryId: '',
      );

      expect(result.synopsis, 'Aquesta sinopsi ja existeix.');
      expect(result.coverUrl, 'https://example.com/portada.jpg');
      expect(calls, 0); // No ha fet cap petició HTTP
    });

    test('enrichAndPersistBook skips fetch if enrichmentAttempts >= 3 (leaves it alone)', () async {
      int calls = 0;
      final mockClient = MockClient((_) async {
        calls++;
        return http.Response('{}', 200);
      });

      final service = BookEnrichmentService(httpClient: mockClient);

      final bookMaxAttempts = BookModel(
        id: 'book_max_attempts',
        title: 'Sense Coberta Ni Sinopsi Però 3 Intents',
        author: 'Autor',
        shelfCode: 'E1-B1',
        positionIndex: 1,
        enrichmentAttempts: 3,
        createdAt: DateTime.now(),
      );

      final result = await service.enrichAndPersistBook(
        book: bookMaxAttempts,
        libraryId: '',
      );

      expect(result.enrichmentAttempts, 3);
      expect(calls, 0); // Ho deixa estar, no fa peticions HTTP
    });

    test('enrichAndPersistBook attempts to find missing cover if only synopsis is present', () async {
      int calls = 0;
      final mockClient = MockClient((request) async {
        calls++;
        if (request.url.host == 'openlibrary.org') {
          return http.Response(jsonEncode({'docs': []}), 200);
        }
        return http.Response(
          jsonEncode({
            'totalItems': 1,
            'items': [
              {
                'volumeInfo': {
                  'imageLinks': {'thumbnail': 'https://example.com/nova_portada.jpg'},
                }
              }
            ]
          }),
          200,
        );
      });

      final service = BookEnrichmentService(httpClient: mockClient);

      final bookOnlySynopsis = BookModel(
        id: 'book_only_synopsis',
        title: 'Té Sinopsi Però No Portada',
        author: 'Autor',
        shelfCode: 'E1-B1',
        positionIndex: 1,
        synopsis: 'Sinopsi conservada.',
        enrichmentAttempts: 0,
        createdAt: DateTime.now(),
      );

      final result = await service.enrichAndPersistBook(
        book: bookOnlySynopsis,
        libraryId: '',
      );

      expect(calls, greaterThan(0));
      expect(result.synopsis, 'Sinopsi conservada.');
      expect(result.coverUrl, 'https://example.com/nova_portada.jpg');
      expect(result.enrichmentAttempts, 1);
    });

    test('Resilient search with commas in title ("Lejos, más lejos") cleans query and retrieves volume', () async {
      String? requestedQuery;
      final mockClient = MockClient((request) async {
        if (request.url.host == 'openlibrary.org') {
          return http.Response(jsonEncode({'docs': []}), 200);
        }
        requestedQuery = request.url.query;
        final responseBody = {
          'totalItems': 1,
          'items': [
            {
              'volumeInfo': {
                'title': 'Lejos, más lejos',
                'authors': ['Gabriel'],
                'description': 'Una novel·la apassionant.',
                'infoLink': 'https://books.google.cat/books?id=lejos',
              }
            }
          ]
        };
        return http.Response(jsonEncode(responseBody), 200);
      });

      final service = BookEnrichmentService(httpClient: mockClient);
      final data = await service.fetchEnrichmentData(
        title: 'Lejos, más lejos',
        author: 'Gabriel',
      );

      expect(data, isNotNull);
      expect(data!.synopsis, 'Una novel·la apassionant.');
      expect(data.infoUrl, 'https://books.google.cat/books?id=lejos');
      expect(requestedQuery, anyOf(contains('Lejos+m%C3%A1s+lejos'), contains('Lejos%20m%C3%A1s%20lejos')));
    });

    test('Falls back to Intent 2 (open search) when Intent 1 returns totalItems == 0', () async {
      final List<String> requestedQueries = [];
      final mockClient = MockClient((request) async {
        if (request.url.host == 'openlibrary.org') {
          return http.Response(jsonEncode({'docs': []}), 200);
        }
        requestedQueries.add(request.url.toString());

        if (requestedQueries.length == 1) {
          // Intent 1: returns totalItems 0
          return http.Response(jsonEncode({'totalItems': 0, 'items': []}), 200);
        } else {
          // Intent 2: returns match
          return http.Response(
            jsonEncode({
              'totalItems': 1,
              'items': [
                {
                  'volumeInfo': {
                    'title': 'Crònica de la veritat oculta',
                    'description': 'Recull de contes de Pere Calders.',
                  }
                }
              ]
            }),
            200,
          );
        }
      });

      final service = BookEnrichmentService(httpClient: mockClient);
      final data = await service.fetchEnrichmentData(
        title: 'Crònica de la veritat oculta',
        author: 'Pere Calders',
      );

      expect(requestedQueries.length, 2);
      expect(data, isNotNull);
      expect(data!.synopsis, 'Recull de contes de Pere Calders.');
      // Quan infoLink és absent, fallback infoUrl apunta a books.google.com amb query codificat
      expect(data.infoUrl, contains('books.google.com/books?q='));
      expect(data.infoUrl, contains('Cr%C3%B2nica'));
    });

    test('Assigns fallback books.google.com infoUrl when volumeInfo does not provide infoLink', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'openlibrary.org') {
          return http.Response(jsonEncode({'docs': []}), 200);
        }
        return http.Response(
          jsonEncode({
            'totalItems': 1,
            'items': [
              {
                'volumeInfo': {
                  'title': 'Sense Enllaç Directe',
                  'description': 'Descripció sense infoLink',
                }
              }
            ]
          }),
          200,
        );
      });

      final service = BookEnrichmentService(httpClient: mockClient);
      final data = await service.fetchEnrichmentData(
        title: 'Sense Enllaç',
        author: 'Autor Test',
      );

      expect(data, isNotNull);
      expect(data!.infoUrl, 'https://books.google.com/books?q=Sense%20Enlla%C3%A7%20Autor%20Test');
    });

    test('Injects key parameter in Google Books query when key starts with AIzaSy', () async {
      String? requestedQuery;
      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.googleapis.com') {
          requestedQuery = request.url.query;
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'volumeInfo': {
                    'title': 'Test Clau AIzaSy',
                    'description': 'Descripció amb clau AIzaSy',
                  }
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = BookEnrichmentService(
        httpClient: mockClient,
        googleBooksApiKey: 'AIzaSyTestValidGoogleKey123',
      );
      expect(service.hasValidGoogleBooksApiKey, isTrue);

      final data = await service.fetchEnrichmentData(
        title: 'Test Clau AIzaSy',
        author: 'Autor',
      );

      expect(data, isNotNull);
      expect(requestedQuery, contains('key=AIzaSyTestValidGoogleKey123'));
    });

    test('Does NOT inject key parameter when key starts with AQ. (AI Studio) or is empty', () async {
      String? requestedQuery;
      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.googleapis.com') {
          requestedQuery = request.url.query;
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'volumeInfo': {
                    'title': 'Test Clau AQ',
                    'description': 'Descripció sense clau injectada',
                  }
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = BookEnrichmentService(
        httpClient: mockClient,
        googleBooksApiKey: 'AQ.DummyTestKeyOnly',
      );
      expect(service.hasValidGoogleBooksApiKey, isFalse);

      final data = await service.fetchEnrichmentData(
        title: 'Test Clau AQ',
        author: 'Autor',
      );

      expect(data, isNotNull);
      expect(requestedQuery, isNotNull);
      expect(requestedQuery, isNot(contains('key=')));
    });

    test('Falls back to Open Library when Google Books returns 401 or 429', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.googleapis.com') {
          return http.Response('Unauthorized', 401);
        } else if (request.url.host == 'openlibrary.org') {
          if (request.url.path == '/search.json') {
            return http.Response(
              jsonEncode({
                'docs': [
                  {
                    'key': '/works/OL401W',
                    'title': 'Fallback per 401',
                    'first_publish_year': 2022,
                    'cover_i': 998877,
                  }
                ]
              }),
              200,
            );
          } else if (request.url.path == '/works/OL401W.json') {
            return http.Response(
              jsonEncode({'description': 'Sinopsi recuperada d\'Open Library post 401.'}),
              200,
            );
          }
        }
        return http.Response('Not found', 404);
      });

      final service = BookEnrichmentService(httpClient: mockClient);
      final data = await service.fetchEnrichmentData(
        title: 'Fallback per 401',
        author: 'Autor',
      );

      expect(data, isNotNull);
      expect(data!.synopsis, 'Sinopsi recuperada d\'Open Library post 401.');
      expect(data.coverUrl, 'https://covers.openlibrary.org/b/id/998877-M.jpg');
      expect(data.infoUrl, 'https://openlibrary.org/works/OL401W');
    });

    test('Skips Intent 2 when Google Books returns 429 or 401', () async {
      final List<String> requestedUrls = [];
      final mockClient = MockClient((request) async {
        requestedUrls.add(request.url.toString());

        if (request.url.host == 'openlibrary.org') {
          return http.Response(jsonEncode({'docs': []}), 200);
        } else if (request.url.host == 'www.googleapis.com') {
          // Intent 1 returns 429
          return http.Response('Too Many Requests', 429);
        }
        return http.Response('Not Found', 404);
      });

      final service = BookEnrichmentService(httpClient: mockClient);
      final data = await service.fetchEnrichmentData(
        title: 'Llibre Inexistent Quota',
        author: 'Autor Fallback Quota',
      );

      expect(data, isNull);
      // Google Books was only called ONCE (Intent 2 was skipped because of 429)
      final googleBooksCalls = requestedUrls.where((u) => u.contains('googleapis.com')).length;
      expect(googleBooksCalls, 1);
    });

    test('fetchFromOpenLibrary directly parses search and works endpoint', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/search.json') {
          expect(request.url.queryParameters['title'], 'Mirall trencat');
          expect(request.url.queryParameters['author'], 'Mercè Rodoreda');
          return http.Response(
            jsonEncode({
              'docs': [
                {
                  'key': '/works/OL999W',
                  'cover_i': 12345,
                  'first_publish_year': 1974,
                  'number_of_pages_median': 360,
                }
              ]
            }),
            200,
          );
        } else if (request.url.path == '/works/OL999W.json') {
          return http.Response(
            jsonEncode({
              'description': {
                'type': '/type/text',
                'value': 'Novel·la coral sobre tres generacions de la família Valldaura.',
              }
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = BookEnrichmentService(httpClient: mockClient);
      final data = await service.fetchFromOpenLibrary('Mirall trencat', 'Mercè Rodoreda');

      expect(data, isNotNull);
      expect(data!.coverUrl, 'https://covers.openlibrary.org/b/id/12345-M.jpg');
      expect(data.publishedYear, '1974');
      expect(data.pageCount, 360);
      expect(data.synopsis, 'Novel·la coral sobre tres generacions de la família Valldaura.');
      expect(data.infoUrl, 'https://openlibrary.org/works/OL999W');
    });

    test('enrichAndPersistBook attempts to find missing synopsis if only coverUrl is present', () async {
      int calls = 0;
      final mockClient = MockClient((request) async {
        calls++;
        if (request.url.host == 'openlibrary.org') {
          return http.Response(jsonEncode({'docs': []}), 200);
        }
        return http.Response(
          jsonEncode({
            'totalItems': 1,
            'items': [
              {
                'volumeInfo': {
                  'description': 'Nova sinopsi trobada per al llibre amb portada.',
                }
              }
            ]
          }),
          200,
        );
      });

      final service = BookEnrichmentService(httpClient: mockClient);
      final bookWithCover = BookModel(
        id: 'book_has_cover',
        title: 'Ja té portada',
        author: 'Autor',
        shelfCode: 'E1-B1',
        positionIndex: 1,
        coverUrl: 'https://example.com/portada.jpg',
        enrichmentAttempts: 0,
        createdAt: DateTime.now(),
      );

      final result = await service.enrichAndPersistBook(
        book: bookWithCover,
        libraryId: '',
      );

      expect(calls, greaterThan(0));
      expect(result.coverUrl, 'https://example.com/portada.jpg');
      expect(result.synopsis, 'Nova sinopsi trobada per al llibre amb portada.');
      expect(result.enrichmentAttempts, 1);
    });

    test('fetchEnrichmentData complements Google Books synopsis with Open Library cover when Google Books lacks cover', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.googleapis.com') {
          // Google Books té sinopsi però NO té imageLinks/portada
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'volumeInfo': {
                    'title': 'Llibre Híbrid',
                    'description': 'Sinopsi exclusiva de Google Books.',
                    'pageCount': 250,
                  }
                }
              ]
            }),
            200,
          );
        } else if (request.url.host == 'openlibrary.org') {
          // Open Library té la portada!
          if (request.url.path == '/search.json') {
            return http.Response(
              jsonEncode({
                'docs': [
                  {
                    'key': '/works/OL_HYBRID_1',
                    'cover_i': 554433,
                    'first_publish_year': 2018,
                  }
                ]
              }),
              200,
            );
          }
        }
        return http.Response('Not found', 404);
      });

      BookEnrichmentService.clearCache();
      final service = BookEnrichmentService(httpClient: mockClient);
      final data = await service.fetchEnrichmentData(
        title: 'Llibre Híbrid',
        author: 'Autor',
      );

      expect(data, isNotNull);
      // Sinopsi obtinguda de Google Books
      expect(data!.synopsis, 'Sinopsi exclusiva de Google Books.');
      // Portada completada des d'Open Library
      expect(data.coverUrl, 'https://covers.openlibrary.org/b/id/554433-M.jpg');
      expect(data.pageCount, 250);
    });

    test('lookupAuthorByTitle retrieves author from Google Books', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.googleapis.com') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'volumeInfo': {
                    'title': 'La plaça del Diamant',
                    'authors': ['Mercè Rodoreda'],
                  }
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      BookEnrichmentService.clearCache();
      final service = BookEnrichmentService(httpClient: mockClient);
      final author = await service.lookupAuthorByTitle('La plaça del Diamant');

      expect(author, 'Mercè Rodoreda');
    });

    test('lookupAuthorByTitle falls back to Open Library when Google Books has no author', () async {
      final mockClient = MockClient((request) async {
        if (request.url.host == 'www.googleapis.com') {
          return http.Response(
            jsonEncode({
              'items': [
                {
                  'volumeInfo': {
                    'title': 'Títol Sense Autor A Google',
                  }
                }
              ]
            }),
            200,
          );
        } else if (request.url.host == 'openlibrary.org') {
          return http.Response(
            jsonEncode({
              'docs': [
                {
                  'title': 'Títol Sense Autor A Google',
                  'author_name': ['Joan Fuster'],
                }
              ]
            }),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      BookEnrichmentService.clearCache();
      final service = BookEnrichmentService(httpClient: mockClient);
      final author = await service.lookupAuthorByTitle('Títol Sense Autor A Google');

      expect(author, 'Joan Fuster');
    });

    test('lookupAuthorByTitle returns null for empty title', () async {
      final service = BookEnrichmentService();
      expect(await service.lookupAuthorByTitle(''), isNull);
      expect(await service.lookupAuthorByTitle('   '), isNull);
    });
  });
}
