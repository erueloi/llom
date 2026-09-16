import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../models/detected_book_spine.dart';

/// Excepció específica de ShelfVisionService amb detalls sobre quotes i claus
class GeminiVisionException implements Exception {
  final String message;
  final String? rawError;
  final bool isQuotaExhausted;
  final bool isInvalidKey;

  const GeminiVisionException(
    this.message, {
    this.rawError,
    this.isQuotaExhausted = false,
    this.isInvalidKey = false,
  });

  @override
  String toString() => message;
}

/// Servei per detectar i segmentar els lloms de llibres d'una balda utilitzant Gemini Flash
class ShelfVisionService {
  static const String _prefApiKey = 'gemini_api_key';

  static const String shelfVisionPrompt = '''
Analitza la fotografia d'aquesta balda d'estanteria. Identifica cada llom de llibre individual visible d'esquerra a dreta.
Per a cada llibre detectat, retorna un objecte JSON amb:
- 'title': Títol del llibre (en majúscules/minúscules netes, o 'Sense títol' si no és llegible).
- 'author': Nom de l'autor (o null si no apareix).
- 'box': Coordenades normalitzades [ymin, xmin, ymax, xmax] de 0 a 1000 relatives a la imatge sencera.
Retorna exclusivament l'esquema: { "books": [ { "title": string, "author": string | null, "box": [number, number, number, number] } ] }
''';

  final String? _apiKey;

  ShelfVisionService({String? apiKey}) : _apiKey = apiKey;

  /// Obté la clau d'API efectiva:
  /// 1. Font primària: const String.fromEnvironment('GEMINI_API_KEY')
  /// 2. Fallback: SharedPreferences ('gemini_api_key')
  static Future<String?> getEffectiveApiKey() async {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.trim().isNotEmpty) {
      return envKey.trim();
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKey = prefs.getString(_prefApiKey)?.trim();
      if (savedKey != null && savedKey.isNotEmpty) {
        return savedKey;
      }
    } catch (_) {
      // Ignora errors de SharedPreferences en entorns aïllats
    }

