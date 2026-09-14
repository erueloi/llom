import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';

class BookSpineWidget extends StatefulWidget {
  final BookModel book;
  final VoidCallback onTap;
  final bool isHighlighted;
  final bool isDimmed;

  const BookSpineWidget({
    super.key,
    required this.book,
    required this.onTap,
    this.isHighlighted = false,
    this.isDimmed = false,
  });

  @override
  State<BookSpineWidget> createState() => _BookSpineWidgetState();
}

class _BookSpineWidgetState extends State<BookSpineWidget> {
  bool _isHoveredOrPressed = false;

  // Paleta de colors de coberta alternats segons disseny
  static const List<Color> _spineColors = [
    Color(0xFFFFFFFF), // Blanc porcellana
    Color(0xFFF2856D), // Salmó d'acció
    Color(0xFFF8B4A6), // Rosa pàl·lid
    Color(0xFFF2EBE9), // Sorra càlida
  ];

  Color _getSpineColor() {
    if (widget.isHighlighted) {
      return AppColors.primary;
    }
    final index = widget.book.title.hashCode.abs() % _spineColors.length;
    return _spineColors[index];
  }

  Color _getTextColor(Color bgColor) {
    if (bgColor == AppColors.primary) {
      return Colors.white;
    }
    return AppColors.textMain;
  }

  double _getSpineHeight() {
    // Variació d'alçada realista entre 185px i 210px
    final variation = (widget.book.title.length * 7 + widget.book.positionIndex * 3) % 25;
    return 185.0 + variation;
  }

  @override
  Widget build(BuildContext context) {
    final spineColor = _getSpineColor();
    final textColor = _getTextColor(spineColor);
    final height = _getSpineHeight();

    // Si està destacat per cerca, es manté elevat permanentment uns 16px
    final double bottomElevation = widget.isHighlighted
        ? 16.0
        : (_isHoveredOrPressed ? 12.0 : 0.0);

    return Semantics(
      button: true,
      label: 'Llibre ${widget.book.title} per ${widget.book.author}, posició ${widget.book.positionIndex}',
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: widget.isDimmed ? 0.4 : 1.0, // Opacitat 0.4 si la cerca no coincideix
        child: MouseRegion(
          onEnter: (_) => setState(() => _isHoveredOrPressed = true),
          onExit: (_) => setState(() => _isHoveredOrPressed = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _isHoveredOrPressed = true),
            onTapUp: (_) => setState(() => _isHoveredOrPressed = false),
            onTapCancel: () => setState(() => _isHoveredOrPressed = false),
            onTap: widget.onTap,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                // Llom de llibre
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.only(
                    right: 5,
                    left: 2,
                    bottom: bottomElevation,
                  ),
                  width: 58,
                  height: height,
                  decoration: BoxDecoration(
                    color: spineColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    border: Border.all(
                      color: widget.isHighlighted
                          ? AppColors.primaryDark
                          : AppColors.accent.withAlpha(120),
                      width: widget.isHighlighted ? 2.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(bottomElevation > 0 ? 55 : 28),
                        blurRadius: bottomElevation > 0 ? 10 : 4,
                        offset: Offset(bottomElevation > 0 ? 3 : 2, bottomElevation > 0 ? -4 : 0),
                      ),
                      if (widget.isHighlighted)
                        BoxShadow(
                          color: AppColors.primary.withAlpha(140),
                          blurRadius: 16,
                          spreadRadius: 3,
                        ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                    child: Stack(
                      children: [
                        // Nervadures clàssiques superiors
                        Positioned(
                          top: 12,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Container(
                                height: 1.5,
                                color: textColor.withAlpha(50),
                              ),
                              const SizedBox(height: 2.5),
                              Container(
                                height: 1.5,
                                color: textColor.withAlpha(50),
                              ),
                            ],
                          ),
                        ),

                        // Títol del llibre en vertical (de baix a dalt)
                        Positioned.fill(
                          top: 26,
                          bottom: 34,
                          child: Center(
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                child: Text(
                                  widget.book.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: textColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Nervadures clàssiques inferiors i posició física
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Container(
                                height: 1.5,
                                color: textColor.withAlpha(50),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '#${widget.book.positionIndex}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: textColor.withAlpha(180),
                                ),
                              ),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Indicador visual superior assenyalant el llibre destacat
                if (widget.isHighlighted)
                  Positioned(
                    bottom: height + bottomElevation + 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(120),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
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
