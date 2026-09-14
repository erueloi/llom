import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/shelf_unit_model.dart';

class FurnitureCard extends StatelessWidget {
  final ShelfUnit unit;
  final VoidCallback onTap;

  const FurnitureCard({
    super.key,
    required this.unit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${unit.name}, ${unit.shelfCount} baldes i ${unit.bookCount} llibres',
      child: Card(
        elevation: 1,
        shadowColor: AppColors.primary.withAlpha(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColors.accent.withAlpha(70),
            width: 1.2,
          ),
        ),
        color: AppColors.surface,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: const BoxConstraints(minHeight: 110),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                // Icona esquemàtica gran d'estanteria amb fons salmó suau
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(60),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.accent.withAlpha(120),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      unit.icon,
                      size: 34,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Textos d'alta llegibilitat
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unit.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                          letterSpacing: -0.3,
                          height: 1.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${unit.shelfCount} ${unit.shelfCount == 1 ? 'balda' : 'baldes'} · ${unit.bookCount} llibres',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (unit.location.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          unit.location,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryDark.withAlpha(200),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Fletxa d'acció gran i visible en color salmó
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accent.withAlpha(60),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      size: 32,
                      color: AppColors.primary,
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
