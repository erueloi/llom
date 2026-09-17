import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';
import '../services/bookcase_service.dart';
import '../services/library_stats_service.dart';

/// Pantalla d'estadístiques i mètriques de lectura de la biblioteca
class LibraryStatsScreen extends StatelessWidget {
  final String? libraryId;
  final String? libraryName;
  final String? bookcaseId;
  final String? bookcaseName;
  final List<BookModel>? initialBooks;
  final BookcaseService? bookcaseService;

  const LibraryStatsScreen({
    super.key,
    this.libraryId,
    this.libraryName,
    this.bookcaseId,
    this.bookcaseName,
    this.initialBooks,
    this.bookcaseService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain, size: 26),
          tooltip: 'Tornar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadístiques',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textMain,
                letterSpacing: -0.3,
              ),
            ),
            Text(
              bookcaseName ?? libraryName ?? 'Biblioteca',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (initialBooks != null) {
      final stats = LibraryStatsService.calculateStats(initialBooks!);
      return _buildContent(context, stats);
    }

    final cleanLibId = libraryId?.trim() ?? '';
    if (cleanLibId.isEmpty) {
      final stats = LibraryStatsService.calculateStats([]);
      return _buildContent(context, stats);
    }

    final service = bookcaseService ?? BookcaseService();
    final stream = bookcaseId != null && bookcaseId!.trim().isNotEmpty
        ? service.getBooksForBookcase(cleanLibId, bookcaseId!.trim())
        : service.getAllBooks(cleanLibId);

    return StreamBuilder<List<BookModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          );
        }

        final books = snapshot.data ?? [];
        final stats = LibraryStatsService.calculateStats(books);
        return _buildContent(context, stats);
      },
    );
  }

  Widget _buildContent(BuildContext context, LibraryStats stats) {
    if (stats.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.insights_rounded,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Encara no hi ha estadístiques',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Afegeix llibres a la biblioteca o fotografia les teves baldes per veure mètriques detallades de lectura.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted.withAlpha(200),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 750),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
          children: [
            _buildKpiGrid(stats),
            const SizedBox(height: 28),
            _buildTopAuthorsSection(stats),
            const SizedBox(height: 28),
            _buildSingularBooksSection(stats),
            const SizedBox(height: 28),
            _buildDecadesSection(stats),
            if (stats.enrichedBooksCount > 0) ...[
              const SizedBox(height: 24),
              _buildEnrichedFooter(stats),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // SECCIÓ 1: Targetes KPI
  // -------------------------------------------------------------
  Widget _buildKpiGrid(LibraryStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        final cardWidth = isWide ? (constraints.maxWidth - 12) / 2 : double.infinity;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                key: const Key('kpi_total_books'),
                title: 'Total de llibres',
                value: stats.totalBooks.toString(),
                unit: stats.totalBooks == 1 ? 'llibre' : 'llibres',
                icon: Icons.menu_book_rounded,
                accentColor: AppColors.primary,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                key: const Key('kpi_total_pages'),
                title: 'Pàgines totals',
                value: _formatNumber(stats.totalPages),
                unit: 'pàgines estimades',
                icon: Icons.auto_stories_rounded,
                accentColor: const Color(0xFF795548), // Marró terra càlid
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                key: const Key('kpi_borrowed_books'),
                title: 'Fora de la balda',
                value: stats.borrowedBooksCount.toString(),
                unit: stats.borrowedBooksCount == 1 ? 'en préstec / lectura' : 'en préstec / lectura',
                icon: Icons.outbox_rounded,
                accentColor: const Color(0xFFE65100), // Taronja préstec
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _buildKpiCard(
                key: const Key('kpi_average_year'),
                title: 'Any mitjà d\'edició',
                value: stats.averageYear != null ? stats.averageYear.toString() : '—',
                unit: stats.averagePages > 0 ? '~${stats.averagePages} pàg./llibre' : 'any de publicació',
                icon: Icons.history_edu_rounded,
                accentColor: const Color(0xFF00897B), // Verd blavós elegant
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiCard({
    Key? key,
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accent.withAlpha(70),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accentColor.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted.withAlpha(190),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SECCIÓ 2: Top Autors
  // -------------------------------------------------------------
  Widget _buildTopAuthorsSection(LibraryStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.stars_rounded,
          title: 'Top autors de la col·lecció',
          subtitle: 'Autors i autores més presents a la biblioteca',
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('top_authors_container'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withAlpha(70),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: stats.topAuthors.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Encara no hi ha autors catalogats',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              : Column(
                  children: [
                    for (int i = 0; i < stats.topAuthors.length; i++) ...[
                      _buildAuthorRow(
                        rank: i + 1,
                        author: stats.topAuthors[i].key,
                        count: stats.topAuthors[i].value,
                        maxCount: stats.topAuthors.first.value,
                      ),
                      if (i < stats.topAuthors.length - 1)
                        Divider(
                          height: 16,
                          thickness: 0.8,
                          color: AppColors.accent.withAlpha(50),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildAuthorRow({
    required int rank,
    required String author,
    required int count,
    required int maxCount,
  }) {
    final double ratio = maxCount > 0 ? (count / maxCount).clamp(0.05, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: rank == 1
                      ? AppColors.primary
                      : (rank <= 3 ? AppColors.accent : AppColors.canvas),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: rank == 1 ? Colors.white : AppColors.textMain,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  author,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$count ${count == 1 ? 'títol' : 'títols'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.accent.withAlpha(40),
              valueColor: AlwaysStoppedAnimation<Color>(
                rank == 1 ? AppColors.primary : AppColors.primary.withAlpha(180),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SECCIÓ 3: Llibres Singulars ("El veterà" i "El gegant")
  // -------------------------------------------------------------
  Widget _buildSingularBooksSection(LibraryStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.auto_awesome_rounded,
          title: 'Llibres singulars',
          subtitle: 'Els extrems més notables de la teva prestatgeria',
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 500;
            final cardWidth = isWide ? (constraints.maxWidth - 12) / 2 : double.infinity;

            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _buildSingularCard(
                    key: const Key('singular_oldest_book'),
                    badgeText: 'El veterà',
                    icon: Icons.hourglass_bottom_rounded,
                    accentColor: const Color(0xFFD48B38), // Daurat antic càlid
                    book: stats.oldestBook,
                    metricLabel: stats.oldestBook?.publishedYear != null
                        ? 'Edició de l\'any ${stats.oldestBook!.publishedYear}'
                        : null,
                    emptyText: 'Sense anys de publicació registrats',
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _buildSingularCard(
                    key: const Key('singular_longest_book'),
                    badgeText: 'El gegant',
                    icon: Icons.library_books_rounded,
                    accentColor: AppColors.primary,
                    book: stats.longestBook,
                    metricLabel: stats.longestBook?.pageCount != null
                        ? '${_formatNumber(stats.longestBook!.pageCount!)} pàgines de volum'
                        : null,
                    emptyText: 'Sense recompte de pàgines registrat',
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildSingularCard({
    Key? key,
    required String badgeText,
    required IconData icon,
    required Color accentColor,
    required BookModel? book,
    required String? metricLabel,
    required String emptyText,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accent.withAlpha(70),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: accentColor),
                    const SizedBox(width: 6),
                    Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (book != null) ...[
            Text(
              book.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              book.author.isNotEmpty ? book.author : 'Autor desconegut',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (metricLabel != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  metricLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain.withAlpha(220),
                  ),
                ),
              ),
            ],
          ] else ...[
            Text(
              emptyText,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // SECCIÓ 4: Distribució per Dècades
  // -------------------------------------------------------------
  Widget _buildDecadesSection(LibraryStats stats) {
    final maxInDecade = stats.booksByDecade.values.fold<int>(0, (max, val) => val > max ? val : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          icon: Icons.timeline_rounded,
          title: 'Distribució per dècades',
          subtitle: 'Cronologia de publicació dels exemplars de la biblioteca',
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('decades_distribution_container'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accent.withAlpha(70),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (final entry in stats.booksByDecade.entries) ...[
                _buildDecadeRow(
                  label: entry.key,
                  count: entry.value,
                  maxCount: maxInDecade,
                ),
                if (entry.key != stats.booksByDecade.keys.last)
                  const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDecadeRow({
    required String label,
    required int count,
    required int maxCount,
  }) {
    final double ratio = maxCount > 0 ? (count / maxCount).clamp(count > 0 ? 0.05 : 0.0, 1.0) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 12,
              backgroundColor: AppColors.canvas,
              valueColor: AlwaysStoppedAnimation<Color>(
                count > 0 ? AppColors.primary : AppColors.accent.withAlpha(50),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            count.toString(),
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: count > 0 ? FontWeight.w800 : FontWeight.w500,
              color: count > 0 ? AppColors.textMain : AppColors.textMuted.withAlpha(120),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Peu informatiu d'enriquiment digital
  // -------------------------------------------------------------
  Widget _buildEnrichedFooter(LibraryStats stats) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.accent.withAlpha(30),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accent.withAlpha(70),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${stats.enrichedBooksCount} de ${stats.totalBooks} llibres amb sinopsi o portada catalogada digitalment.',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.accent.withAlpha(50),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textMain,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      final formatted = number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      return formatted;
    }
    return number.toString();
  }
}
