import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/shelf_unit_model.dart';

class BookcaseCard extends StatelessWidget {
  final ShelfUnit unit;
  final VoidCallback onTap;
  final bool isFocused;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canEdit;
  final List<int>? shelfBookCounts;

  const BookcaseCard({
    super.key,
    required this.unit,
    required this.onTap,
    this.isFocused = true,
    this.onEdit,
    this.onDelete,
    this.canEdit = true,
    this.shelfBookCounts,
  });

  // Paleta de colors càlids i editorials per als lloms simulats
  static const List<Color> _spineColors = [
    Color(0xFFF2856D), // Salmó terracota
    Color(0xFFF8B4A6), // Rosa càlid
    Color(0xFFFFFFFF), // Blanc porcellana
    Color(0xFFF5EBE6), // Crema càlid
    Color(0xFFDE6D54), // Terracota intens
    Color(0xFF7A9E9F), // Blau verdós editorial suau
    Color(0xFFE9C46A), // Mostassa càlida
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${unit.name}, ${unit.shelfCount} baldes i ${unit.bookCount} llibres',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              width: 8,
              color: AppColors.accent.withAlpha(128), // 0.5 d'opacitat
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withAlpha(50),
                      blurRadius: 22,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(15),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cos de l'estanteria: baldes horitzontals amb llibres reals simulats
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                  child: Column(
                    children: List.generate(unit.shelfCount, (index) {
                      return Expanded(
                        child: _buildShelfRow(index),
                      );
                    }),
                  ),
                ),
              ),

              // Base del moble: etiqueta gran i recompte amb menú d'opcions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.accent.withAlpha(70),
                      width: 1.2,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            unit.name,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMain,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shelves,
                                size: 15,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  '${unit.shelfCount} ${unit.shelfCount == 1 ? 'balda' : 'baldes'} · ${unit.bookCount} llibres',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMuted,
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
                    if (canEdit && (onEdit != null || onDelete != null))
                      PopupMenuButton<String>(
                        key: Key('bookcase_options_${unit.id}'),
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted, size: 22),
                        tooltip: 'Opcions de l\'estanteria',
                        onSelected: (value) {
                          if (value == 'edit' && onEdit != null) {
                            onEdit!();
                          } else if (value == 'delete' && onDelete != null) {
                            onDelete!();
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.edit_outlined, color: AppColors.textMain, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Editar nom',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline_rounded, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Eliminar estanteria',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red.shade700),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShelfRow(int shelfIndex) {
    final bool isShelfEmpty;
    final int bookSpinesCount;

    if (shelfBookCounts != null && shelfIndex < shelfBookCounts!.length) {
      final count = shelfBookCounts![shelfIndex];
      isShelfEmpty = count == 0;
      bookSpinesCount = isShelfEmpty
          ? 0
          : (count <= 2
              ? 4
              : (count <= 5 ? 7 : (count <= 10 ? 9 : 12)));
    } else {
      isShelfEmpty = unit.bookCount == 0;
      bookSpinesCount = isShelfEmpty
          ? 0
          : (8 + (shelfIndex * 3 + unit.id.hashCode) % 5);
    }

    final bool showPlant = shelfIndex == 0 && unit.bookCount > 0;
    final bool hasLeaningBook = !isShelfEmpty &&
        bookSpinesCount >= 4 &&
        (shelfIndex == 1 || (unit.shelfCount == 1 && shelfIndex == 0));
    final int straightSpinesCount = hasLeaningBook ? bookSpinesCount - 1 : bookSpinesCount;

    return Column(
      children: [
        // Zona superior: llibres i detalls artesanals que reposen sobre el tauló
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: isShelfEmpty
                ? (showPlant
                    ? Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: _buildMiniPlant(),
                        ),
                      )
                    : const SizedBox.shrink())
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Llibres rectes
                      ...List.generate(straightSpinesCount, (bIndex) {
                        final seed = (shelfIndex * 13 + bIndex * 7 + unit.name.length) % 100;
                        final color = _spineColors[seed % _spineColors.length];
                        final heightFactor = 0.55 + ((seed % 40) / 100); // alçades variables

                        return Flexible(
                          child: FractionallySizedBox(
                            heightFactor: heightFactor,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 1.2),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                                border: Border.all(
                                  color: AppColors.accent.withAlpha(80),
                                  width: 0.6,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),

                      // Llibre artesanal inclinat en diagonal (efecte llibreria viva)
                      if (hasLeaningBook)
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: 0.72,
                            child: Transform.rotate(
                              key: const Key('leaning_book_decoration'),
                              angle: 0.20,
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 1.2),
                                decoration: BoxDecoration(
                                  color: _spineColors[(shelfIndex * 7 + unit.name.length) % _spineColors.length],
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                                  border: Border.all(
                                    color: AppColors.accent.withAlpha(80),
                                    width: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Planteta artesanal a la balda superior
                      if (showPlant)
                        _buildMiniPlant(),
                    ],
                  ),
          ),
        ),

        // Prestatge / Base física de la balda (fusta càlida to roure/beix segons AGENTS.md)
        Container(
          height: 8,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFD9C5B2), // Color fusta càlida AGENTS.md
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: const Color(0xFFCBB5A1),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 2,
                offset: const Offset(0, 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Detall decoratiu artesanal: petita planta de terracota amb suculenta verda
  Widget _buildMiniPlant() {
    return Tooltip(
      message: 'Detall artesanal',
      child: Container(
        key: const Key('mini_plant_decoration'),
        margin: const EdgeInsets.only(left: 4.0, right: 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Fulles verdes de suculenta en ventall
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Transform.rotate(
                  angle: -0.38,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 4,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5BA86E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Container(
                  width: 4,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF439055),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Transform.rotate(
                  angle: 0.38,
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    width: 4,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5BA86E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            // Test de terracota amb vora superior
            Container(
              width: 14,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFC86D51), // Terracota càlid
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(3),
                  top: Radius.circular(1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 1,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
