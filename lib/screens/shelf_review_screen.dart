import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/feedback/app_feedback.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';
import '../models/bookcase_model.dart';
import '../models/detected_book_spine.dart';
import '../services/bookcase_service.dart';
import '../services/book_enrichment_service.dart';

/// Pantalla de revisió interactiva (Human-in-the-loop) dels lloms detectats per Gemini
class ShelfReviewScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String? photoUrl;
  final String libraryId;
  final BookcaseModel bookcase;
  final int shelfIndex;
  final List<DetectedBookSpine> initialDetectedSpines;
  final List<BookModel>? existingBooks;
  final bool isRetroactiveEdit;
  final BookcaseService? bookcaseService;
  final FirebaseStorage? storageInstance;
  final BookEnrichmentService? enrichmentService;

  const ShelfReviewScreen({
    super.key,
    required this.imageBytes,
    this.photoUrl,
    required this.libraryId,
    required this.bookcase,
    required this.shelfIndex,
    required this.initialDetectedSpines,
    this.existingBooks,
    this.isRetroactiveEdit = false,
    this.bookcaseService,
    this.storageInstance,
    this.enrichmentService,
  });

  @override
  State<ShelfReviewScreen> createState() => _ShelfReviewScreenState();
}

class _ShelfReviewScreenState extends State<ShelfReviewScreen> {
  late final BookcaseService _bookcaseService;
  late final BookEnrichmentService _enrichmentService;
  late List<DetectedBookSpine> _spines;
  bool _isSaving = false;
  ui.Image? _decodedImage;
  String? _selectedSpineId;
  bool _isDrawingMode = false;
  Offset? _dragStart;
  Offset? _dragCurrent;

  @override
  void initState() {
    super.initState();
    _bookcaseService = widget.bookcaseService ?? BookcaseService();
    _enrichmentService = widget.enrichmentService ?? BookEnrichmentService();

    if (widget.isRetroactiveEdit && widget.existingBooks != null) {
      final existing = widget.existingBooks!;
      final count = math.max(1, existing.length);
      final double widthPerBook = (1000.0 / count).clamp(40.0, 300.0);

      _spines = existing.asMap().entries.map((entry) {
        final idx = entry.key;
        final book = entry.value;

        List<int> box;
        if (book.box != null && book.box!.length == 4) {
          box = List<int>.from(book.box!);
        } else {
          final xmin = (idx * widthPerBook).clamp(0.0, 950.0).toInt();
          final xmax = math.min(1000.0, (xmin + widthPerBook)).toInt();
          box = [100, xmin, 900, xmax];
        }

        return DetectedBookSpine(
          id: book.id,
          title: book.title,
          author: book.author.isNotEmpty ? book.author : null,
          box: box,
          isManual: book.box == null,
        );
      }).toList();
    } else {
      _spines = List.from(widget.initialDetectedSpines);
    }
    _spines.sort((a, b) => a.xmin.compareTo(b.xmin));

    if (widget.imageBytes.isNotEmpty) {
      _decodeImage();
    } else if (widget.photoUrl != null && widget.photoUrl!.isNotEmpty) {
      _resolveNetworkImage();
    }
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

  Future<void> _resolveNetworkImage() async {
    if (widget.photoUrl == null || widget.photoUrl!.isEmpty) return;
    try {
      final imageProvider = NetworkImage(widget.photoUrl!);
      final stream = imageProvider.resolve(const ImageConfiguration());
      stream.addListener(
        ImageStreamListener((info, _) {
          if (mounted && _decodedImage == null) {
            setState(() {
              _decodedImage = info.image;
            });
          }
        }, onError: (e, s) {
          debugPrint('Error resolent dimensions de photoUrl: $e');
        }),
      );
    } catch (_) {}
  }

  Future<void> _lookupAuthorForField({
    required TextEditingController titleController,
    required TextEditingController authorController,
    required void Function(bool isSearching) setSearching,
    required BuildContext sheetContext,
  }) async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      AppFeedback.showWarning(sheetContext, 'Escriu primer el títol del llibre per cercar l\'autor/a.');
      return;
    }

