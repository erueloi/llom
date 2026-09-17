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
    // Proporció física d'amplada: estanteria estreta (ex: 40 cm) es veu clarament més esvelta sense generar buits excessius
    final double widthFactor = (0.68 + (unit.widthCm / 80.0) * 0.32).clamp(0.82, 1.0);

    return Semantics(
      button: true,
      label: '${unit.name}, ${unit.widthCm} cm, ${unit.shelfCount} baldes i ${unit.bookCount} llibres',
      child: Center(
        child: FractionallySizedBox(
          widthFactor: widthFactor,
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
                                    Icons.straighten_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${unit.widthCm} cm · ${unit.shelfCount} ${unit.shelfCount == 1 ? 'balda' : 'baldes'} · ${unit.bookCount} llibres',
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
        ),
      ),
    );
  }

  Widget _buildShelfRow(int shelfIndex) {
    final bool isShelfEmpty;
    final int bookSpinesCount;
    final int maxSpines = ((unit.widthCm / 80.0) * 12).round().clamp(6, 16);

    if (shelfBookCounts != null && shelfIndex < shelfBookCounts!.length) {
      final count = shelfBookCounts![shelfIndex];
      isShelfEmpty = count == 0;
      if (isShelfEmpty) {
        bookSpinesCount = 0;
      } else if (unit.widthCm <= 50) {
        // Estreta (~40 cm): la balda s'omple abans
        bookSpinesCount = count <= 2 ? 3 : (count <= 4 ? 4 : maxSpines);
      } else if (unit.widthCm <= 70) {
        // Mitjana (~60 cm)
        bookSpinesCount = count <= 2 ? 4 : (count <= 5 ? 6 : maxSpines);
      } else {
        // Ampla / Gran (80+ cm)
        bookSpinesCount = count <= 2
            ? 4
            : (count <= 5 ? 7 : (count <= 10 ? 9 : maxSpines));
      }
    } else {
      isShelfEmpty = unit.bookCount == 0;
      final base = ((unit.widthCm / 80.0) * 8).round().clamp(5, 12);
      bookSpinesCount = isShelfEmpty
          ? 0
          : (base + (shelfIndex * 3 + unit.id.hashCode) % 3);
    }

    // Si la balda està buida, no hi ha llibres ni decoració (tauló buit net)
    if (isShelfEmpty) {
      return Column(
        children: [
          const Expanded(child: SizedBox.shrink()),
          _buildShelfBoard(),
        ],
      );
    }

    final shelfSeed = _calculateShelfSeed(shelfIndex);
    final decoration = _getDecorationType(shelfIndex, bookSpinesCount);
    final position = _getDecorationPosition(shelfIndex, decoration);

    final int straightSpinesCount;
    switch (decoration) {
      case _ShelfDecorationType.none:
        straightSpinesCount = bookSpinesCount;
        break;
      case _ShelfDecorationType.leaningBookRight:
      case _ShelfDecorationType.leaningBookLeft:
        straightSpinesCount = (bookSpinesCount - 1).clamp(2, bookSpinesCount);
        break;
      case _ShelfDecorationType.stackedBooks:
        straightSpinesCount = (bookSpinesCount - 2).clamp(2, bookSpinesCount);
        break;
      case _ShelfDecorationType.miniPlant:
      case _ShelfDecorationType.bookend:
        straightSpinesCount = (bookSpinesCount - 1).clamp(2, bookSpinesCount);
        break;
    }

    Widget? decorationWidget;
    switch (decoration) {
      case _ShelfDecorationType.none:
        decorationWidget = null;
        break;
      case _ShelfDecorationType.miniPlant:
        decorationWidget = _buildMiniPlant();
        break;
      case _ShelfDecorationType.leaningBookRight:
        decorationWidget = _buildLeaningBook(
          leanRight: true,
          color: _spineColors[(shelfSeed * 7 + unit.name.length) % _spineColors.length],
        );
        break;
      case _ShelfDecorationType.leaningBookLeft:
        decorationWidget = _buildLeaningBook(
          leanRight: false,
          color: _spineColors[(shelfSeed * 7 + unit.name.length) % _spineColors.length],
        );
        break;
      case _ShelfDecorationType.stackedBooks:
        decorationWidget = _buildStackedBooks(
          color1: _spineColors[shelfSeed % _spineColors.length],
          color2: _spineColors[(shelfSeed + 3) % _spineColors.length],
        );
        break;
      case _ShelfDecorationType.bookend:
        decorationWidget = _buildBookend(
          isLeft: position == _ShelfDecorationPosition.start,
        );
        break;
    }

    List<Widget> buildSpinesRange(int start, int end) {
      return List.generate(end - start, (idx) {
        final bIndex = start + idx;
        final seed = (shelfIndex * 13 + bIndex * 7 + unit.name.length) % 100;
        final color = _spineColors[seed % _spineColors.length];
        final heightFactor = 0.55 + ((seed % 40) / 100);

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
      });
    }

    List<Widget> rowChildren;
    if (decorationWidget == null) {
      rowChildren = buildSpinesRange(0, straightSpinesCount);
    } else {
      switch (position) {
        case _ShelfDecorationPosition.start:
          rowChildren = [
            decorationWidget,
            ...buildSpinesRange(0, straightSpinesCount),
          ];
          break;
        case _ShelfDecorationPosition.end:
          rowChildren = [
            ...buildSpinesRange(0, straightSpinesCount),
            decorationWidget,
          ];
          break;
        case _ShelfDecorationPosition.middle:
          final split = (straightSpinesCount ~/ 2).clamp(1, straightSpinesCount - 1);
          rowChildren = [
            ...buildSpinesRange(0, split),
            decorationWidget,
            ...buildSpinesRange(split, straightSpinesCount),
          ];
          break;
      }
    }

    return Column(
      children: [
        // Zona superior: llibres i detalls artesanals que reposen sobre el tauló
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: rowChildren,
            ),
          ),
        ),

        // Prestatge / Base física de la balda (fusta càlida to roure/beix segons AGENTS.md)
        _buildShelfBoard(),
      ],
    );
  }

  /// Base física de la balda
  Widget _buildShelfBoard() {
    return Container(
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
    );
  }

  /// Hash determinista per evitar parpelleigs entre rebuilds
  int _deterministicStringHash(String str) {
    int hash = 0;
    for (int i = 0; i < str.length; i++) {
      hash = (hash * 31 + str.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    return hash;
  }

  int _calculateShelfSeed(int shelfIndex) {
    int h = _deterministicStringHash(unit.id);
    h = (h * 31 + _deterministicStringHash(unit.name)) & 0x7FFFFFFF;
    h = (h * 31 + shelfIndex) & 0x7FFFFFFF;
    // Mesclador tipus Murmur3 per a una distribució uniforme sense correlacions
    h ^= h >> 16;
    h = (h * 0x45d9f3b) & 0x7FFFFFFF;
    h ^= h >> 15;
    return h.abs();
  }

  _ShelfDecorationType _getDecorationType(int shelfIndex, int bookSpinesCount) {
    // Només s'afegeixen detalls si la balda té prou llibres (com a mínim 4 lloms)
    if (bookSpinesCount < 4) {
      return _ShelfDecorationType.none;
    }

    final seed = _calculateShelfSeed(shelfIndex);
    final roll = seed % 7;
    switch (roll) {
      case 0:
      case 1:
        return _ShelfDecorationType.none; // ~28.5% baldes netes elegants
      case 2:
        return _ShelfDecorationType.miniPlant;
      case 3:
        return _ShelfDecorationType.leaningBookRight;
      case 4:
        return _ShelfDecorationType.leaningBookLeft;
      case 5:
        return _ShelfDecorationType.stackedBooks;
      case 6:
        return _ShelfDecorationType.bookend;
      default:
        return _ShelfDecorationType.none;
    }
  }

  _ShelfDecorationPosition _getDecorationPosition(
    int shelfIndex,
    _ShelfDecorationType decoration,
  ) {
    final seed = _calculateShelfSeed(shelfIndex);
    final posSeed = seed ~/ 7;

    switch (decoration) {
      case _ShelfDecorationType.none:
        return _ShelfDecorationPosition.end;
      case _ShelfDecorationType.miniPlant:
      case _ShelfDecorationType.stackedBooks:
        final p = posSeed % 3;
        return p == 0
            ? _ShelfDecorationPosition.start
            : (p == 1 ? _ShelfDecorationPosition.middle : _ShelfDecorationPosition.end);
      case _ShelfDecorationType.leaningBookRight:
        final p = posSeed % 2;
        return p == 0 ? _ShelfDecorationPosition.end : _ShelfDecorationPosition.middle;
      case _ShelfDecorationType.leaningBookLeft:
        final p = posSeed % 2;
        return p == 0 ? _ShelfDecorationPosition.start : _ShelfDecorationPosition.middle;
      case _ShelfDecorationType.bookend:
        final p = posSeed % 2;
        return p == 0 ? _ShelfDecorationPosition.start : _ShelfDecorationPosition.end;
    }
  }

  /// Detall decoratiu artesanal: petita planta de terracota amb suculenta verda
  Widget _buildMiniPlant() {
    return Tooltip(
      message: 'Detall artesanal: planta',
      child: Container(
        key: const Key('mini_plant_decoration'),
        margin: const EdgeInsets.symmetric(horizontal: 3.0),
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

  /// Detall decoratiu artesanal: llibre inclinat
  Widget _buildLeaningBook({required bool leanRight, required Color color}) {
    return Flexible(
      child: FractionallySizedBox(
        heightFactor: 0.72,
        child: Transform.rotate(
          key: const Key('leaning_book_decoration'),
          angle: leanRight ? 0.20 : -0.20,
          alignment: leanRight ? Alignment.bottomLeft : Alignment.bottomRight,
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
      ),
    );
  }

  /// Detall decoratiu artesanal: pila de 2 llibres en horitzontal
  Widget _buildStackedBooks({required Color color1, required Color color2}) {
    return Tooltip(
      message: 'Detall artesanal: llibres apilats',
      child: Container(
        key: const Key('stacked_books_decoration'),
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Llibre superior (lleugerament més curt)
            Container(
              width: 17,
              height: 5,
              decoration: BoxDecoration(
                color: color2,
                borderRadius: BorderRadius.circular(1.5),
                border: Border.all(
                  color: AppColors.accent.withAlpha(80),
                  width: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 1),
            // Llibre inferior
            Container(
              width: 21,
              height: 6,
              decoration: BoxDecoration(
                color: color1,
                borderRadius: BorderRadius.circular(1.5),
                border: Border.all(
                  color: AppColors.accent.withAlpha(80),
                  width: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Detall decoratiu artesanal: subjectallibres metàl·lic / bronze
  Widget _buildBookend({required bool isLeft}) {
    return Tooltip(
      message: 'Detall artesanal: subjectallibres',
      child: Container(
        key: const Key('bookend_decoration'),
        margin: EdgeInsets.only(
          left: isLeft ? 1.0 : 3.0,
          right: isLeft ? 3.0 : 1.0,
        ),
        width: 9,
        height: 18,
        child: CustomPaint(
          painter: _BookendPainter(isLeft: isLeft),
        ),
      ),
    );
  }
}

enum _ShelfDecorationType {
  none,
  miniPlant,
  leaningBookRight,
  leaningBookLeft,
  stackedBooks,
  bookend,
}

enum _ShelfDecorationPosition {
  start,
  middle,
  end,
}

class _BookendPainter extends CustomPainter {
  final bool isLeft;

  const _BookendPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFF8D6E63) // Bronze fusta càlida
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final path = Path();
    if (isLeft) {
      // Suport esquerre: paret vertical a la dreta que aguanta els llibres, base cap a l'esquerra
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 2);
      path.lineTo(size.width - 2.5, 2);
      path.lineTo(size.width - 2.5, size.height - 2.5);
      path.lineTo(0, size.height - 2.5);
      path.close();

      final strutPath = Path()
        ..moveTo(2, size.height - 2.5)
        ..lineTo(size.width - 2.5, size.height * 0.4)
        ..lineTo(size.width - 2.5, size.height - 2.5)
        ..close();
      canvas.drawPath(strutPath, fillPaint);
    } else {
      // Suport dret: paret vertical a l'esquerra que aguanta els llibres, base cap a la dreta
      path.moveTo(0, 2);
      path.lineTo(2.5, 2);
      path.lineTo(2.5, size.height - 2.5);
      path.lineTo(size.width, size.height - 2.5);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      final strutPath = Path()
        ..moveTo(2.5, size.height * 0.4)
        ..lineTo(size.width - 2, size.height - 2.5)
        ..lineTo(2.5, size.height - 2.5)
        ..close();
      canvas.drawPath(strutPath, fillPaint);
    }

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _BookendPainter oldDelegate) => oldDelegate.isLeft != isLeft;
}
