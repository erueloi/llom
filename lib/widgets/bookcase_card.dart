import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/shelf_unit_model.dart';

class BookcaseCard extends StatelessWidget {
  final ShelfUnit unit;
  final VoidCallback onTap;
  final bool isFocused;

  const BookcaseCard({
    super.key,
    required this.unit,
    required this.onTap,
    this.isFocused = true,
  });

  // Paleta de colors càlids per als lloms simulats
  static const List<Color> _spineColors = [
    Color(0xFFF2856D), // Salmó
    Color(0xFFF8B4A6), // Rosa
    Color(0xFFFFFFFF), // Blanc
    Color(0xFFF2EBE9), // Sorra càlida
    Color(0xFFDE6D54), // Salmó intens
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

              // Base del moble: etiqueta gran i recompte
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      unit.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
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
                              fontSize: 14.5,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShelfRow(int shelfIndex) {
    // Generar entre 7 i 12 barres de llibres simulats per a cada balda
    final bookSpinesCount = 8 + (shelfIndex * 3 + unit.id.hashCode) % 5;

    return Column(
      children: [
        // Llibres descansant a la balda
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(bookSpinesCount, (bIndex) {
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
            ),
          ),
        ),

        // Prestatge / Base física de la balda (fusta to terra suau)
        Container(
          height: 7,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFE2D6D2),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
