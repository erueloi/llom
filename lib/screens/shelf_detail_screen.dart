import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/mock_data.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';
import '../models/shelf_unit_model.dart';
import '../providers/library_provider.dart';
import '../widgets/shelf_row_widget.dart';

class ShelfDetailScreen extends StatefulWidget {
  final ShelfUnit bookcase;
  final String? initialShelfId;
  final String? highlightBookId;
  final String? initialSearchQuery;

  const ShelfDetailScreen({
    super.key,
    required this.bookcase,
    this.initialShelfId,
    this.highlightBookId,
    this.initialSearchQuery,
  });

  // Getter per retrocompatibilitat
  ShelfUnit get unit => bookcase;

  @override
  State<ShelfDetailScreen> createState() => _ShelfDetailScreenState();
}

class _ShelfDetailScreenState extends State<ShelfDetailScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _shelfKeys = {};

  String _searchQuery = '';
  late final Map<String, List<BookModel>> _booksByShelf;

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!.trim();
      _searchQuery = widget.initialSearchQuery!.trim();
    }

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });

    _initBooks();
    _setupAutoScroll();
  }

  void _initBooks() {
    final prefix = widget.bookcase.id == 'u1'
        ? 'E1'
        : widget.bookcase.id == 'u2'
            ? 'E2'
            : widget.bookcase.id == 'u3'
                ? 'E3'
                : 'E4';

    // Obtenir els llibres centrals filtrats per aquesta estanteria
    final allBooks = MockData.mockBooks;
    _booksByShelf = {};

    for (int i = 1; i <= widget.bookcase.shelfCount; i++) {
      final code = '$prefix-B$i';
      _shelfKeys[code] = GlobalKey();
      _booksByShelf[code] = allBooks.where((b) => b.shelfCode == code).toList();
    }
  }

  String? _findShelfForBook(String? bookId) {
    if (bookId == null) return null;
    for (final entry in _booksByShelf.entries) {
      if (entry.value.any((b) => b.id == bookId)) {
        return entry.key;
      }
    }
    return null;
  }

  void _setupAutoScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetShelf = widget.initialShelfId ?? _findShelfForBook(widget.highlightBookId);
      if (targetShelf != null) {
        final key = _shelfKeys[targetShelf];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeInOutCubic,
            alignment: 0.1,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getShelfLabel(int index) {
    if (index == 0) return 'Superior';
    if (index == widget.bookcase.shelfCount - 1) return 'Inferior';
    return 'Intermèdia $index';
  }

  void _showBookDetailModal(BookModel book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 58,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(50),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          book.author,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent.withAlpha(90)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.place_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Balda ${book.shelfCode.replaceAll('-', ' · ')} (${widget.bookcase.name})',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Posició #${book.positionIndex} d\'esquerra a dreta a la balda',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.watch<LibraryProvider?>()?.canEdit ?? true;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 30,
            color: AppColors.textMain,
          ),
          tooltip: 'Tornar a les estanteries',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bookcase.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            Text(
              '${widget.bookcase.shelfCount} baldes · ${widget.bookcase.bookCount} llibres',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // Cercador ràpid superior
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent, width: 1.2),
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
                ),
              ),

              // Llista vertical de baldes amb desplaçament horitzontal de lloms
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 90),
                  itemCount: widget.bookcase.shelfCount,
                  itemBuilder: (context, index) {
                    final shelfNumber = index + 1;
                    final prefix = widget.bookcase.id == 'u1'
                        ? 'E1'
                        : widget.bookcase.id == 'u2'
                            ? 'E2'
                            : widget.bookcase.id == 'u3'
                                ? 'E3'
                                : 'E4';
                    final shelfCode = '$prefix-B$shelfNumber';
                    final shelfBooks = _booksByShelf[shelfCode] ?? [];
                    final label = _getShelfLabel(index);

                    return Container(
                      key: _shelfKeys[shelfCode],
                      child: ShelfRowWidget(
                        title: 'Balda $shelfNumber · $label',
                        subtitle: '${shelfBooks.length} llibres',
                        books: shelfBooks,
                        searchQuery: _searchQuery,
                        highlightedBookId: widget.highlightBookId,
                        canEdit: canEdit,
                        onBookTap: _showBookDetailModal,
                        onCameraTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Càmera per a la Balda $shelfNumber ($shelfCode)',
                                style: const TextStyle(fontSize: 15),
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Nova foto d\'estanteria per a ${widget.bookcase.name}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_a_photo_rounded, size: 24),
              label: const Text(
                'Fotografiar balda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }
}
