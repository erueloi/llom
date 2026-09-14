import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';

class BookCard extends StatelessWidget {
  final BookModel book;
  final VoidCallback? onTap;

  const BookCard({
    super.key,
    required this.book,
    this.onTap,
  });

  String _formatShelfCode(String code) {
    if (code.contains('-')) {
      final parts = code.split('-');
      if (parts.length >= 2 && parts[1].toUpperCase().startsWith('B')) {
        return 'Balda ${parts[1].substring(1)}';
      }
      return code.split('-').join(' · ');
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    final formattedShelf = _formatShelfCode(book.shelfCode);

    return Semantics(
      button: true,
      label: 'Llibre ${book.title}, d\'autor ${book.author}, a la balda $formattedShelf, posició número ${book.positionIndex}',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        elevation: 1,
        shadowColor: AppColors.primary.withAlpha(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: AppColors.accent.withAlpha(70),
            width: 1.2,
          ),
        ),
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: const BoxConstraints(minHeight: 110),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                // Indicador visual de llibre / llom accessible
                Container(
                  width: 52,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withAlpha(100),
                      width: 1.2,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.primaryDark,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Informació del llibre amb alta llegibilitat
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        book.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        book.author,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Indicador de posició físic
                      Row(
                        children: [
                          Icon(
                            Icons.swap_horiz_rounded,
                            size: 18,
                            color: AppColors.textMuted.withAlpha(200),
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'Posició #${book.positionIndex} d\'esquerra a dreta',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted.withAlpha(220),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Botó d'acció explícit a la dreta «Anar a Balda X →»
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(65),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withAlpha(140),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Anar a $formattedShelf',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
