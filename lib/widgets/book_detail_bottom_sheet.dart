import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';
import '../models/bookcase_model.dart';
import '../services/bookcase_service.dart';
import '../services/book_enrichment_service.dart';
import 'add_manual_book_dialog.dart';

/// Mostra la Bottom Sheet moderna de detall del llibre amb portada, sinopsi de Google Books i accions
Future<void> showBookDetailBottomSheet(
  BuildContext context, {
  required BookModel book,
  required BookcaseModel bookcase,
  required String libraryId,
  required bool canEdit,
  BookcaseService? bookcaseService,
  BookEnrichmentService? enrichmentService,
  VoidCallback? onBookChanged,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return BookDetailBottomSheet(
        book: book,
        bookcase: bookcase,
        libraryId: libraryId,
        canEdit: canEdit,
        bookcaseService: bookcaseService,
        enrichmentService: enrichmentService,
        onBookChanged: onBookChanged,
      );
    },
  );
}

class BookDetailBottomSheet extends StatefulWidget {
  final BookModel book;
  final BookcaseModel bookcase;
  final String libraryId;
  final bool canEdit;
  final BookcaseService? bookcaseService;
  final BookEnrichmentService? enrichmentService;
  final VoidCallback? onBookChanged;

  const BookDetailBottomSheet({
    super.key,
    required this.book,
    required this.bookcase,
    required this.libraryId,
    required this.canEdit,
    this.bookcaseService,
    this.enrichmentService,
    this.onBookChanged,
  });

  @override
  State<BookDetailBottomSheet> createState() => _BookDetailBottomSheetState();
}

class _BookDetailBottomSheetState extends State<BookDetailBottomSheet> {
  late BookModel _currentBook;
  late final BookcaseService _bookcaseService;
  late final BookEnrichmentService _enrichmentService;

  bool _isLoadingEnrichment = false;
  bool _isSynopsisExpanded = false;
  Future<BookModel>? _enrichmentFuture;

  @visibleForTesting
  Future<BookModel>? get enrichmentFuture => _enrichmentFuture;

  @override
  void initState() {
    super.initState();
    _currentBook = widget.book;
    _bookcaseService = widget.bookcaseService ?? BookcaseService();
    _enrichmentService = widget.enrichmentService ?? BookEnrichmentService();

    _loadEnrichmentDataIfNeeded();
  }

