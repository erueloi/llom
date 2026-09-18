import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/feedback/app_feedback.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';
import '../models/bookcase_model.dart';
import '../providers/library_provider.dart';
import '../services/bookcase_service.dart';
import '../widgets/add_manual_book_dialog.dart';
import '../widgets/book_spine_widget.dart';
import 'package:image_picker/image_picker.dart';
import '../models/detected_book_spine.dart';
import '../services/shelf_vision_service.dart';
import '../services/book_enrichment_service.dart';
import '../widgets/book_detail_bottom_sheet.dart';
import 'shelf_review_screen.dart';
import 'library_stats_screen.dart';

/// Pantalla de detall d'un moble d'estanteria amb les seves baldes llistades verticalment
class BookshelfDetailScreen extends StatefulWidget {
  final BookcaseModel bookcase;
  final String libraryId;
  final BookcaseService? bookcaseService;
  final String? highlightBookId;
  final String? initialSearchQuery;
  final ImagePicker? imagePicker;
  final ShelfVisionService? shelfVisionService;
  final BookEnrichmentService? enrichmentService;

  const BookshelfDetailScreen({
    super.key,
    required this.bookcase,
    required this.libraryId,
    this.bookcaseService,
    this.highlightBookId,
    this.initialSearchQuery,
    this.imagePicker,
    this.shelfVisionService,
    this.enrichmentService,
  });

  @override
  State<BookshelfDetailScreen> createState() => _BookshelfDetailScreenState();
}

class _BookshelfDetailScreenState extends State<BookshelfDetailScreen> {
  late final BookcaseService _bookcaseService;
  late final TextEditingController _searchController;
  String _searchQuery = '';
  String? _highlightBookId;
  final Map<int, List<BookModel>> _shelfBooksOverride = {};
  bool _onlyBorrowedFilter = false;

  void _onReorderShelfBooks(
    int shelfNumber,
    int oldIndex,
    int newIndex,
    List<BookModel> currentBooks,
  ) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    if (oldIndex == newIndex) return;