    setSearching(true);
    try {
      final foundAuthor = await _enrichmentService.lookupAuthorByTitle(title);
      if (!sheetContext.mounted) return;

      if (foundAuthor != null && foundAuthor.isNotEmpty) {
        authorController.text = foundAuthor;
        AppFeedback.showSuccess(sheetContext, 'S\'ha trobat l\'autor/a: "$foundAuthor"');
      } else {
        AppFeedback.showInfo(sheetContext, 'No s\'ha trobat l\'autor/a automàticament.');
      }
    } catch (_) {
      if (sheetContext.mounted) {
        AppFeedback.showError(sheetContext, 'Error en consultar el servei d\'autors.');
      }
    } finally {
      setSearching(false);
    }
  }

  void _showEditSpineBottomSheet(DetectedBookSpine spine) {
    setState(() {
      _selectedSpineId = spine.id;
    });

    final titleController = TextEditingController(text: spine.title);
    final authorController = TextEditingController(text: spine.author ?? '');
    bool isSearchingAuthor = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                        Expanded(
                          child: Text(
                            spine.isManual ? 'Corregir llom manual' : 'Corregir llom detectat',
                            style: const TextStyle(
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
                        suffixIcon: isSearchingAuthor
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                key: const Key('auto_fill_spine_author_edit'),
                                icon: const Icon(Icons.auto_fix_high_rounded, color: AppColors.primary),
                                tooltip: 'Cercar l\'autor/a automàticament',
                                onPressed: () async {
                                  await _lookupAuthorForField(
                                    titleController: titleController,
                                    authorController: authorController,
                                    setSearching: (val) => setSheetState(() => isSearchingAuthor = val),
                                    sheetContext: sheetContext,
                                  );
                                },
                              ),
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

  void _showAddManualSpineDialog({List<int>? box}) {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    bool isSearchingAuthor = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                          child: Icon(
                            box != null ? Icons.draw_rounded : Icons.add_box_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          box != null ? 'Catalogar llom marcat' : 'Afegir llom manualment',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ],
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
                        suffixIcon: isSearchingAuthor
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : IconButton(
                                key: const Key('auto_fill_spine_author'),
                                icon: const Icon(Icons.auto_fix_high_rounded, color: AppColors.primary),
                                tooltip: 'Cercar l\'autor/a automàticament',
                                onPressed: () async {
                                  await _lookupAuthorForField(
                                    titleController: titleController,
                                    authorController: authorController,
                                    setSearching: (val) => setSheetState(() => isSearchingAuthor = val),
                                    sheetContext: sheetContext,
                                  );
                                },
                              ),
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
                            final chosenBox = box ?? [100, 100, 900, 250];
                            final newSpine = DetectedBookSpine(
                              id: 'manual_${DateTime.now().microsecondsSinceEpoch}',
                              title: title,
                              author: authorController.text.trim().isEmpty
                                  ? null
                                  : authorController.text.trim(),
                              box: chosenBox,
                              isManual: true,
                            );
                            setState(() {
                              _spines.add(newSpine);
                              _spines.sort((a, b) => a.xmin.compareTo(b.xmin));
                              _selectedSpineId = newSpine.id;
                              _isDrawingMode = false;
                            });
                            Navigator.of(sheetContext).pop();
                            final newOrdinal = _spines.indexWhere((s) => s.id == newSpine.id) + 1;
                            AppFeedback.showSuccess(
                              this.context,
                              'Llom "$title" afegit a la posició #$newOrdinal de la balda',
                            );
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
      },
    );
  }

  void _handleBoxDrawn(Offset start, Offset current, double renderW, double renderH) {
    final left = math.min(start.dx, current.dx).clamp(0.0, renderW);
    final right = math.max(start.dx, current.dx).clamp(0.0, renderW);
    final top = math.min(start.dy, current.dy).clamp(0.0, renderH);
    final bottom = math.max(start.dy, current.dy).clamp(0.0, renderH);

    final width = right - left;
    final height = bottom - top;

    // Si el traç és massa petit (< 12px), es descarta per evitar tocs involuntaris
    if (width < 12 || height < 12) {
      AppFeedback.showWarning(
        context,
        'La caixa marcada és massa petita. Arrossega per cobrir tot el llom.',
      );
      return;
    }

    final ymin = ((top / renderH) * 1000).round().clamp(0, 1000);
    final xmin = ((left / renderW) * 1000).round().clamp(0, 1000);
    final ymax = ((bottom / renderH) * 1000).round().clamp(0, 1000);
    final xmax = ((right / renderW) * 1000).round().clamp(0, 1000);

    _showAddManualSpineDialog(box: [ymin, xmin, ymax, xmax]);
  }

  Future<bool?> _showReplaceOrAppendDialog(int existingCount) {
    final llibreWord = existingCount == 1 ? '1 llibre' : '$existingCount llibres';
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Balda amb contingut previ'),
          content: Text(
            'La balda ja té $llibreWord. Vols substituir-los amb aquesta nova captura o mantenir-los?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: const Text('Cancel·lar'),
            ),
            OutlinedButton(
              key: const Key('keep_existing_shelf_books_button'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Mantenir i afegir'),
            ),
            ElevatedButton(
              key: const Key('replace_existing_shelf_books_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Substituir balda'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveShelf() async {
    if (widget.isRetroactiveEdit) {
      setState(() {
        _isSaving = true;
      });

      final navigator = Navigator.of(context);

      try {
        final List<BookModel> updatedBooks = [];
        final now = DateTime.now();

        for (int i = 0; i < _spines.length; i++) {
          final spine = _spines[i];
          final existingMatch = widget.existingBooks?.cast<BookModel?>().firstWhere(
            (b) => b?.id == spine.id,
            orElse: () => null,
          );

          if (existingMatch != null) {
            updatedBooks.add(
              existingMatch.copyWith(
                title: spine.title,
                author: spine.author ?? '',
                positionIndex: i + 1,
                box: spine.box,
                photoUrl: widget.photoUrl ?? existingMatch.photoUrl,
              ),
            );
          } else {
            updatedBooks.add(
              BookModel(
                id: '',
                title: spine.title,
                author: spine.author ?? '',
                shelfCode: '${widget.bookcase.id}-B${widget.shelfIndex}',
                bookcaseId: widget.bookcase.id,
                positionIndex: i + 1,
                photoUrl: widget.photoUrl,
                box: spine.box,
                createdAt: now,
              ),
            );
          }
        }

        await _bookcaseService.updateRetroactiveShelf(
          libraryId: widget.libraryId,
          shelfCode: '${widget.bookcase.id}-B${widget.shelfIndex}',
          updatedBooks: updatedBooks,
          bookcaseId: widget.bookcase.id,
        );

        if (mounted) {
          navigator.pop(true);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
          AppFeedback.showError(context, 'Error en desar els canvis de la balda: $e');
        }
      }
      return;
    }

    bool replaceExisting = false;

    try {
      final existingBooks = await _bookcaseService.getBooksForShelf(
        widget.libraryId,
        widget.bookcase.id,
        widget.shelfIndex,
      );

      if (!mounted) return;

      if (existingBooks.isNotEmpty) {
        final choice = await _showReplaceOrAppendDialog(existingBooks.length);
        if (choice == null) {
          return;
        }
        replaceExisting = choice;
      }
    } catch (e) {
      debugPrint('Error comprovant contingut previ de la balda: $e');
    }

    if (!mounted) return;

    setState(() {
      _isSaving = true;
    });

    final navigator = Navigator.of(context);

    try {
      await _bookcaseService.saveCatalogedShelf(
        libraryId: widget.libraryId,
        bookcase: widget.bookcase,
        shelfIndex: widget.shelfIndex,
        imageBytes: widget.imageBytes,
        detectedBooks: _spines,
        replaceExisting: replaceExisting,
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
        AppFeedback.showError(context, 'Error en desar la balda: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aspectRatio = _decodedImage != null
        ? _decodedImage!.width / _decodedImage!.height
        : 16 / 9;

    final spineCount = _spines.length;
    final saveButtonLabel = widget.isRetroactiveEdit
        ? 'Desar canvis a la balda'
        : (spineCount == 1
            ? 'Desar balda (1 llibre)'
            : 'Desar balda ($spineCount llibres)');

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
              widget.isRetroactiveEdit
                  ? 'Edició balda ${widget.shelfIndex}'
                  : 'Revisió · Balda ${widget.shelfIndex}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.isRetroactiveEdit
                  ? '${widget.bookcase.name} · $spineCount llibres a la balda'
                  : '${widget.bookcase.name} · $spineCount lloms detectats',
              style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(200)),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('btn_draw_spine_mode'),
            tooltip: _isDrawingMode
                ? 'Mode dibuixar llom (actiu)'
                : 'Dibuixar llom sobre la foto',
            icon: Icon(
              _isDrawingMode ? Icons.draw_rounded : Icons.draw_outlined,
              color: _isDrawingMode ? AppColors.accent : Colors.white,
            ),
            style: IconButton.styleFrom(
              backgroundColor: _isDrawingMode ? AppColors.accent.withAlpha(50) : null,
            ),
            onPressed: () {
              setState(() {
                _isDrawingMode = !_isDrawingMode;
                _dragStart = null;
                _dragCurrent = null;
              });
              if (_isDrawingMode) {
                AppFeedback.showInfo(
                  context,
                  'Mode dibuix actiu: arrossega sobre la foto per marcar un llom.',
                );
              }
            },
          ),
          IconButton(
            key: const Key('btn_add_spine_manual'),
            tooltip: 'Afegir llom manualment',
            icon: const Icon(Icons.add_box_outlined),
            onPressed: () => _showAddManualSpineDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner explicatiu adaptat segons el mode actiu
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _isDrawingMode
                  ? AppColors.primaryDark.withAlpha(210)
                  : Colors.black.withAlpha(100),
              child: Row(
                children: [
                  Icon(
                    _isDrawingMode ? Icons.draw_rounded : Icons.touch_app_rounded,
                    color: _isDrawingMode ? Colors.white : AppColors.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isDrawingMode
                          ? 'Mode dibuix actiu: arrossega sobre la foto per marcar la caixa d\'un nou llom.'
                          : 'Toca qualsevol llom per corregir el títol, autor o eliminar-lo si és un fals positiu.',
                      style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),

            // Visor de la imatge amb caixes superposades
            Expanded(
              child: Center(
                child: InteractiveViewer(
                  panEnabled: !_isDrawingMode,
                  scaleEnabled: !_isDrawingMode,
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
                              ..._spines.asMap().entries.map((entry) {
                                final spineIndex = entry.key;
                                final spine = entry.value;
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
                                    onTap: () {
                                      if (!_isDrawingMode) {
                                        _showEditSpineBottomSheet(spine);
                                      }
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary.withAlpha(70)
                                            : (spine.isManual
                                                ? AppColors.accent.withAlpha(60)
                                                : AppColors.primary.withAlpha(38)),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : (spine.isManual ? AppColors.accent : AppColors.primary),
                                          width: isSelected ? 2.5 : 1.8,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          // Indicador d'índex ordinal #N
                                          Positioned(
                                            top: 2,
                                            left: 2,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: spine.isManual ? AppColors.accent : AppColors.primary,
                                                borderRadius: BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                '#${spineIndex + 1}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Etiqueta flotant amb el títol del llibre
                                          Positioned(
                                            top: 16,
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
                                          // Indicador (Manual) si s'ha afegit manualment
                                          if (spine.isManual)
                                            Positioned(
                                              bottom: 4,
                                              left: 2,
                                              right: 2,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                                decoration: BoxDecoration(
                                                  color: AppColors.accent,
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: const Text(
                                                  '(Manual)',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 9,
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

                              // Capa interactiva de dibuix de caixa quan el mode està actiu
                              if (_isDrawingMode)
                                Positioned.fill(
                                  child: GestureDetector(
                                    key: const Key('gesture_draw_spine'),
                                    behavior: HitTestBehavior.opaque,
                                    onPanStart: (details) {
                                      setState(() {
                                        _dragStart = details.localPosition;
                                        _dragCurrent = details.localPosition;
                                      });
                                    },
                                    onPanUpdate: (details) {
                                      setState(() {
                                        _dragCurrent = details.localPosition;
                                      });
                                    },
                                    onPanEnd: (details) {
                                      final start = _dragStart;
                                      final current = _dragCurrent;
                                      setState(() {
                                        _dragStart = null;
                                        _dragCurrent = null;
                                      });
                                      if (start != null && current != null) {
                                        _handleBoxDrawn(start, current, renderW, renderH);
                                      }
                                    },
                                    child: CustomPaint(
                                      painter: _ManualBoxPainter(
                                        start: _dragStart,
                                        current: _dragCurrent,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Llista / Xips de revisió dels lloms ordenats per posició física
            if (_spines.isNotEmpty)
              Container(
                height: 52,
                color: Colors.black.withAlpha(140),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: _spines.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final spine = _spines[idx];
                    final isSelected = spine.id == _selectedSpineId;
                    return ActionChip(
                      key: Key('chip_spine_${spine.id}'),
                      avatar: CircleAvatar(
                        backgroundColor: isSelected ? Colors.white : AppColors.primary,
                        radius: 10,
                        child: Text(
                          '${idx + 1}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppColors.primary : Colors.white,
                          ),
                        ),
                      ),
                      label: Text(
                        '${spine.title}${spine.isManual ? ' (Manual)' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.textMain,
                        ),
                      ),
                      color: WidgetStatePropertyAll(
                        isSelected
                            ? AppColors.primary
                            : (spine.isManual ? const Color(0xFFFFF7F2) : Colors.white),
                      ),
                      backgroundColor: isSelected
                          ? AppColors.primary
                          : (spine.isManual ? const Color(0xFFFFF7F2) : Colors.white),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : (spine.isManual ? AppColors.accent : const Color(0xFFDCD6D0)),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      onPressed: () => _showEditSpineBottomSheet(spine),
                    );
                  },
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
                    _isSaving
                        ? (widget.isRetroactiveEdit
                            ? 'Desant canvis a la balda...'
                            : 'Desant llibres a la balda...')
                        : saveButtonLabel,
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

/// Dibuixa un rectangle interactiu en temps real sobre la imatge mentre l'usuari arrossega el cursor/dit
class _ManualBoxPainter extends CustomPainter {
  final Offset? start;
  final Offset? current;

  _ManualBoxPainter({this.start, this.current});

  @override
  void paint(Canvas canvas, Size size) {
    if (start == null || current == null) return;

    final left = math.min(start!.dx, current!.dx);
    final top = math.min(start!.dy, current!.dy);
    final right = math.max(start!.dx, current!.dx);
    final bottom = math.max(start!.dy, current!.dy);
    final rect = Rect.fromLTRB(left, top, right, bottom);

    // Fons semitransparent terracota
    final fillPaint = Paint()
      ..color = AppColors.primary.withAlpha(75)
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // Vora blanca nítida
    final borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);

    // Vora exterior terracota per a contrast òptim
    final outerPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect.inflate(1), outerPaint);
  }

  @override
  bool shouldRepaint(covariant _ManualBoxPainter oldDelegate) {
    return oldDelegate.start != start || oldDelegate.current != current;
  }
}
