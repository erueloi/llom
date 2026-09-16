import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: isQuotaOrKeyError ? 8 : 4),
            action: isQuotaOrKeyError
                ? SnackBarAction(
                    label: 'Canviar clau',
                    textColor: Colors.white,
                    onPressed: () {
                      ShelfVisionService.promptApiKeyIfNeeded(context, forceShow: true);
                    },
                  )
                : null,
          ),
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
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'S\'han catalogat els llibres correctament a la Balda $shelfNumber.',
          ),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
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
                      '${currentBookcase.room} · ${currentBookcase.shelfCount} baldes · ${allBooks.length} llibres',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              body: LayoutBuilder(
                builder: (context, constraints) {
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        children: [
                          _buildBookcaseSearchBar(),
                          const SizedBox(height: 16),
                          for (int index = 0; index < currentBookcase.shelfCount; index++) ...[
                            () {
                              final shelfNum = index + 1;
                              final shelfBooks = allBooks.where((b) {
                                final code = b.shelfCode.trim();
                                return code == '${currentBookcase.id}-B$shelfNum' ||
                                    code.endsWith('-B$shelfNum');
                              }).toList();

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
              floatingActionButton: canEdit
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

  Widget _buildBookcaseSearchBar() {
    return Container(
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
                  onPressed: () => _searchController.clear(),
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
    final subtitleText = books.isEmpty
        ? '0 llibres'
        : '${books.length} ${books.length == 1 ? 'llibre' : 'llibres'}';
    final shelfPhotoUrl = books.cast<BookModel?>().firstWhere(
      (b) => b?.photoUrl != null && b!.photoUrl!.isNotEmpty,
      orElse: () => null,
    )?.photoUrl;

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
                      Text(
                        subtitleText,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                        ),
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
                      );
                    },
                  ),
                  if (canEdit) const SizedBox(width: 8),
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
                ? ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: books.length,
                    itemBuilder: (context, bIdx) {
                      final book = books[bIdx];
                      final matchesQuery = _searchQuery.isNotEmpty && (
                        book.title.toLowerCase().contains(_searchQuery) ||
                        book.author.toLowerCase().contains(_searchQuery)
                      );
                      final isHighlighted = matchesQuery || (_highlightBookId != null && book.id == _highlightBookId);
                      final isDimmed = (_searchQuery.isNotEmpty || _highlightBookId != null) && !isHighlighted;

                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: BookSpineWidget(
                            book: book,
                            displayIndex: bIdx + 1,
                            isHighlighted: isHighlighted,
                            isDimmed: isDimmed,
                            onTap: () {
                              if (_highlightBookId != null) {
                                setState(() {
                                  _highlightBookId = null;
                                });
                              }
                              _showBookDetails(book, currentBookcase, canEdit);
                            },
                          ),
                        ),
                      );
                    },
                  )
                : Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: InkWell(
                        key: Key('ghost_spine_$shelfNumber'),
                        onTap: () {
                          showAddManualBookDialog(
                            context,
                            libraryId: widget.libraryId,
                            bookcase: currentBookcase,
                            initialShelfIndex: shelfNumber,
                            bookcaseService: _bookcaseService,
                          );
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
                  ),
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
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
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
          ],
        ),
      ),
    );
  }
}
