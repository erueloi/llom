import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/theme/app_colors.dart';
import '../models/bookcase_model.dart';
import '../models/detected_book_spine.dart';
import '../services/bookcase_service.dart';

/// Pantalla de revisió interactiva (Human-in-the-loop) dels lloms detectats per Gemini
class ShelfReviewScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String? photoUrl;
  final String libraryId;
  final BookcaseModel bookcase;
  final int shelfIndex;
  final List<DetectedBookSpine> initialDetectedSpines;
  final BookcaseService? bookcaseService;
  final FirebaseStorage? storageInstance;

  const ShelfReviewScreen({
    super.key,
    required this.imageBytes,
    this.photoUrl,
    required this.libraryId,
    required this.bookcase,
    required this.shelfIndex,
    required this.initialDetectedSpines,
    this.bookcaseService,
    this.storageInstance,
  });

  @override
  State<ShelfReviewScreen> createState() => _ShelfReviewScreenState();
}

class _ShelfReviewScreenState extends State<ShelfReviewScreen> {
  late final BookcaseService _bookcaseService;
  late List<DetectedBookSpine> _spines;
  bool _isSaving = false;
  ui.Image? _decodedImage;
  String? _selectedSpineId;

  @override
  void initState() {
    super.initState();
    _bookcaseService = widget.bookcaseService ?? BookcaseService();
    _spines = List.from(widget.initialDetectedSpines);
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    if (widget.imageBytes.isEmpty) return;
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
        });
      }
    } catch (_) {
      // Si falla la descodificació en memòria, s'usarà relació d'aspecte per defecte
    }
  }

  void _showEditSpineBottomSheet(DetectedBookSpine spine) {
    setState(() {
      _selectedSpineId = spine.id;
    });

    final titleController = TextEditingController(text: spine.title);
    final authorController = TextEditingController(text: spine.author ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
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
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Corregir llom detectat',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const Key('btn_delete_spine'),
                      tooltip: 'Eliminar llom (fals positiu)',
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _spines.removeWhere((s) => s.id == spine.id);
                          _selectedSpineId = null;
                        });
                        Navigator.of(sheetContext).pop();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('field_edit_spine_title'),
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Títol del llibre *',
                    prefixIcon: const Icon(Icons.book_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('field_edit_spine_author'),
                  controller: authorController,
                  decoration: InputDecoration(
                    labelText: 'Autor / Autora (opcional)',
                    prefixIcon: const Icon(Icons.person_rounded, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('btn_save_spine_changes'),
                    onPressed: () {
                      final newTitle = titleController.text.trim();
                      if (newTitle.isNotEmpty) {
                        setState(() {
                          spine.title = newTitle;
                          spine.author = authorController.text.trim().isEmpty
                              ? null
                              : authorController.text.trim();
                          _selectedSpineId = null;
                        });
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Desar canvis', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      if (mounted) {
        setState(() {
          _selectedSpineId = null;
        });
      }
    });
  }

  void _showAddManualSpineDialog() {
    final titleController = TextEditingController();
    final authorController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 16,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
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
                const Text(
                  'Afegir llom manualment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('field_add_spine_title'),
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Títol del llibre *',
                    prefixIcon: const Icon(Icons.book_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('field_add_spine_author'),
                  controller: authorController,
                  decoration: InputDecoration(
                    labelText: 'Autor / Autora (opcional)',
                    prefixIcon: const Icon(Icons.person_rounded, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    key: const Key('btn_save_new_spine'),
                    onPressed: () {
                      final title = titleController.text.trim();
                      if (title.isNotEmpty) {
                        setState(() {
                          _spines.add(
                            DetectedBookSpine(
                              id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
                              title: title,
                              author: authorController.text.trim().isEmpty
                                  ? null
                                  : authorController.text.trim(),
                              box: [100, 100, 900, 250], // Caixa predeterminada
                            ),
                          );
                        });
                        Navigator.of(sheetContext).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Afegir llom', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveShelf() async {
    setState(() {
      _isSaving = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await _bookcaseService.saveCatalogedShelf(
        libraryId: widget.libraryId,
        bookcase: widget.bookcase,
        shelfIndex: widget.shelfIndex,
        imageBytes: widget.imageBytes,
        detectedBooks: _spines,
        storageInstance: widget.storageInstance,
      );

      if (mounted) {
        navigator.pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error en desar la balda: $e'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = _decodedImage != null
        ? _decodedImage!.width / _decodedImage!.height
        : 16 / 9;

    final spineCount = _spines.length;
    final saveButtonLabel = spineCount == 1
        ? 'Desar balda (1 llibre)'
        : 'Desar balda ($spineCount llibres)';

    return Scaffold(
      backgroundColor: AppColors.textMain,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Revisió · Balda ${widget.shelfIndex}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${widget.bookcase.name} · $spineCount lloms detectats',
              style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200)),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('btn_add_spine_manual'),
            tooltip: 'Afegir llom manualment',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: _showAddManualSpineDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner explicatiu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.black.withAlpha(100),
              child: const Row(
                children: [
                  Icon(Icons.touch_app_rounded, color: AppColors.accent, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Toca qualsevol llom per corregir el títol, autor o eliminar-lo si és un fals positiu.',
                      style: TextStyle(fontSize: 12.5, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            // Visor de la imatge amb caixes superposades
            Expanded(
              child: Center(
                child: InteractiveViewer(
                  minScale: 1.0,
                  maxScale: 4.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Calculem la mida amb la relació d'aspecte continguda dins l'espai
                      final maxW = constraints.maxWidth;
                      final maxH = constraints.maxHeight;

                      double renderW = maxW;
                      double renderH = renderW / aspectRatio;

                      if (renderH > maxH) {
                        renderH = maxH;
                        renderW = renderH * aspectRatio;
                      }

                      return Center(
                        child: SizedBox(
                          width: renderW,
                          height: renderH,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Imatge capturada o carregada de xarxa
                              if (widget.imageBytes.isNotEmpty)
                                Image.memory(
                                  widget.imageBytes,
                                  fit: BoxFit.fill,
                                )
                              else if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                                Image.network(
                                  widget.photoUrl!,
                                  fit: BoxFit.fill,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(color: AppColors.primary),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint(
                                      'Error carregant imatge a ShelfReviewScreen [CORS/Network] (${widget.photoUrl}): $error',
                                    );
                                    return Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.broken_image_rounded, size: 48, color: Colors.white54),
                                            const SizedBox(height: 8),
                                            const Text(
                                              'No s\'ha pogut carregar la fotografia de la balda.',
                                              style: TextStyle(color: Colors.white70, fontSize: 13),
                                              textAlign: TextAlign.center,
                                            ),
                                            if (kIsWeb) ...[
                                              const SizedBox(height: 4),
                                              const Text(
                                                'Si estàs a Flutter Web, assegura\'t que Firebase Storage tingui el CORS configurat.',
                                                style: TextStyle(color: Colors.white54, fontSize: 11),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                )
                              else
                                Container(color: Colors.black26),

                              // Caixes dels lloms superposades
                              ..._spines.map((spine) {
                                final isSelected = spine.id == _selectedSpineId;
                                final left = (spine.xmin / 1000.0) * renderW;
                                final top = (spine.ymin / 1000.0) * renderH;
                                final width = ((spine.xmax - spine.xmin) / 1000.0) * renderW;
                                final height = ((spine.ymax - spine.ymin) / 1000.0) * renderH;

                                return Positioned(
                                  left: left.clamp(0, renderW),
                                  top: top.clamp(0, renderH),
                                  width: width.clamp(16, renderW),
                                  height: height.clamp(16, renderH),
                                  child: GestureDetector(
                                    key: Key('box_${spine.id}'),
                                    onTap: () => _showEditSpineBottomSheet(spine),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withAlpha(70)
                                            : AppColors.primary.withAlpha(38),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isSelected ? Colors.white : AppColors.primary,
                                          width: isSelected ? 2.5 : 1.8,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Etiqueta flotant amb el títol del llibre
                                          Positioned(
                                            top: 4,
                                            left: 2,
                                            right: 2,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withAlpha(190),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                spine.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Botó inferior de confirmació i desat
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              color: AppColors.surface,
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  key: const Key('btn_save_cataloged_shelf'),
                  onPressed: _isSaving ? null : _saveShelf,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_rounded, size: 22),
                  label: Text(
                    _isSaving ? 'Desant llibres a la balda...' : saveButtonLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
