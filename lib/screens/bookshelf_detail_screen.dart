import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';
import '../models/bookcase_model.dart';
import '../providers/library_provider.dart';
import '../services/bookcase_service.dart';
import '../widgets/add_manual_book_dialog.dart';
import '../widgets/book_spine_widget.dart';

/// Pantalla de detall d'un moble d'estanteria amb les seves baldes llistades verticalment
class BookshelfDetailScreen extends StatefulWidget {
  final BookcaseModel bookcase;
  final String libraryId;
  final BookcaseService? bookcaseService;

  const BookshelfDetailScreen({
    super.key,
    required this.bookcase,
    required this.libraryId,
    this.bookcaseService,
  });

  @override
  State<BookshelfDetailScreen> createState() => _BookshelfDetailScreenState();
}

class _BookshelfDetailScreenState extends State<BookshelfDetailScreen> {
  late final BookcaseService _bookcaseService;

  @override
  void initState() {
    super.initState();
    _bookcaseService = widget.bookcaseService ?? BookcaseService();
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Preparant càmera per fotografiar la balda... (Properament)'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
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
    // Extreure el número de balda per a l'etiqueta (ex: Balda 2)
    String shelfLabel = book.shelfCode;
    final match = RegExp(r'-B(\d+)$').firstMatch(book.shelfCode);
    if (match != null) {
      shelfLabel = 'Balda ${match.group(1)}';
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nansa superior per arrossegar
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(60),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 32),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          if (book.author.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              book.author,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent.withAlpha(100)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.table_rows_rounded, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            shelfLabel,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.accent.withAlpha(100)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.shelves, size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            currentBookcase.name,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textMain),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (canEdit) ...[
                  Row(
                    children: [
                      // Botó Editar
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            key: const Key('edit_book_button'),
                            onPressed: () {
                              Navigator.of(sheetContext).pop();
                              showEditBookBottomSheet(
                                context,
                                libraryId: widget.libraryId,
                                bookcase: currentBookcase,
                                book: book,
                                bookcaseService: _bookcaseService,
                              );
                            },
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            label: const Text('Editar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Botó Eliminar
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            key: const Key('delete_book_button'),
                            onPressed: () async {
                              final shouldDelete = await showDialog<bool>(
                                context: context,
                                builder: (dialogCtx) => AlertDialog(
                                  backgroundColor: AppColors.surface,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Text('Eliminar llibre'),
                                  content: Text('Segur que vols eliminar "${book.title}" d\'aquesta estanteria? Aquesta acció no es pot desfer.'),
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
                                if (sheetContext.mounted) {
                                  Navigator.of(sheetContext).pop();
                                }
                                try {
                                  await _bookcaseService.deleteBook(
                                    widget.libraryId,
                                    book.id,
                                    currentBookcase.id,
                                  );
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text('S\'ha eliminat "${book.title}".'),
                                        backgroundColor: Colors.red.shade800,
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
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
                            },
                            icon: Icon(Icons.delete_outline_rounded, size: 20, color: Colors.red.shade700),
                            label: Text('Eliminar', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red.shade700)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.red.shade300),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Tancar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                        itemCount: currentBookcase.shelfCount,
                        itemBuilder: (context, index) {
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
                        },
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Preparant càmera per a la Balda $shelfNumber... (Properament)'),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
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
                      return Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: BookSpineWidget(
                            book: book,
                            displayIndex: bIdx + 1,
                            onTap: () => _showBookDetails(book, currentBookcase, canEdit),
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
}
