import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';
import 'book_spine_widget.dart';

class ShelfRowWidget extends StatefulWidget {
  final String title;
  final String subtitle;
  final List<BookModel> books;
  final String? searchQuery;
  final String? highlightedBookId;
  final ValueChanged<BookModel> onBookTap;
  final VoidCallback onCameraTap;

  const ShelfRowWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.books,
    this.searchQuery,
    this.highlightedBookId,
    this.canEdit = true,
    required this.onBookTap,
    required this.onCameraTap,
  });

  final bool canEdit;

  @override
  State<ShelfRowWidget> createState() => _ShelfRowWidgetState();
}

class _ShelfRowWidgetState extends State<ShelfRowWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollToHighlightedBookIfNeeded();
  }

  @override
  void didUpdateWidget(covariant ShelfRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightedBookId != oldWidget.highlightedBookId ||
        widget.searchQuery != oldWidget.searchQuery) {
      _scrollToHighlightedBookIfNeeded();
    }
  }

  void _scrollToHighlightedBookIfNeeded() {
    final sortedBooks = List<BookModel>.from(widget.books)
      ..sort((a, b) => a.positionIndex.compareTo(b.positionIndex));

    int bookIndex = -1;
    if (widget.highlightedBookId != null) {
      bookIndex = sortedBooks.indexWhere((b) => b.id == widget.highlightedBookId);
    } else if (widget.searchQuery != null && widget.searchQuery!.trim().isNotEmpty) {
      final q = widget.searchQuery!.trim().toLowerCase();
      bookIndex = sortedBooks.indexWhere((b) =>
          b.title.toLowerCase().contains(q) || b.author.toLowerCase().contains(q));
    }

    if (bookIndex >= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          final targetOffset = (bookIndex * 65.0) - 60.0;
          _scrollController.animateTo(
            targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ordenar els llibres per positionIndex d'esquerra a dreta
    final sortedBooks = List<BookModel>.from(widget.books)
      ..sort((a, b) => a.positionIndex.compareTo(b.positionIndex));

    final hasSearch = widget.searchQuery != null && widget.searchQuery!.trim().isNotEmpty;
    final query = hasSearch ? widget.searchQuery!.trim().toLowerCase() : '';

    final hasHighlightInThisShelf = widget.highlightedBookId != null &&
        sortedBooks.any((b) => b.id == widget.highlightedBookId);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capçalera de la balda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Botó discret de càmera per actualitzar la balda (només si l'usuari pot editar)
                if (widget.canEdit)
                  IconButton.filledTonal(
                    onPressed: widget.onCameraTap,
                    tooltip: 'Actualitzar foto d\'aquesta balda',
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                      size: 20,
                      color: AppColors.primaryDark,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.accent.withAlpha(50),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 4),

          // Contenidor de llibres (alçada ~230px) + Taula / Suport físic de fusta
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                // Fila horitzontal de llibres
                SizedBox(
                  height: 240,
                  child: sortedBooks.isEmpty
                      ? Center(
                          child: Text(
                            'Balda buida. Prem la càmera per afegir-hi llibres.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted.withAlpha(180),
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          itemCount: sortedBooks.length,
                          itemBuilder: (context, index) {
                            final book = sortedBooks[index];

                            bool isHighlighted = false;
                            bool isDimmed = false;

                            if (hasHighlightInThisShelf) {
                              if (book.id == widget.highlightedBookId) {
                                isHighlighted = true;
                              } else {
                                isDimmed = true;
                              }
                            } else if (hasSearch) {
                              final matches = book.title
                                      .toLowerCase()
                                      .contains(query) ||
                                  book.author.toLowerCase().contains(query);
                              if (matches) {
                                isHighlighted = true;
                              } else {
                                isDimmed = true;
                              }
                            }

                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: BookSpineWidget(
                                book: book,
                                isHighlighted: isHighlighted,
                                isDimmed: isDimmed,
                                onTap: () => widget.onBookTap(book),
                              ),
                            );
                          },
                        ),
                ),

                // Base física de la balda (fusta clara #E2D6D2)
                Container(
                  height: 12,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2D6D2),
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(25),
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFD4C4C0),
                      width: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
