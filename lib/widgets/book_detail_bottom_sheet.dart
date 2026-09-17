import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/feedback/app_feedback.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';
import '../models/bookcase_model.dart';
import '../models/loan_record.dart';
import '../providers/library_provider.dart';
import '../services/bookcase_service.dart';
import '../services/book_enrichment_service.dart';
import '../services/library_service.dart';
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
      AppFeedback.showInfo(
        context,
        'El llibre "${_currentBook.title}" es troba a ${_getShelfLabel(_currentBook.shelfCode)} de ${widget.bookcase.name}.',
      );
    }
  }

  Future<void> _refreshEnrichmentData() async {
    if (_isLoadingEnrichment) return;

    setState(() {
      _isLoadingEnrichment = true;
    });

    try {
      final updated = await _enrichmentService.enrichAndPersistBook(
        book: _currentBook,
        libraryId: widget.libraryId,
        force: true,
      );

      if (mounted) {
        final hadInfo = _currentBook.synopsis != null || _currentBook.coverUrl != null;
        final hasNewInfo = updated.synopsis != _currentBook.synopsis ||
            updated.coverUrl != _currentBook.coverUrl ||
            updated.pageCount != _currentBook.pageCount ||
            updated.publishedYear != _currentBook.publishedYear;

        setState(() {
          _currentBook = updated;
          _isLoadingEnrichment = false;
        });
        widget.onBookChanged?.call();

        if (hasNewInfo) {
          AppFeedback.showSuccess(context, 'S\'han actualitzat les dades de «${_currentBook.title}».');
        } else if (hadInfo) {
          AppFeedback.showInfo(context, 'Les dades de «${_currentBook.title}» ja estan al dia.');
        } else {
          AppFeedback.showInfo(context, 'No s\'ha trobat informació addicional per a «${_currentBook.title}».');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingEnrichment = false;
        });
        AppFeedback.showError(context, 'Error en recarregar les dades: $e');
      }
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
            // Barra superior amb nansa centrada i icones d'acció ràpida a la dreta
            Stack(
              alignment: Alignment.center,
              children: [
                // Nansa superior
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(120),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                // Botons d'acció compactes a dalt a la dreta
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botó de recàrrega de dades (sinopsi i portada)
                      IconButton(
                        key: const Key('refresh_enrichment_button'),
                        tooltip: 'Recarregar dades (sinopsi i portada)',
                        iconSize: 20,
                        splashRadius: 20,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        icon: _isLoadingEnrichment
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, color: AppColors.textMuted),
                        onPressed: _isLoadingEnrichment ? null : _refreshEnrichmentData,
                      ),
                      const SizedBox(width: 4),
                      // Botó de localitzar a la balda
                      IconButton(
                        key: const Key('locate_on_shelf_button'),
                        tooltip: 'Localitzar a la balda',
                        iconSize: 20,
                        splashRadius: 20,
                        padding: const EdgeInsets.all(6),
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.center_focus_strong_rounded, color: AppColors.primary),
                        onPressed: _locateBookOnShelf,
                      ),
                      if (widget.canEdit) ...[
                        const SizedBox(width: 4),
                        // Botó de préstec o retornar
                        if (_currentBook.isBorrowed)
                          IconButton(
                            key: const Key('return_book_button'),
                            tooltip: 'Retornar a la balda',
                            iconSize: 20,
                            splashRadius: 20,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.inbox_rounded, color: Color(0xFF2E7D32)),
                            onPressed: _returnBookToShelf,
                          )
                        else
                          IconButton(
                            key: const Key('borrow_book_button'),
                            tooltip: 'Treure de la balda / Marcar prestat',
                            iconSize: 20,
                            splashRadius: 20,
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.outbox_rounded, color: Color(0xFFE65100)),
                            onPressed: _showBorrowDialog,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

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

            // Banner informatiu si el llibre està en préstec / fora de la balda
            if (_currentBook.isBorrowed)
              Container(
                key: const Key('borrowed_info_banner'),
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFFFFB74D),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.outbox_rounded, color: Color(0xFFE65100), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '📖 Fora de la balda: prestat a ${_currentBook.borrowedTo ?? 'desconegut'}${_currentBook.borrowedAt != null ? ' el ${_formatDate(_currentBook.borrowedAt)}' : ''}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBF360C),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

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
                if (_currentBook.isBorrowed)
                  _buildChip(
                    icon: Icons.person_outline_rounded,
                    label: 'En préstec',
                    subLabel: _currentBook.borrowedTo ?? 'En lectura',
                    highlight: true,
                  ),
              ],
            ),

            const SizedBox(height: 18),

            // Bloc de Sinopsi
            _buildSynopsisSection(),

            if (_currentBook.loanHistory.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: OutlinedButton.icon(
                  key: const Key('loan_history_button'),
                  onPressed: _showLoanHistoryDialog,
                  icon: const Icon(Icons.history_rounded, size: 19, color: AppColors.primary),
                  label: Text(
                    'Historial de préstecs (${_currentBook.loanHistory.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.accent.withAlpha(150)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: AppColors.surface,
                  ),
                ),
              ),
            ],

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
      Navigator.of(context).pop();
      try {
        await _bookcaseService.deleteBook(
          widget.libraryId,
          _currentBook.id,
          widget.bookcase.id,
        );
        if (mounted) {
          AppFeedback.showSuccess(context, 'S\'ha eliminat "${_currentBook.title}".');
        }
        widget.onBookChanged?.call();
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, 'Error en eliminar el llibre: $e');
        }
      }
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'data desconeguda';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _returnBookToShelf() async {
    try {
      if (widget.libraryId.isNotEmpty) {
        await _bookcaseService.toggleBookBorrowedStatus(
          libraryId: widget.libraryId,
          bookId: _currentBook.id,
          isBorrowed: false,
        );
      }
      if (mounted) {
        final now = DateTime.now();
        final updatedHistory = List<LoanRecord>.from(_currentBook.loanHistory);
        final activeIndex = updatedHistory.lastIndexWhere((r) => r.returnedAt == null);
        if (activeIndex != -1) {
          updatedHistory[activeIndex] = updatedHistory[activeIndex].copyWith(returnedAt: now);
        } else if (_currentBook.isBorrowed) {
          updatedHistory.add(LoanRecord(
            id: '${now.millisecondsSinceEpoch}',
            borrowedTo: _currentBook.borrowedTo ?? 'En lectura',
            borrowedAt: _currentBook.borrowedAt ?? now,
            returnedAt: now,
          ));
        }
        setState(() {
          _currentBook = _currentBook.copyWith(
            isBorrowed: false,
            borrowedTo: null,
            borrowedAt: null,
            loanHistory: updatedHistory,
          );
        });
        widget.onBookChanged?.call();
        AppFeedback.showSuccess(context, 'S\'ha retornat «${_currentBook.title}» a la balda.');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Error en retornar el llibre: $e');
      }
    }
  }

  void _showLoanHistoryDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _LoanHistoryBottomSheet(book: _currentBook),
    );
  }

  Future<void> _showBorrowDialog() async {
    LibraryProvider? libraryProvider;
    try {
      libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    } catch (_) {
      // Entorn de proves sense Provider
    }

    final activeLib = libraryProvider?.activeLibrary;
    final currentUser = libraryProvider?.currentUser;

    final Set<String> suggestionSet = {};
    if (currentUser?.displayName != null && currentUser!.displayName!.trim().isNotEmpty) {
      suggestionSet.add(currentUser.displayName!.trim());
    }
    suggestionSet.add('Jo mateix / Llegint');
    suggestionSet.add('Familiar');
    suggestionSet.add('Amic/ga');

    if (activeLib != null) {
      for (final fb in activeLib.frequentBorrowers) {
        if (fb.trim().isNotEmpty) {
          suggestionSet.add(fb.trim());
        }
      }
    }

    final result = await showDialog<BorrowDialogResult>(
      context: context,
      builder: (dialogContext) => _BorrowBookDialog(
        suggestions: suggestionSet.toList(),
        initialDateTime: DateTime.now(),
      ),
    );

    if (result != null && mounted) {
      final borrower = result.borrower;
      final borrowedAt = result.borrowedAt;
      try {
        if (widget.libraryId.isNotEmpty) {
          await _bookcaseService.toggleBookBorrowedStatus(
            libraryId: widget.libraryId,
            bookId: _currentBook.id,
            isBorrowed: true,
            borrowedTo: borrower,
            borrowedAt: borrowedAt,
          );

          // Si el prestatari no és a frequentBorrowers ni és un dels genèrics, desar-lo
          final isGeneric = borrower == 'Jo mateix / Llegint' ||
              borrower == 'Familiar' ||
              borrower == 'Amic/ga' ||
              borrower == 'En lectura';
          if (!isGeneric) {
            final libraryService = LibraryService();
            await libraryService.addFrequentBorrower(
              libraryId: widget.libraryId,
              borrowerName: borrower,
            );
          }
        }
        if (mounted) {
          final newRecord = LoanRecord(
            id: '${borrowedAt.millisecondsSinceEpoch}',
            borrowedTo: borrower,
            borrowedAt: borrowedAt,
            returnedAt: null,
          );
          setState(() {
            _currentBook = _currentBook.copyWith(
              isBorrowed: true,
              borrowedTo: borrower,
              borrowedAt: borrowedAt,
              loanHistory: [..._currentBook.loanHistory, newRecord],
            );
          });
          widget.onBookChanged?.call();
          AppFeedback.showSuccess(context, 'S\'ha marcat «${_currentBook.title}» com a prestat.');
        }
      } catch (e) {
        if (mounted) {
          AppFeedback.showError(context, 'Error en marcar com a prestat: $e');
        }
      }
    }
  }
}