    return null;
  }

  /// Desa la clau d'API a SharedPreferences per a ús posterior
  static Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefApiKey, apiKey.trim());
  }

  /// Elimina la clau d'API desada a SharedPreferences
  static Future<void> deleteApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefApiKey);
  }

  /// Mostra una Bottom Sheet per demanar la clau d'API si no està configurada,
  /// o de manera forçada si forceShow és true (per exemple des de configuració/perfil).
  static Future<String?> promptApiKeyIfNeeded(
    BuildContext context, {
    bool forceShow = false,
  }) async {
    final existing = await getEffectiveApiKey();
    if (!forceShow && existing != null && existing.isNotEmpty) {
      return existing;
    }

    if (!context.mounted) return null;

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => _ApiKeyPromptBottomSheet(initialKey: existing),
    );
  }

  /// Llista de models candidats per ordre de preferència
  static const List<String> candidateModels = [
    'gemini-flash-latest',
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-2.5-flash',
  ];

  /// Analitza una imatge de balda i retorna els lloms detectats
  Future<List<DetectedBookSpine>> analyzeShelfImage(
    Uint8List imageBytes, {
    String? apiKeyOverride,
    String? modelOverride,
  }) async {
    final key = apiKeyOverride ?? _apiKey ?? await getEffectiveApiKey();
    if (key == null || key.trim().isEmpty) {
      throw const GeminiVisionException(
        'No s\'ha configurat cap clau d\'API de Gemini. '
        'Configura GEMINI_API_KEY com a variable d\'entorn o introdueix-la a l\'aplicació.',
        isInvalidKey: true,
      );
    }

    final modelsToTry = modelOverride != null ? [modelOverride] : candidateModels;
    Object? lastError;

    for (final modelName in modelsToTry) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: key.trim(),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
          ),
        );

        final promptPart = TextPart(shelfVisionPrompt);
        final imagePart = DataPart('image/jpeg', imageBytes);

        final response = await model.generateContent([
          Content.multi([promptPart, imagePart]),
        ]);

        final rawText = response.text;
        if (rawText == null || rawText.trim().isEmpty) {
          return [];
        }

        return parseGeminiResponse(rawText);
      } catch (e) {
        lastError = e;
        final errorStr = e.toString();
        // Si és un error de model no trobat (404), prova el següent model candidat
        if (errorStr.contains('not found') || errorStr.contains('404')) {
          continue;
        }
        // Si és un altre tipus d'error (429 exhaurit, 403 clau invàlida, etc.), atura't
        break;
      }
    }

    // Processar l'error amb missatges entenedors en català
    final rawMsg = lastError?.toString() ?? 'Error desconegut';
    if (rawMsg.contains('429') ||
        rawMsg.contains('prepayment credits are depleted') ||
        rawMsg.contains('RESOURCE_EXHAUSTED') ||
        rawMsg.contains('Quota exceeded')) {
      throw GeminiVisionException(
        'Els crèdits o la quota de la teva clau de Gemini s\'han esgotat (Error 429). '
        'Genera una nova clau gratuïta a Google AI Studio o revisa la facturació.',
        rawError: rawMsg,
        isQuotaExhausted: true,
      );
    }
    if (rawMsg.contains('API_KEY_INVALID') ||
        rawMsg.contains('API key not valid') ||
        rawMsg.contains('403')) {
      throw GeminiVisionException(
        'La clau d\'API de Gemini no és vàlida (Error 403). '
        'Revisa-la o introdueix-ne una de nova.',
        rawError: rawMsg,
        isInvalidKey: true,
      );
    }
    if (rawMsg.contains('not found for API version') || rawMsg.contains('404')) {
      throw GeminiVisionException(
        'Cap dels models de Gemini provats ($modelsToTry) està disponible a l\'API.',
        rawError: rawMsg,
      );
    }

    throw GeminiVisionException(
      'Error en analitzar la balda amb Gemini: $rawMsg',
      rawError: rawMsg,
    );
  }

  /// Deserialitza i valida la resposta JSON retornada per Gemini
  static List<DetectedBookSpine> parseGeminiResponse(String rawJson) {
    String cleaned = rawJson.trim();
    // Neteja possibles blocs markdown ```json ... ```
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    try {
      final decoded = jsonDecode(cleaned);
      List<dynamic> booksList = [];

      if (decoded is Map<String, dynamic>) {
        if (decoded['books'] is List) {
          booksList = decoded['books'] as List<dynamic>;
        } else if (decoded['spines'] is List) {
          booksList = decoded['spines'] as List<dynamic>;
        }
      } else if (decoded is List) {
        booksList = decoded;
      }

      final List<DetectedBookSpine> result = [];
      for (int i = 0; i < booksList.length; i++) {
        final item = booksList[i];
        if (item is Map<String, dynamic>) {
          result.add(DetectedBookSpine.fromMap(item, id: 'detected_$i'));
        }
      }

      // Ordenar els llibres d'esquerra a dreta segons xmin (box[1])
      result.sort((a, b) => a.xmin.compareTo(b.xmin));

      return result;
    } catch (e) {
      debugPrint('Error en interpretar resposta JSON de Gemini: $e');
      return [];
    }
  }
}

class _ApiKeyPromptBottomSheet extends StatefulWidget {
  final String? initialKey;

  const _ApiKeyPromptBottomSheet({this.initialKey});

  @override
  State<_ApiKeyPromptBottomSheet> createState() => _ApiKeyPromptBottomSheetState();
}

class _ApiKeyPromptBottomSheetState extends State<_ApiKeyPromptBottomSheet> {
  late final TextEditingController _controller;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialKey ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasExistingKey = widget.initialKey != null && widget.initialKey!.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(120),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Clau d\'API de Gemini',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ),
              if (hasExistingKey)
                IconButton(
                  key: const Key('gemini_api_key_delete_btn'),
                  tooltip: 'Eliminar clau',
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  onPressed: () async {
                    await ShelfVisionService.deleteApiKey();
                    if (context.mounted) {
                      Navigator.of(context).pop('');
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Per detectar els lloms de la balda amb Gemini Flash, introdueix la teva clau d\'API de Google AI Studio.',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            key: const Key('gemini_api_key_input'),
            controller: _controller,
            obscureText: _obscure,
            decoration: InputDecoration(
              hintText: 'AIzaSy...',
              prefixIcon: const Icon(Icons.key_rounded, color: AppColors.primary),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              key: const Key('gemini_api_key_save_btn'),
              onPressed: () async {
                final key = _controller.text.trim();
                if (key.isNotEmpty) {
                  await ShelfVisionService.saveApiKey(key);
                  if (context.mounted) {
                    Navigator.of(context).pop(key);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Desar i continuar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
