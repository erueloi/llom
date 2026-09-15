import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/shelf_unit_model.dart';
import 'bookcase_card.dart';

class BookcaseCarousel extends StatefulWidget {
  final List<ShelfUnit> units;
  final ValueChanged<ShelfUnit> onUnitSelected;
  final ValueChanged<ShelfUnit>? onEditUnit;
  final ValueChanged<ShelfUnit>? onDeleteUnit;
  final bool canEdit;
  final int initialPage;

  const BookcaseCarousel({
    super.key,
    required this.units,
    required this.onUnitSelected,
    this.onEditUnit,
    this.onDeleteUnit,
    this.canEdit = true,
    this.initialPage = 0,
  });

  @override
  State<BookcaseCarousel> createState() => _BookcaseCarouselState();
}

class _BookcaseCarouselState extends State<BookcaseCarousel> {
  late PageController _pageController;
  double _currentPage = 0.0;
  double _currentViewportFraction = 0.78;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage.toDouble();
    _pageController = PageController(
      viewportFraction: _currentViewportFraction,
      initialPage: widget.initialPage,
    );
    _pageController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_pageController.hasClients) {
      setState(() {
        _currentPage = _pageController.page ?? _currentPage;
      });
    }
  }

  void _updateViewportFractionIfNeeded(double newFraction) {
    if ((_currentViewportFraction - newFraction).abs() > 0.01) {
      _currentViewportFraction = newFraction;
      final page = _currentPage.round();
      _pageController.removeListener(_onScroll);
      _pageController.dispose();
      _pageController = PageController(
        viewportFraction: newFraction,
        initialPage: page,
      );
      _pageController.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onScroll);
    _pageController.dispose();
    super.dispose();
  }

  void _goToPrevious() {
    if (_pageController.hasClients && _currentPage > 0.1) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _goToNext() {
    if (_pageController.hasClients && _currentPage < widget.units.length - 1.1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // En mòbil: 0.78; En tauleta/web: 0.55
        final targetFraction = constraints.maxWidth < 600 ? 0.78 : 0.55;
        _updateViewportFractionIfNeeded(targetFraction);

        final canGoBack = _currentPage > 0.2;
        final canGoForward = _currentPage < widget.units.length - 1.2;

        return Stack(
          alignment: Alignment.center,
          children: [
            // PageView amb Cover Flow efecte
            PageView.builder(
              controller: _pageController,
              itemCount: widget.units.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final unit = widget.units[index];

                // Càlcul de la distància relativa respecte al centre
                final double diff = (index - _currentPage).abs();
                final double normalizedDiff = diff.clamp(0.0, 1.0);

                // Interpolació suau d'escala (1.0 al centre, 0.85 als laterals)
                final double scale = 1.0 - (0.15 * normalizedDiff);

                // Interpolació d'opacitat (1.0 al centre, 0.55 als laterals)
                final double opacity = 1.0 - (0.45 * normalizedDiff);

                final bool isCenter = diff < 0.5;

                return Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: opacity,
                    child: BookcaseCard(
                      unit: unit,
                      isFocused: isCenter,
                      canEdit: widget.canEdit,
                      onEdit: widget.onEditUnit != null ? () => widget.onEditUnit!(unit) : null,
                      onDelete: widget.onDeleteUnit != null ? () => widget.onDeleteUnit!(unit) : null,
                      onTap: () {
                        if (isCenter) {
                          // Si es toca el moble central, navega al detall
                          widget.onUnitSelected(unit);
                        } else {
                          // Si es toca un lateral, s'anima per centrar-lo
                          _pageController.animateToPage(
                            index,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            ),

            // Botó flotant esquerre <
            if (canGoBack)
              Positioned(
                left: 10,
                child: Semantics(
                  button: true,
                  label: 'Mobles anteriors',
                  child: _buildNavButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: 'Moble anterior',
                    onPressed: _goToPrevious,
                  ),
                ),
              ),

            // Botó flotant dret >
            if (canGoForward)
              Positioned(
                right: 10,
                child: Semantics(
                  button: true,
                  label: 'Mobles següents',
                  child: _buildNavButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: 'Moble següent',
                    onPressed: _goToNext,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accent.withAlpha(90),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: AppColors.primary.withAlpha(35),
            blurRadius: 14,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          size: 34,
          color: AppColors.primary,
        ),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
