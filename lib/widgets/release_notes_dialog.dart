import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:llom/core/theme/app_colors.dart';

/// Mostra un modal inferior accessible amb les notes de versió de l'aplicació
Future<void> showReleaseNotesModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.canvas,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => const _ReleaseNotesSheet(),
  );
}

class _ReleaseNotesSheet extends StatelessWidget {
  const _ReleaseNotesSheet();

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.8;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tirador superior discret
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withAlpha(60),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Capçalera amb icona, títol i botó de tancar gran
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Novetats de la versió',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 28),
                    color: AppColors.textMain,
                    tooltip: 'Tancar',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Cos amb contingut Markdown o missatge alternatiu
            Expanded(
              child: FutureBuilder<String>(
                future: _loadReleaseNotes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    );
                  }

                  final content = snapshot.data;
                  if (content == null || content.trim().isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.description_outlined,
                              size: 48,
                              color: AppColors.textMuted.withAlpha(150),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Encara no hi ha notes de versió disponibles.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Markdown(
                    data: content,
                    shrinkWrap: false,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    styleSheet: MarkdownStyleSheet(
                      h1: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                        letterSpacing: -0.3,
                      ),
                      h2: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                      p: const TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.textMain,
                      ),
                      listBullet: const TextStyle(
                        fontSize: 16,
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      strong: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                      code: TextStyle(
                        backgroundColor: AppColors.surface,
                        color: AppColors.primaryDark,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                      blockSpacing: 14.0,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String> _loadReleaseNotes() async {
    try {
      return await rootBundle.loadString('assets/release_notes.md');
    } catch (_) {
      return '';
    }
  }
}
