import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llom/models/detected_book_spine.dart';
import 'package:llom/services/shelf_vision_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ShelfVisionService and DetectedBookSpine tests', () {
    test('Parses direct JSON list and sorts left to right by xmin', () {
      const jsonStr = '''
      [
        {"box_2d": [100, 450, 800, 600], "label": "Segon Llibre", "author": "Autor 2"},
        {"box_2d": [120, 80, 810, 220], "label": "Primer Llibre", "author": "Autor 1"},
        {"box_2d": [90, 700, 790, 850], "label": "Tercer Llibre", "author": "Autor 3"}
      ]
      ''';

      final spines = ShelfVisionService.parseGeminiResponse(jsonStr);
      expect(spines.length, 3);
      expect(spines[0].title, 'Primer Llibre');
      expect(spines[0].author, 'Autor 1');
      expect(spines[0].xmin, 80);

      expect(spines[1].title, 'Segon Llibre');
      expect(spines[1].author, 'Autor 2');
      expect(spines[1].xmin, 450);

      expect(spines[2].title, 'Tercer Llibre');
      expect(spines[2].author, 'Autor 3');
      expect(spines[2].xmin, 700);
    });

    test('Parses markdown fence json block', () {
      const jsonStr = '''
      ```json
      [
        {"box_2d": [150, 200, 750, 300], "label": "La plaça del Diamant", "author": "Mercè Rodoreda"}
      ]
      ```
      ''';

      final spines = ShelfVisionService.parseGeminiResponse(jsonStr);
      expect(spines.length, 1);
      expect(spines.first.title, 'La plaça del Diamant');
      expect(spines.first.author, 'Mercè Rodoreda');
      expect(spines.first.ymin, 150);
      expect(spines.first.xmin, 200);
      expect(spines.first.ymax, 750);
      expect(spines.first.xmax, 300);
    });

    test('Parses json object containing "spines" or "books" property', () {
      const jsonStr = '''
      {
        "spines": [
          {"box_2d": [50, 100, 900, 250], "title": "Pedra de tartera", "author": "Maria Barbal"}
        ]
      }
      ''';

      final spines = ShelfVisionService.parseGeminiResponse(jsonStr);
      expect(spines.length, 1);
      expect(spines.first.title, 'Pedra de tartera');
      expect(spines.first.author, 'Maria Barbal');
    });

    test('Clamps coordinates and falls back to default title if empty', () {
      const jsonStr = '''
      [
        {"box_2d": [-50, -20, 1200, 1100], "label": "", "author": null}
      ]
      ''';

      final spines = ShelfVisionService.parseGeminiResponse(jsonStr);
      expect(spines.length, 1);
      expect(spines.first.title, 'Sense títol');
      expect(spines.first.author, isNull);
      expect(spines.first.ymin, 0);
      expect(spines.first.xmin, 0);
      expect(spines.first.ymax, 1000);
      expect(spines.first.xmax, 1000);
    });

    test('DetectedBookSpine converts to and from map', () {
      final spine = DetectedBookSpine(
        id: 's_1',
        title: 'Tirant lo Blanc',
        author: 'Joanot Martorell',
        box: [100, 200, 800, 350],
      );

      final map = spine.toMap();
      expect(map['title'], 'Tirant lo Blanc');
      expect(map['author'], 'Joanot Martorell');
      expect(map['box'], [100, 200, 800, 350]);

      final fromMap = DetectedBookSpine.fromMap(map, id: 's_from_map');
      expect(fromMap.id, 's_from_map');
      expect(fromMap.title, 'Tirant lo Blanc');
      expect(fromMap.author, 'Joanot Martorell');
      expect(fromMap.box, [100, 200, 800, 350]);
    });

    test('Gracefully returns empty list on invalid JSON string', () {
      final spines = ShelfVisionService.parseGeminiResponse('Invalid response from AI');
      expect(spines, isEmpty);
    });
  });

  group('ShelfVisionService API Key management', () {
    test('Stores and retrieves API key from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});

      expect(await ShelfVisionService.getEffectiveApiKey(), isNull);

      await ShelfVisionService.saveApiKey('AIzaSyTestKey12345');
      expect(await ShelfVisionService.getEffectiveApiKey(), 'AIzaSyTestKey12345');
    });

    test('Candidate models list contains active Gemini flash models', () {
      expect(ShelfVisionService.candidateModels, contains('gemini-flash-latest'));
      expect(ShelfVisionService.candidateModels, contains('gemini-3.6-flash'));
    });

    test('GeminiVisionException has correct properties and toString', () {
      const ex = GeminiVisionException(
        'Quota esgotada',
        rawError: '429 RESOURCE_EXHAUSTED',
        isQuotaExhausted: true,
      );
      expect(ex.message, 'Quota esgotada');
      expect(ex.rawError, '429 RESOURCE_EXHAUSTED');
      expect(ex.isQuotaExhausted, isTrue);
      expect(ex.isInvalidKey, isFalse);
      expect(ex.toString(), 'Quota esgotada');
    });
  });
}