/// Resultat retornat pel diàleg de préstec
class BorrowDialogResult {
  final String borrower;
  final DateTime borrowedAt;

  const BorrowDialogResult({
    required this.borrower,
    required this.borrowedAt,
  });
}

/// Modal / diàleg per treure un llibre de la balda amb xips de suggeriments i selector de data/hora
class _BorrowBookDialog extends StatefulWidget {
  final List<String> suggestions;
  final DateTime initialDateTime;

  const _BorrowBookDialog({
    required this.suggestions,
    required this.initialDateTime,
  });

  @override
  State<_BorrowBookDialog> createState() => _BorrowBookDialogState();
}

class _BorrowBookDialogState extends State<_BorrowBookDialog> {
  late final TextEditingController _controller;
  late DateTime _selectedDateTime;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.suggestions.isNotEmpty ? widget.suggestions.first : 'Jo mateix / Llegint',
    );
    _selectedDateTime = widget.initialDateTime;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year;
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y · $h:$min';
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      cancelText: 'Cancel·lar',
      confirmText: 'Acceptar',
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      cancelText: 'Cancel·lar',
      confirmText: 'Acceptar',
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.outbox_rounded, color: Color(0xFFE65100), size: 24),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Treure de la balda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'A qui el prestes o qui l\'està llegint?',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('borrowed_to_text_field'),
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Nom de la persona...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.suggestions.isNotEmpty) ...[
              const Text(
                'Suggeriments habituals:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: widget.suggestions.map((suggestion) {
                  return ActionChip(
                    key: Key('borrow_chip_$suggestion'),
                    label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                    onPressed: () {
                      _controller.text = suggestion;
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: _controller.text.length),
                      );
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              'Data i hora d\'inici:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
            const SizedBox(height: 6),
            InkWell(
              key: const Key('borrow_date_picker_button'),
              borderRadius: BorderRadius.circular(12),
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.accent.withAlpha(160)),
                  borderRadius: BorderRadius.circular(12),
                  color: AppColors.surface,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatDateTime(_selectedDateTime),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.edit_calendar_rounded, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel·lar'),
        ),
        ElevatedButton(
          key: const Key('confirm_borrow_button'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () {
            final borrower = _controller.text.trim().isNotEmpty
                ? _controller.text.trim()
                : 'En lectura';
            Navigator.of(context).pop(
              BorrowDialogResult(
                borrower: borrower,
                borrowedAt: _selectedDateTime,
              ),
            );
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

/// Visualitzador de l'historial complet de préstecs d'un llibre
class _LoanHistoryBottomSheet extends StatelessWidget {
  final BookModel book;

  const _LoanHistoryBottomSheet({required this.book});

  String _formatDate(DateTime? date) {
    if (date == null) return 'data desconeguda';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sortedHistory = List<LoanRecord>.from(book.loanHistory)
      ..sort((a, b) => b.borrowedAt.compareTo(a.borrowedAt));

    return SafeArea(
      key: const Key('loan_history_sheet'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                const Icon(Icons.history_rounded, color: AppColors.primary, size: 26),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historial de préstecs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                      ),
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sortedHistory.length,
                separatorBuilder: (context, index) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final record = sortedHistory[index];
                  final isCurrent = record.returnedAt == null;
                  final days = record.durationInDays;
                  final daysLabel = days == 1 ? '1 dia' : '$days dies';

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFFFFF3E0)
                                : const Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCurrent ? Icons.outbox_rounded : Icons.check_circle_rounded,
                            size: 20,
                            color: isCurrent
                                ? const Color(0xFFE65100)
                                : const Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.borrowedTo,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_formatDate(record.borrowedAt)} → ${record.returnedAt != null ? _formatDate(record.returnedAt) : 'En curs'}',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFFFFE0B2)
                                : AppColors.surface,
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFFFFB74D)
                                  : AppColors.accent.withAlpha(120),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isCurrent ? 'En curs ($daysLabel)' : daysLabel,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: isCurrent
                                  ? const Color(0xFFBF360C)
                                  : AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                key: const Key('close_loan_history_button'),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tancar', style: TextStyle(fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
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