    final reordered = List<BookModel>.from(currentBooks);
    final movedItem = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, movedItem);

    setState(() {
      _shelfBooksOverride[shelfNumber] = reordered;
    });

    _bookcaseService
        .updateShelfBooksOrder(
          libraryId: widget.libraryId,
          books: reordered,
        )
        .catchError((e) {
          debugPrint('Error actualitzant ordre de llibres a Firestore: $e');
        });
  }

  @override
  void initState() {
    super.initState();
    _bookcaseService = widget.bookcaseService ?? BookcaseService();
    _highlightBookId = widget.highlightBookId;
    _searchController = TextEditingController(text: widget.initialSearchQuery ?? '');
    _searchQuery = widget.initialSearchQuery?.trim().toLowerCase() ?? '';
    _searchController.addListener(() {
      final text = _searchController.text.trim().toLowerCase();
      if (_searchQuery != text) {
        setState(() {
          _searchQuery = text;
          if (_highlightBookId != null) {
            _highlightBookId = null;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCameraForShelfSelection(BuildContext context, BookcaseModel currentBookcase) {
    if (currentBookcase.shelfCount <= 1) {
      _showCaptureSourceSheet(currentBookcase, 1);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  'Quina balda vols fotografiar?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: currentBookcase.shelfCount,
                    separatorBuilder: (_, _) => const Divider(height: 8, color: AppColors.canvas),
                    itemBuilder: (ctx, idx) {
                      final shelfNum = idx + 1;
                      final pos = _getShelfPositionLabel(shelfNum, currentBookcase.shelfCount);
                      return ListTile(
                        key: Key('select_shelf_camera_$shelfNum'),
                        leading: CircleAvatar(
                          backgroundColor: AppColors.accent.withAlpha(60),
                          foregroundColor: AppColors.primary,
                          child: Text('$shelfNum', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        title: Text(
                          'Balda $shelfNum · $pos',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textMain),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textMuted),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _showCaptureSourceSheet(currentBookcase, shelfNum);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCaptureSourceSheet(BookcaseModel currentBookcase, int shelfNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                Text(
                  'Fotografiar Balda $shelfNumber',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  key: const Key('capture_option_camera'),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 24),
                  ),
                  title: const Text(
                    'Fer foto amb la càmera',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                  subtitle: const Text(
                    'Fes una foto frontal de la balda ben il·luminada',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _captureAndAnalyzeShelf(currentBookcase, shelfNumber, source: ImageSource.camera);
                  },
                ),
                const Divider(height: 14, color: AppColors.canvas),
                ListTile(
                  key: const Key('capture_option_gallery'),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 24),
                  ),
                  title: const Text(
                    'Triar de la galeria',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                  subtitle: const Text(
                    'Selecciona una fotografia que ja tinguis desada',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _captureAndAnalyzeShelf(currentBookcase, shelfNumber, source: ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEmptyShelfOptionsSheet(BookcaseModel currentBookcase, int shelfNumber) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Afegir a la Balda $shelfNumber',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tria com vols afegir contingut a aquesta balda del moble ${currentBookcase.name}.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                key: Key('empty_shelf_option_camera_$shelfNumber'),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 24),
                ),
                title: const Text(
                  'Fotografiar i catalogar balda',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
                subtitle: const Text(
                  'Fes una foto a la balda i detecta automàticament els lloms',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _showCaptureSourceSheet(currentBookcase, shelfNumber);
                },
              ),
              const Divider(height: 14, color: AppColors.canvas),
              ListTile(
                key: Key('empty_shelf_option_manual_$shelfNumber'),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 24),
                ),
                title: const Text(
                  'Afegir llibre manualment',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
                subtitle: const Text(
                  'Introdueix el títol i l\'autor/a amb formulari',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showAddManualBookDialog(
                    context,
                    libraryId: widget.libraryId,
                    bookcase: currentBookcase,
                    initialShelfIndex: shelfNumber,
                    bookcaseService: _bookcaseService,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmClearShelf(BookcaseModel currentBookcase, int shelfNumber, int bookCount) async {
    final llibresText = bookCount == 1 ? '1 llibre' : '$bookCount llibres';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Buidar Balda $shelfNumber'),
          content: Text(
            'Vols buidar la Balda $shelfNumber? S\'eliminaran els $llibresText d\'aquest prestatge.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel·lar'),
            ),
            ElevatedButton(
              key: const Key('confirm_clear_shelf_button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Buidar balda'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      try {
        await _bookcaseService.clearShelf(widget.libraryId, currentBookcase.id, shelfNumber);
        if (mounted) {
          AppFeedback.showSuccess(context, 'S\'ha buidat la Balda $shelfNumber.');
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, 'Error en buidar la balda: $e');
        }
      }
    }
  }

  Future<void> _captureAndAnalyzeShelf(
    BookcaseModel currentBookcase,
    int shelfNumber, {
    ImageSource source = ImageSource.camera,
  }) async {
    // 1. Obtenir API Key si no s'ha injectat un servei de visió
    String? apiKey;
    if (widget.shelfVisionService == null) {
      apiKey = await ShelfVisionService.promptApiKeyIfNeeded(context);
      if (!mounted || apiKey == null || apiKey.trim().isEmpty) {
        return;
      }
    }

    // 2. Capturar imatge amb ImagePicker (configurat amb maxWidth: 2048, maxHeight: 2048, imageQuality: 85)
    final picker = widget.imagePicker ?? ImagePicker();
    final XFile? photo = await picker.pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
      imageQuality: 85,
    );

    if (photo == null || !mounted) {
      return;
    }

    final bytes = await photo.readAsBytes();
    if (!mounted) return;

    // 3. Mostrar indicador de càrrega
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(40),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppColors.primary),
                SizedBox(width: 20),
                Flexible(
                  child: Text(
                    'Processant els llibres amb el far...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    List<DetectedBookSpine> detectedSpines = [];
    try {
      final visionService = widget.shelfVisionService ?? ShelfVisionService(apiKey: apiKey!);
      detectedSpines = await visionService.analyzeShelfImage(bytes);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Tancar diàleg de càrrega
        final isQuotaOrKeyError = e is GeminiVisionException && (e.isQuotaExhausted || e.isInvalidKey);
        final errorMessage = e is GeminiVisionException ? e.message : 'Error en analitzar la balda amb Gemini: $e';
        AppFeedback.showError(
          context,
          errorMessage,
          duration: Duration(seconds: isQuotaOrKeyError ? 8 : 4),
          actionLabel: isQuotaOrKeyError ? 'Canviar clau' : null,
          onAction: isQuotaOrKeyError
              ? () => ShelfVisionService.promptApiKeyIfNeeded(context, forceShow: true)
              : null,
        );
      }
      return;
    }

    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // Tancar diàleg de càrrega

    // 4. Obrir pantalla de revisió
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (ctx) => ShelfReviewScreen(
          imageBytes: bytes,
          initialDetectedSpines: detectedSpines,
          libraryId: widget.libraryId,
          bookcase: currentBookcase,
          shelfIndex: shelfNumber,
          bookcaseService: _bookcaseService,
          enrichmentService: widget.enrichmentService,
        ),
      ),
    );

    if (result == true && mounted) {
      AppFeedback.showSuccess(
        context,
        'S\'han catalogat els llibres correctament a la Balda $shelfNumber.',
      );
    }
  }

  void _showAddActionsSheet(BuildContext context, BookcaseModel currentBookcase) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  'Afegir contingut a l\'estanteria',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  key: const Key('action_camera_shelf'),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 26),
                  ),
                  title: const Text(
                    'Fotografiar balda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                  subtitle: const Text(
                    'Captura automàtica dels lloms dels teus llibres amb la càmera',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openCameraForShelfSelection(context, currentBookcase);
                  },
                ),
                const Divider(height: 14, color: AppColors.canvas),
                ListTile(
                  key: const Key('action_manual_book'),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                  ),
                  title: const Text(
                    'Afegir llibre manualment',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textMain),
                  ),
                  subtitle: const Text(
                    'Introdueix el títol, l\'autor i selecciona a quina balda va',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    showAddManualBookDialog(
                      context,
                      libraryId: widget.libraryId,
                      bookcase: currentBookcase,
                      bookcaseService: _bookcaseService,
                    );
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBookDetails(BookModel book, BookcaseModel currentBookcase, bool canEdit) {
    showBookDetailBottomSheet(
      context,
      book: book,
      bookcase: currentBookcase,
      libraryId: widget.libraryId,
      canEdit: canEdit,
      bookcaseService: _bookcaseService,
      enrichmentService: widget.enrichmentService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final libraryProvider = context.watch<LibraryProvider?>();
    final canEdit = libraryProvider?.canEdit ?? true;

    return StreamBuilder<List<BookcaseModel>>(
      stream: _bookcaseService.getBookcases(widget.libraryId),
      builder: (context, bookcaseSnapshot) {
        final bookcases = bookcaseSnapshot.data ?? [];
        final currentBookcase = bookcases.firstWhere(
          (b) => b.id == widget.bookcase.id,
          orElse: () => widget.bookcase,
        );

        return StreamBuilder<List<BookModel>>(
          stream: _bookcaseService.getBooksForBookcase(widget.libraryId, currentBookcase.id),
          builder: (context, booksSnapshot) {
            final allBooks = booksSnapshot.data ?? [];

            return Scaffold(
              backgroundColor: AppColors.canvas,
              appBar: AppBar(
                backgroundColor: AppColors.canvas,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain, size: 28),
                  tooltip: 'Tornar a les estanteries',
                  onPressed: () => Navigator.of(context).pop(),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentBookcase.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${currentBookcase.room} · ${currentBookcase.widthLabel} · ${currentBookcase.shelfCount} baldes · ${allBooks.length} llibres',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    key: const Key('bookcase_stats_button'),
                    tooltip: 'Estadístiques d\'aquesta estanteria',
                    icon: const Icon(Icons.insights_rounded, color: AppColors.primary, size: 24),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LibraryStatsScreen(
                            libraryId: widget.libraryId,
                            bookcaseId: currentBookcase.id,
                            bookcaseName: currentBookcase.name,
                            initialBooks: allBooks,
                            bookcaseService: _bookcaseService,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  // Contenció subtil per a tauletes i web segons l'amplada física del moble
                  final maxWidth = currentBookcase.widthCm <= 50
                      ? 620.0
                      : (currentBookcase.widthCm <= 70 ? 720.0 : 850.0);

                  return Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        children: [
                          _buildBookcaseSearchBar(
                            borrowedCount: allBooks.where((b) => b.isBorrowed).length,
                          ),
                          const SizedBox(height: 16),
                          for (int index = 0; index < currentBookcase.shelfCount; index++) ...[
                            () {
                              final shelfNum = index + 1;
                              final serverBooks = allBooks.where((b) {
                                final code = b.shelfCode.trim();
                                return code == '${currentBookcase.id}-B$shelfNum' ||
                                    code.endsWith('-B$shelfNum');
                              }).toList();

                              List<BookModel> shelfBooks;
                              final overrideList = _shelfBooksOverride[shelfNum];
                              if (overrideList != null) {
                                final overrideIds = overrideList.map((b) => b.id).toList();
                                final serverIds = serverBooks.map((b) => b.id).toList();
                                if (listEquals(overrideIds, serverIds)) {
                                  _shelfBooksOverride.remove(shelfNum);
                                  shelfBooks = serverBooks;
                                } else {
                                  shelfBooks = overrideList;
                                }
                              } else {
                                shelfBooks = serverBooks;
                              }

                              if (_onlyBorrowedFilter) {
                                shelfBooks = shelfBooks.where((b) => b.isBorrowed).toList();
                              }

                              return _buildShelfSection(
                                shelfNumber: shelfNum,
                                books: shelfBooks,
                                canEdit: canEdit,
                                currentBookcase: currentBookcase,
                              );
                            }(),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
              floatingActionButton: (canEdit && _searchQuery.isEmpty && !_onlyBorrowedFilter)
                  ? FloatingActionButton.extended(
                      key: const Key('bookshelf_actions_fab'),
                      onPressed: () => _showAddActionsSheet(context, currentBookcase),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                      icon: const Icon(Icons.add_rounded, size: 26),
                      label: const Text(
                        'Afegir llibres',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  Widget _buildBookcaseSearchBar({int borrowedCount = 0}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.accent,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(
              color: AppColors.textMain,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Cerca un llibre en aquesta estanteria...',
              hintStyle: TextStyle(
                color: AppColors.textMuted.withAlpha(180),
                fontSize: 15,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 24,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.cancel_rounded,
                        color: AppColors.textMuted,
                        size: 22,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        if (_highlightBookId != null) {
                          setState(() {
                            _highlightBookId = null;
                          });
                        }
                      },
                    )
                  : null,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: false,
            ),
          ),
        ),
        if (borrowedCount > 0 || _onlyBorrowedFilter) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              key: const Key('filter_borrowed_books_chip'),
              selected: _onlyBorrowedFilter,
              avatar: Icon(
                _onlyBorrowedFilter ? Icons.bookmark_remove_rounded : Icons.bookmark_border_rounded,
                size: 18,
                color: _onlyBorrowedFilter ? AppColors.primary : AppColors.textMuted,
              ),
              label: Text(
                'Fora de la balda ($borrowedCount)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: _onlyBorrowedFilter ? FontWeight.w700 : FontWeight.w500,
                  color: _onlyBorrowedFilter ? AppColors.primary : AppColors.textMain,
                ),
              ),
              backgroundColor: AppColors.surface,
              selectedColor: AppColors.primary.withAlpha(30),
              checkmarkColor: AppColors.primary,
              side: BorderSide(
                color: _onlyBorrowedFilter ? AppColors.primary : AppColors.accent,
                width: _onlyBorrowedFilter ? 1.5 : 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              onSelected: (selected) {
                setState(() {
                  _onlyBorrowedFilter = selected;
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  String _getShelfPositionLabel(int index, int totalShelves) {
    if (totalShelves <= 1) return 'Única';
    if (index == 1) return 'Superior';
    if (index == totalShelves) return 'Inferior';
    return 'Intermèdia';
  }

  Widget _buildShelfSection({
    required int shelfNumber,
    required List<BookModel> books,
    required bool canEdit,
    required BookcaseModel currentBookcase,
  }) {
    final positionLabel = _getShelfPositionLabel(shelfNumber, currentBookcase.shelfCount);
    final String subtitleText;
    if (_onlyBorrowedFilter) {
      subtitleText = books.isEmpty
          ? 'Cap llibre fora de la balda'
          : '${books.length} ${books.length == 1 ? 'llibre fora de la balda' : 'llibres fora de la balda'}';
    } else {
      subtitleText = books.isEmpty
          ? '0 llibres'
          : '${books.length} ${books.length == 1 ? 'llibre' : 'llibres'}';
    }

    final shelfPhotoUrl = books.cast<BookModel?>().firstWhere(
      (b) => b?.photoUrl != null && b!.photoUrl!.isNotEmpty,
      orElse: () => null,
    )?.photoUrl;

    final matchingCount = _searchQuery.isNotEmpty
        ? books.where((b) =>
            b.title.toLowerCase().contains(_searchQuery) ||
            b.author.toLowerCase().contains(_searchQuery)).length
        : (_highlightBookId != null && books.any((b) => b.id == _highlightBookId) ? 1 : 0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capçalera neta de la balda (sense card)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Balda $shelfNumber · $positionLabel',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text(
                            subtitleText,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                          if (matchingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.primary.withAlpha(80),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$matchingCount ${matchingCount == 1 ? 'coincident' : 'coincidents'}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (shelfPhotoUrl != null) ...[
                  IconButton.filledTonal(
                    key: Key('shelf_photo_button_$shelfNumber'),
                    tooltip: 'Veure fotografia de la balda $shelfNumber',
                    icon: const Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent.withAlpha(60),
                      shape: const CircleBorder(),
                    ),
                    onPressed: () {
                      _showShelfPhotoViewer(
                        context,
                        photoUrl: shelfPhotoUrl,
                        shelfNumber: shelfNumber,
                        positionLabel: positionLabel,
                        bookcaseName: currentBookcase.name,
                        currentBookcase: currentBookcase,
                        existingBooks: books,
                        canEdit: canEdit,
                      );
                    },
                  ),
                  if (canEdit) const SizedBox(width: 8),
                ],
                if (canEdit && books.isNotEmpty) ...[
                  IconButton.filledTonal(
                    key: Key('shelf_clear_button_$shelfNumber'),
                    tooltip: 'Buidar balda $shelfNumber',
                    icon: const Icon(
                      Icons.delete_sweep_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent.withAlpha(60),
                      shape: const CircleBorder(),
                    ),
                    onPressed: () {
                      _confirmClearShelf(currentBookcase, shelfNumber, books.length);
                    },
                  ),
                  const SizedBox(width: 8),
                ],
                if (canEdit)
                  IconButton.filledTonal(
                    key: Key('shelf_camera_button_$shelfNumber'),
                    tooltip: 'Fotografiar balda $shelfNumber',
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent.withAlpha(60),
                      shape: const CircleBorder(),
                    ),
                    onPressed: () {
                      _showCaptureSourceSheet(currentBookcase, shelfNumber);
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Espai de llibres (reposant a la base de la balda)
          SizedBox(
            height: 195,
            child: books.isNotEmpty
                ? _ShelfHorizontalBookList(
                    shelfNumber: shelfNumber,
                    books: books,
                    searchQuery: _searchQuery,
                    highlightBookId: _highlightBookId,
                    canEdit: canEdit,
                    onlyBorrowedFilter: _onlyBorrowedFilter,
                    currentBookcase: currentBookcase,
                    onReorder: _onReorderShelfBooks,
                    onBookTap: (book, bc, editable) {
                      if (_highlightBookId != null) {
                        setState(() {
                          _highlightBookId = null;
                        });
                      }
                      _showBookDetails(book, bc, editable);
                    },
                  )
                : (_onlyBorrowedFilter
                    ? Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 16),
                          child: Text(
                            'Cap llibre fora de la balda',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted.withAlpha(160),
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: InkWell(
                            key: Key('ghost_spine_$shelfNumber'),
                            onTap: () {
                              _showEmptyShelfOptionsSheet(currentBookcase, shelfNumber);
                            },
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            child: Container(
                              width: 46,
                              height: 160,
                              decoration: BoxDecoration(
                                color: AppColors.canvas.withAlpha(120),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                border: Border.all(
                                  color: AppColors.primary.withAlpha(130),
                                  width: 1.5,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Positioned(
                                    top: 12,
                                    child: Icon(Icons.add_rounded, color: AppColors.primary, size: 22),
                                  ),
                                  Positioned(
                                    top: 38,
                                    bottom: 12,
                                    child: Center(
                                      child: RotatedBox(
                                        quarterTurns: 3,
                                        child: Text(
                                          'Afegir llibre / foto',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.0,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary.withAlpha(200),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )),
          ),

          // Tauló físic de fusta horitzontal (#D9C5B2)
          Container(
            height: 12,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFD9C5B2),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: const Color(0xFFCBB5A1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 4,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showShelfPhotoViewer(
    BuildContext context, {
    required String photoUrl,
    required int shelfNumber,
    required String positionLabel,
    required String bookcaseName,
    required BookcaseModel currentBookcase,
    List<BookModel> existingBooks = const [],
    bool canEdit = false,
  }) {
    showDialog(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Capçalera
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Balda $shelfNumber · $positionLabel',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          bookcaseName,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    key: const Key('close_shelf_photo_dialog'),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Tancar',
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.canvas),

            // Visor interactiu de la fotografia de la balda sencera
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(canEdit ? 0 : 20),
                ),
                child: InteractiveViewer(
                  maxScale: 4.0,
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      );
                    },
                    errorBuilder: (ctx, error, stackTrace) {
                      debugPrint('Error carregant foto de balda ($photoUrl): $error');
                      return Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.broken_image_rounded, size: 44, color: AppColors.textMuted),
                            const SizedBox(height: 10),
                            const Text(
                              'No s\'ha pogut carregar la fotografia de la balda.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textMain,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              kIsWeb
                                  ? 'Possible restricció de CORS a Flutter Web. Revisa les regles de Firebase Storage.'
                                  : 'Comprova la connexió a la xarxa o la validesa de l\'enllaç.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            if (canEdit) ...[
              const Divider(height: 1, color: AppColors.canvas),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    key: const Key('btn_edit_shelf_detection'),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text(
                      'Editar detecció / Afegir llibre',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogCtx).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ShelfReviewScreen(
                            imageBytes: Uint8List(0),
                            photoUrl: photoUrl,
                            libraryId: widget.libraryId,
                            bookcase: currentBookcase,
                            shelfIndex: shelfNumber,
                            initialDetectedSpines: const [],
                            existingBooks: existingBooks,
                            isRetroactiveEdit: true,
                            bookcaseService: _bookcaseService,
                            enrichmentService: widget.enrichmentService,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ShelfHorizontalBookList extends StatefulWidget {
  final int shelfNumber;
  final List<BookModel> books;
  final String searchQuery;
  final String? highlightBookId;
  final bool canEdit;
  final bool onlyBorrowedFilter;
  final BookcaseModel currentBookcase;
  final void Function(int shelfNumber, int oldIndex, int newIndex, List<BookModel> books) onReorder;
  final void Function(BookModel book, BookcaseModel bookcase, bool canEdit) onBookTap;

  const _ShelfHorizontalBookList({
    required this.shelfNumber,
    required this.books,
    required this.searchQuery,
    required this.highlightBookId,
    required this.canEdit,
    required this.onlyBorrowedFilter,
    required this.currentBookcase,
    required this.onReorder,
    required this.onBookTap,
  });

  @override
  State<_ShelfHorizontalBookList> createState() => _ShelfHorizontalBookListState();
}

class _ShelfHorizontalBookListState extends State<_ShelfHorizontalBookList> {
  final ScrollController _scrollController = ScrollController();
  int _offscreenRightCount = 0;
  int _offscreenLeftCount = 0;
  int? _firstRightMatchIndex;
  int? _lastLeftMatchIndex;
  bool _hasAutoScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateOffscreenCounts);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkInitialScrollAndCounts();
      }
    });
  }

  @override
  void didUpdateWidget(covariant _ShelfHorizontalBookList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery ||
        widget.highlightBookId != oldWidget.highlightBookId ||
        widget.books.length != oldWidget.books.length) {
      _hasAutoScrolled = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _checkInitialScrollAndCounts();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateOffscreenCounts);
    _scrollController.dispose();
    super.dispose();
  }

  bool _isMatch(BookModel book) {
    if (widget.searchQuery.isNotEmpty) {
      return book.title.toLowerCase().contains(widget.searchQuery) ||
          book.author.toLowerCase().contains(widget.searchQuery);
    }
    return widget.highlightBookId != null && book.id == widget.highlightBookId;
  }

  double _getBookWidth(BookModel book) {
    final variation = (book.title.length * 3) % 8;
    return 41.0 + variation;
  }

  List<double> _computeBookStartOffsets() {
    final offsets = <double>[];
    double current = 4.0;
    for (final book in widget.books) {
      offsets.add(current);
      final width = _getBookWidth(book);
      current += width + 8.0;
    }
    return offsets;
  }

  void _updateOffscreenCounts() {
    if (!_scrollController.hasClients || !mounted) return;

    final scrollOffset = _scrollController.offset;
    final viewportWidth = _scrollController.position.viewportDimension;
    if (viewportWidth <= 0) return;

    final startOffsets = _computeBookStartOffsets();
    int offscreenRight = 0;
    int offscreenLeft = 0;
    int? firstRightMatch;
    int? lastLeftMatch;

    for (int i = 0; i < widget.books.length; i++) {
      final book = widget.books[i];
      if (!_isMatch(book)) continue;

      final startX = startOffsets[i];
      final endX = startX + _getBookWidth(book);

      if (startX > scrollOffset + viewportWidth - 20) {
        offscreenRight++;
        firstRightMatch ??= i;
      } else if (endX < scrollOffset + 20) {
        offscreenLeft++;
        lastLeftMatch = i;
      }
    }

    if (offscreenRight != _offscreenRightCount ||
        offscreenLeft != _offscreenLeftCount ||
        firstRightMatch != _firstRightMatchIndex ||
        lastLeftMatch != _lastLeftMatchIndex) {
      setState(() {
        _offscreenRightCount = offscreenRight;
        _offscreenLeftCount = offscreenLeft;
        _firstRightMatchIndex = firstRightMatch;
        _lastLeftMatchIndex = lastLeftMatch;
      });
    }
  }

  void _checkInitialScrollAndCounts() {
    if (!_scrollController.hasClients || !mounted) return;

    final hasSpecificHighlight = widget.highlightBookId != null;
    final hasSearch = widget.searchQuery.isNotEmpty;

    if ((hasSpecificHighlight || hasSearch) && !_hasAutoScrolled) {
      _hasAutoScrolled = true;
      final startOffsets = _computeBookStartOffsets();
      final viewportWidth = _scrollController.position.viewportDimension;

      int targetIndex = -1;
      if (hasSpecificHighlight) {
        targetIndex = widget.books.indexWhere((b) => b.id == widget.highlightBookId);
      } else if (hasSearch) {
        final anyVisible = widget.books.asMap().entries.any((entry) {
          final i = entry.key;
          final book = entry.value;
          if (!_isMatch(book)) return false;
          final startX = startOffsets[i];
          final endX = startX + _getBookWidth(book);
          return startX < viewportWidth - 25 && endX > 25;
        });

        if (!anyVisible) {
          targetIndex = widget.books.indexWhere((b) => _isMatch(b));
        }
      }

      if (targetIndex >= 0 && targetIndex < widget.books.length) {
        final bookStartX = startOffsets[targetIndex];
        final bookWidth = _getBookWidth(widget.books[targetIndex]);
        final targetOffset = (bookStartX + bookWidth / 2) - (viewportWidth / 2);
        final clampedOffset = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

        _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    }

    _updateOffscreenCounts();
  }

  void _scrollToNextMatch() {
    if (_firstRightMatchIndex != null && _scrollController.hasClients) {
      final startOffsets = _computeBookStartOffsets();
      final viewportWidth = _scrollController.position.viewportDimension;
      final idx = _firstRightMatchIndex!;
      final bookStartX = startOffsets[idx];
      final bookWidth = _getBookWidth(widget.books[idx]);
      final targetOffset = (bookStartX + bookWidth / 2) - (viewportWidth / 2);
      final clamped = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _scrollToPreviousMatch() {
    if (_lastLeftMatchIndex != null && _scrollController.hasClients) {
      final startOffsets = _computeBookStartOffsets();
      final viewportWidth = _scrollController.position.viewportDimension;
      final idx = _lastLeftMatchIndex!;
      final bookStartX = startOffsets[idx];
      final bookWidth = _getBookWidth(widget.books[idx]);
      final targetOffset = (bookStartX + bookWidth / 2) - (viewportWidth / 2);
      final clamped = targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.animateTo(
        clamped,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Widget _buildJumpPill({
    required IconData icon,
    required int count,
    required bool isRight,
    required VoidCallback onTap,
  }) {
    return Material(
      key: Key(isRight ? 'jump_pill_right_${widget.shelfNumber}' : 'jump_pill_left_${widget.shelfNumber}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(70),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: Colors.white.withAlpha(200),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isRight) ...[
                Icon(icon, size: 14, color: Colors.white),
                const SizedBox(width: 4),
              ],
              Text(
                '$count ${count == 1 ? 'coincident' : 'coincidents'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isRight) ...[
                const SizedBox(width: 4),
                Icon(icon, size: 14, color: Colors.white),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ReorderableListView.builder(
          scrollController: _scrollController,
          scrollDirection: Axis.horizontal,
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          itemCount: widget.books.length,
          onReorder: (oldIdx, newIdx) {
            widget.onReorder(widget.shelfNumber, oldIdx, newIdx, widget.books);
          },
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final animValue = Curves.easeInOut.transform(animation.value);
                final elevation = lerpDouble(0, 8, animValue) ?? 0;
                final scale = lerpDouble(1.0, 1.05, animValue) ?? 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Material(
                    elevation: elevation,
                    color: Colors.transparent,
                    shadowColor: Colors.black.withAlpha(90),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          itemBuilder: (context, bIdx) {
            final book = widget.books[bIdx];
            final matchesQuery = widget.searchQuery.isNotEmpty && (
              book.title.toLowerCase().contains(widget.searchQuery) ||
              book.author.toLowerCase().contains(widget.searchQuery)
            );
            final isHighlighted = matchesQuery ||
                (widget.highlightBookId != null && book.id == widget.highlightBookId);
            final isDimmed = (widget.searchQuery.isNotEmpty || widget.highlightBookId != null) &&
                !isHighlighted;

            return ReorderableDelayedDragStartListener(
              key: ValueKey(book.id),
              index: bIdx,
              enabled: widget.canEdit && widget.searchQuery.isEmpty && !widget.onlyBorrowedFilter,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: BookSpineWidget(
                    book: book,
                    displayIndex: bIdx + 1,
                    isHighlighted: isHighlighted,
                    isDimmed: isDimmed,
                    onTap: () {
                      widget.onBookTap(book, widget.currentBookcase, widget.canEdit);
                    },
                  ),
                ),
              ),
            );
          },
        ),
        if (_offscreenLeftCount > 0)
          Positioned(
            left: 8,
            top: 8,
            child: _buildJumpPill(
              icon: Icons.arrow_back_rounded,
              count: _offscreenLeftCount,
              isRight: false,
              onTap: _scrollToPreviousMatch,
            ),
          ),
        if (_offscreenRightCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: _buildJumpPill(
              icon: Icons.arrow_forward_rounded,
              count: _offscreenRightCount,
              isRight: true,
              onTap: _scrollToNextMatch,
            ),
          ),
      ],
    );
  }
}
