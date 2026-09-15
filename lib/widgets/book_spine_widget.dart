import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';

class BookSpineWidget extends StatefulWidget {
  final BookModel book;
  final VoidCallback onTap;
  final bool isHighlighted;
  final bool isDimmed;
  final int? displayIndex;

  const BookSpineWidget({
    super.key,
    required this.book,
    required this.onTap,
    this.isHighlighted = false,
    this.isDimmed = false,
    this.displayIndex,
  });

  @override
  State<BookSpineWidget> createState() => _BookSpineWidgetState();
}

class _BookSpineWidgetState extends State<BookSpineWidget> {
  bool _isHoveredOrPressed = false;

  // Paleta de colors editorials: terracota, blanc porcellana i crema
  static const List<Color> _spineColors = [
    Color(0xFFE2725B), // Terracota
    Color(0xFFFFFFFF), // Blanc porcellana
    Color(0xFFF5EBE6), // Crema càlid
    Color(0xFFE88572), // Terracota suau
  ];

  Color _getSpineColor() {
    if (widget.isHighlighted) {
      return AppColors.primaryDark;
    }
    final index = widget.book.title.hashCode.abs() % _spineColors.length;
    return _spineColors[index];
  }

  Color _getTextColor(Color bgColor) {
    if (bgColor == const Color(0xFFE2725B) ||
        bgColor == const Color(0xFFE88572) ||
        bgColor == AppColors.primary ||
        bgColor == AppColors.primaryDark) {
      return Colors.white;
    }
    return AppColors.textMain;
  }

  double _getSpineHeight() {
    // Variació d'alçada generosa entre 150px i 186px
    final order = widget.displayIndex ?? widget.book.positionIndex;
    final variation = (widget.book.title.length * 7 + order * 5) % 36;
    return 150.0 + variation;
  }

  double _getSpineWidth() {
    // Amplada proporcionada entre 40px i 48px
    final variation = (widget.book.title.length * 3) % 8;
    return 41.0 + variation;
  }

  String _getOrderLabel() {
    if (widget.displayIndex != null) {
      return '#${widget.displayIndex}';
    }
    if (widget.book.positionIndex > 0 && widget.book.positionIndex < 1000) {
      return '#${widget.book.positionIndex}';
    }
    return '#1';
  }

  @override
  Widget build(BuildContext context) {
    final spineColor = _getSpineColor();
    final textColor = _getTextColor(spineColor);
    final height = _getSpineHeight();
    final width = _getSpineWidth();
    final orderLabel = _getOrderLabel();

    // Si està destacat per cerca, es manté elevat permanentment uns 16px
    final double bottomElevation = widget.isHighlighted
        ? 16.0
        : (_isHoveredOrPressed ? 12.0 : 0.0);

    return Semantics(
      button: true,
      label: 'Llibre ${widget.book.title} per ${widget.book.author}, posició $orderLabel',
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
                    right: 4,
                    left: 2,
                    bottom: bottomElevation,
                  ),
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: spineColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    border: Border.all(
                      color: widget.isHighlighted
                          ? AppColors.primaryDark
                          : (spineColor == Colors.white
                              ? AppColors.accent.withAlpha(150)
                              : AppColors.accent.withAlpha(90)),
                      width: widget.isHighlighted ? 2.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(bottomElevation > 0 ? 50 : 25),
                        blurRadius: bottomElevation > 0 ? 8 : 3,
                        offset: Offset(bottomElevation > 0 ? 2 : 1, bottomElevation > 0 ? -3 : 0),
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
                        // Nervadures clàssiques superiors (dues línies gravades)
                        Positioned(
                          top: 10,
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
                          top: 24,
                          bottom: 30,
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
                                    fontSize: 13.0,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Peu del llom: número d'ordre net
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Column(
                            children: [
                              Container(
                                height: 1.0,
                                color: textColor.withAlpha(40),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                orderLabel,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: textColor.withAlpha(190),
                                ),
                              ),
                              const SizedBox(height: 3),
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