  @override
  void didUpdateWidget(BookDetailBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id) {
      _currentBook = widget.book;
      _enrichmentFuture = null;
      _loadEnrichmentDataIfNeeded();
    }
  }

  void _loadEnrichmentDataIfNeeded() {
    // Si el llibre ja disposa tant de sinopsi com de portada, no cal consultar la xarxa
    final hasSynopsis = _currentBook.synopsis != null && _currentBook.synopsis!.isNotEmpty;
    final hasCover = _currentBook.coverUrl != null && _currentBook.coverUrl!.isNotEmpty;
    if (hasSynopsis && hasCover) {
      return;
    }

    // Si ja s'ha intentat recuperar la informació mancant 3 o més vegades, ho deixem estar
    if (_currentBook.enrichmentAttempts >= 3) {
      return;
    }

    if (_enrichmentFuture != null || _isLoadingEnrichment) return;

    setState(() {
      _isLoadingEnrichment = true;
    });

    _enrichmentFuture = _enrichmentService.enrichAndPersistBook(
      book: _currentBook,
      libraryId: widget.libraryId,
    ).then((updated) {
      if (mounted) {
        setState(() {
          _currentBook = updated;
          _isLoadingEnrichment = false;
        });
      }
      return updated;
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _isLoadingEnrichment = false;
        });
      }
      return _currentBook;
    });
  }

  String _getShelfLabel(String shelfCode) {
    final match = RegExp(r'-B(\d+)$').firstMatch(shelfCode);
    if (match != null) {
      return 'Balda ${match.group(1)}';
    }
    return shelfCode;
  }

  Future<void> _openExternalBookUrl() async {
    final cleanT = BookEnrichmentService.cleanSearchTerm(_currentBook.title);
    final cleanA = BookEnrichmentService.cleanSearchTerm(_currentBook.author);
    final combined = cleanA.isNotEmpty ? '$cleanT $cleanA' : cleanT;
    final fallbackUrl =
        'https://books.google.com/books?q=${Uri.encodeComponent(combined.isNotEmpty ? combined : _currentBook.title)}';

    final urlStr = (_currentBook.infoUrl != null && _currentBook.infoUrl!.trim().isNotEmpty)
        ? _currentBook.infoUrl!
        : fallbackUrl;

    final uri = Uri.tryParse(urlStr);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _locateBookOnShelf() {
    Navigator.of(context).pop();

    if (_currentBook.photoUrl != null && _currentBook.box != null) {
      showDialog(
        context: context,
        builder: (ctx) => _BookShelfVisualLocatorDialog(
          book: _currentBook,
          bookcase: widget.bookcase,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El llibre "${_currentBook.title}" es troba a ${_getShelfLabel(_currentBook.shelfCode)} de ${widget.bookcase.name}.',
          ),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shelfLabel = _getShelfLabel(_currentBook.shelfCode);
    final positionLabel = _currentBook.positionIndex > 0
        ? 'Posició #${_currentBook.positionIndex}'
        : 'Balda física';

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nansa superior
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(120),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Capçalera moderna: Portada + Dades principals
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoverThumbnail(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentBook.title,
                        key: const Key('book_detail_title'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                          height: 1.25,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_currentBook.author.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _currentBook.author,
                          key: const Key('book_detail_author'),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _buildMetadataRow(),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Xips d'Ubicació Física
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  icon: Icons.shelves,
                  label: widget.bookcase.name,
                  subLabel: widget.bookcase.room,
                ),
                _buildChip(
                  icon: Icons.table_rows_rounded,
                  label: shelfLabel,
                  subLabel: positionLabel,
                  highlight: true,
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Bloc de Sinopsi
            _buildSynopsisSection(),

            const SizedBox(height: 24),

            // Botó destacat «Localitzar a la balda»
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                key: const Key('locate_on_shelf_button'),
                onPressed: _locateBookOnShelf,
                icon: const Icon(Icons.center_focus_strong_rounded, size: 22),
                label: const Text(
                  'Localitzar a la balda',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Fila d'accions secundàries (Fitxa externa, Editar, Eliminar)
            Builder(
              builder: (context) {
                final infoUrlLower = _currentBook.infoUrl?.toLowerCase() ?? '';
                final String externalButtonText;
                final IconData externalButtonIcon;

                if (infoUrlLower.contains('books.google')) {
                  externalButtonText = 'Google Books';
                  externalButtonIcon = Icons.menu_book_rounded;
                } else if (infoUrlLower.contains('openlibrary.org')) {
                  externalButtonText = 'Open Library';
                  externalButtonIcon = Icons.local_library_outlined;
                } else {
                  externalButtonText = 'Fitxa del llibre';
                  externalButtonIcon = Icons.open_in_new_rounded;
                }

                return Row(
                  children: [
                    // Enllaç extern fitxa del llibre (Open Library / Google Books)
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('google_books_button'),
                        onPressed: _openExternalBookUrl,
                        icon: Icon(externalButtonIcon, size: 18, color: AppColors.primaryDark),
                        label: Text(
                          externalButtonText,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          side: BorderSide(color: AppColors.accent.withAlpha(150)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    if (widget.canEdit) ...[
                      const SizedBox(width: 8),
                      // Botó Editar
                      OutlinedButton.icon(
                        key: const Key('edit_book_button'),
                        onPressed: () {
                          Navigator.of(context).pop();
                          showEditBookBottomSheet(
                            context,
                            libraryId: widget.libraryId,
                            bookcase: widget.bookcase,
                            book: _currentBook,
                            bookcaseService: _bookcaseService,
                          );
                        },
                        icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                        label: const Text(
                          'Editar',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          side: BorderSide(color: AppColors.primary.withAlpha(120)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botó Eliminar
                      OutlinedButton.icon(
                        key: const Key('delete_book_button'),
                        onPressed: _confirmAndDeleteBook,
                        icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade700),
                        label: Text(
                          'Eliminar',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverThumbnail() {
    final rawCover = _currentBook.coverUrl;
    final cover = BookEnrichmentService.getSafeDisplayCoverUrl(rawCover);

    if (cover != null && cover.isNotEmpty) {
      return Container(
        width: 76,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(35),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.network(
          cover,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error carregant portada [CORS/Network] ($cover): $error');
            return _buildFallbackSpine();
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: AppColors.accent.withAlpha(50),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildFallbackSpine();
  }

  Widget _buildFallbackSpine() {
    return Container(
      width: 76,
      height: 110,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 28),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              _currentBook.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadataRow() {
    final items = <Widget>[];

    if (_currentBook.publishedYear != null && _currentBook.publishedYear!.isNotEmpty) {
      items.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 13, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            _currentBook.publishedYear!,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ));
    }

    if (_currentBook.pageCount != null && _currentBook.pageCount! > 0) {
      if (items.isNotEmpty) {
        items.add(const Text(' · ', style: TextStyle(color: AppColors.textMuted)));
      }
      items.add(Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.format_list_numbered_rounded, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            '${_currentBook.pageCount} pàg.',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
          ),
        ],
      ));
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(children: items);
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    String? subLabel,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlight ? AppColors.primary.withAlpha(20) : AppColors.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? AppColors.primary.withAlpha(80) : AppColors.accent.withAlpha(120),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight ? AppColors.primary : AppColors.textMuted,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: highlight ? AppColors.primaryDark : AppColors.textMain,
                ),
              ),
              if (subLabel != null && subLabel.isNotEmpty)
                Text(
                  subLabel,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSynopsisSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withAlpha(100)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text(
                'SINOPSI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                  color: AppColors.textMuted,
                ),
              ),
              const Spacer(),
              if (_isLoadingEnrichment)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingEnrichment && (_currentBook.synopsis == null || _currentBook.synopsis!.isEmpty)) ...[
            _buildShimmerLine(widthFraction: 0.95),
            const SizedBox(height: 6),
            _buildShimmerLine(widthFraction: 0.85),
            const SizedBox(height: 6),
            _buildShimmerLine(widthFraction: 0.6),
          ] else if (_currentBook.synopsis != null && _currentBook.synopsis!.isNotEmpty) ...[
            Text(
              _currentBook.synopsis!,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textMain,
                height: 1.45,
              ),
              maxLines: _isSynopsisExpanded ? null : 4,
              overflow: _isSynopsisExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (_currentBook.synopsis!.length > 180) ...[
              const SizedBox(height: 6),
              InkWell(
                onTap: () {
                  setState(() {
                    _isSynopsisExpanded = !_isSynopsisExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    _isSynopsisExpanded ? 'Llegir menys ▴' : 'Llegir més ▾',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ] else ...[
            const Text(
              'No s\'ha trobat cap descripció disponible per a aquest títol.',
              style: TextStyle(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShimmerLine({required double widthFraction}) {
    return FractionallySizedBox(
      widthFactor: widthFraction,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.accent.withAlpha(70),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteBook() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar llibre'),
        content: Text(
          'Segur que vols eliminar "${_currentBook.title}" d\'aquesta estanteria? Aquesta acció no es pot desfer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel·lar', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            key: const Key('confirm_delete_book_button'),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (shouldDelete == true && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      try {
        await _bookcaseService.deleteBook(
          widget.libraryId,
          _currentBook.id,
          widget.bookcase.id,
        );
        messenger.showSnackBar(
          SnackBar(
            content: Text('S\'ha eliminat "${_currentBook.title}".'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onBookChanged?.call();
      } catch (e) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error en eliminar el llibre: $e'),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

/// Visor interactiu que ressalta la caixa del llibre sobre la fotografia real de la balda
class _BookShelfVisualLocatorDialog extends StatelessWidget {
  final BookModel book;
  final BookcaseModel bookcase;

  const _BookShelfVisualLocatorDialog({
    required this.book,
    required this.bookcase,
  });

  @override
  Widget build(BuildContext context) {
    final box = book.box!;
    final shelfMatch = RegExp(r'-B(\d+)$').firstMatch(book.shelfCode);
    final shelfName = shelfMatch != null ? 'Balda ${shelfMatch.group(1)}' : book.shelfCode;

    return Dialog(
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
                        book.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '$shelfName · ${bookcase.name}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.canvas),

          // Imatge amb ressaltat
          Flexible(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
              child: InteractiveViewer(
                maxScale: 4.0,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          book.photoUrl!,
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
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint(
                              'Error carregant photoUrl de la balda [CORS/Network] (${book.photoUrl}): $error',
                            );
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
                        // Caixa delimitadora normalitzada (0..1000)
                        Positioned.fill(
                          child: LayoutBuilder(
                            builder: (ctx, innerConstraints) {
                              final w = innerConstraints.maxWidth;
                              final h = innerConstraints.maxHeight;
                              final top = (box[0] / 1000.0) * h;
                              final left = (box[1] / 1000.0) * w;
                              final right = w - ((box[3] / 1000.0) * w);
                              final bottom = h - ((box[2] / 1000.0) * h);

                              return Stack(
                                children: [
                                  Positioned(
                                    top: top,
                                    left: left,
                                    right: right,
                                    bottom: bottom,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: AppColors.primary, width: 3),
                                        color: AppColors.primary.withAlpha(60),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      alignment: Alignment.topCenter,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        color: AppColors.primaryDark,
                                        child: Text(
                                          book.title,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
