import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/mock_data.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';
import '../models/library_model.dart';
import '../models/shelf_unit_model.dart';
import '../providers/library_provider.dart';
import '../services/auth_service.dart';
import '../widgets/book_card.dart';
import '../widgets/bookcase_carousel.dart';
import '../widgets/library_dialogs.dart';
import 'shelf_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<ShelfUnit> _units = MockData.mockUnits;
  final List<BookModel> _allBooks = MockData.mockBooks;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final text = _searchController.text.trim().toLowerCase();
      if (_searchQuery != text) {
        setState(() {
          _searchQuery = text;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Agrupa els resultats de cerca pel seu moble / estanteria d'origen
  Map<ShelfUnit, List<BookModel>> get _matchingBooksByBookcase {
    if (_searchQuery.isEmpty) return {};

    final Map<ShelfUnit, List<BookModel>> grouped = {};

    final matches = _allBooks.where((book) {
      final titleMatch = book.title.toLowerCase().contains(_searchQuery);
      final authorMatch = book.author.toLowerCase().contains(_searchQuery);
      return titleMatch || authorMatch;
    }).toList();

    for (final book in matches) {
      final unit = MockData.getUnitForShelfCode(book.shelfCode);
      grouped.putIfAbsent(unit, () => []).add(book);
    }

    return grouped;
  }

  int get _totalMatchesCount {
    return _matchingBooksByBookcase.values.fold(0, (sum, list) => sum + list.length);
  }

  int get _totalBooksCount {
    return _units.fold(0, (sum, unit) => sum + unit.bookCount);
  }

  void _navigateToShelfDetail({
    required ShelfUnit bookcase,
    String? initialShelfId,
    String? highlightBookId,
    String? initialSearchQuery,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ShelfDetailScreen(
          bookcase: bookcase,
          initialShelfId: initialShelfId,
          highlightBookId: highlightBookId,
          initialSearchQuery: initialSearchQuery,
        ),
      ),
    );
  }

  /// Navegació intel·ligent directa quan es confirma la cerca amb el teclat (Intro)
  void _handleSearchSubmit() {
    final total = _totalMatchesCount;
    final grouped = _matchingBooksByBookcase;

    // Cas 1: Només 1 resultat global trobat -> salta directament al llibre
    if (total == 1) {
      final entry = grouped.entries.first;
      final unit = entry.key;
      final book = entry.value.first;
      _navigateToShelfDetail(
        bookcase: unit,
        initialShelfId: book.shelfCode,
        highlightBookId: book.id,
      );
    }
    // Cas 2: Múltiples resultats però TOTS a la mateixa estanteria -> obre l'estanteria amb cerca
    else if (grouped.length == 1 && total > 1) {
      final unit = grouped.keys.first;
      _navigateToShelfDetail(
        bookcase: unit,
        initialSearchQuery: _searchQuery,
      );
    }
  }

  void _showLibrarySelectorSheet(BuildContext context) {
    final libraryProvider = context.read<LibraryProvider?>();
    if (libraryProvider == null) return;

    final activeLibrary = libraryProvider.activeLibrary;
    final userLibraries = libraryProvider.userLibraries;
    final canEdit = libraryProvider.canEdit;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      isScrollControlled: true,
      builder: (sheetContext) {
        final librariesToShow = userLibraries.isNotEmpty
            ? userLibraries
            : (activeLibrary != null ? [activeLibrary] : <LibraryModel>[]);

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Les teves biblioteques',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 12),

                if (librariesToShow.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'No hi ha cap biblioteca configurada.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                    ),
                  )
                else
                  ...librariesToShow.map((lib) {
                    final isActive = lib.id == activeLibrary?.id;
                    return InkWell(
                      onTap: () async {
                        Navigator.of(sheetContext).pop();
                        if (!isActive) {
                          await libraryProvider.switchLibrary(lib);
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isActive ? AppColors.accent.withAlpha(40) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isActive ? AppColors.accent : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.shelves,
                              color: isActive ? AppColors.primary : AppColors.textMuted,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lib.name,
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                      color: AppColors.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Codi: ${lib.inviteCode} · ${lib.members.length} membres',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (isActive)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                          ],
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 16),
                const Divider(color: AppColors.accent, height: 1),
                const SizedBox(height: 14),

                // Botó "Compartir codi d'invitació" (visible només per a 'owner' o 'editor')
                if (canEdit && activeLibrary != null) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.share_rounded, color: AppColors.primary),
                    ),
                    title: const Text(
                      "Compartir codi d'invitació",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    subtitle: Text(
                      'Codi: ${activeLibrary.inviteCode}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      showShareLibraryDialog(context);
                    },
                  ),
                  const SizedBox(height: 10),
                ],

                // Accions ràpides inferiors: "Crear nova biblioteca" i "Unir-se amb un altre codi"
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          showCreateLibraryDialog(context);
                        },
                        icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                        label: const Text(
                          'Crear nova',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.accent.withAlpha(150)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(sheetContext).pop();
                          showJoinLibraryDialog(context);
                        },
                        icon: const Icon(Icons.vpn_key_rounded, size: 18, color: AppColors.primary),
                        label: const Text(
                          'Unir-me amb codi',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.accent.withAlpha(150)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Tancar sessió
                Center(
                  child: TextButton.icon(
                    onPressed: () async {
                      Navigator.of(sheetContext).pop();
                      await AuthService().signOut();
                    },
                    icon: const Icon(Icons.logout_rounded, size: 18, color: AppColors.primaryDark),
                    label: const Text(
                      'Tancar sessió',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;
    final groupedMatches = _matchingBooksByBookcase;

    final libraryProvider = context.watch<LibraryProvider?>();
    final activeLibrary = libraryProvider?.activeLibrary;
    final canEdit = libraryProvider?.canEdit ?? true;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        scrolledUnderElevation: 0,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            InkWell(
              onTap: () => _showLibrarySelectorSheet(context),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      activeLibrary?.name ?? 'Llom',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textMain,
                        letterSpacing: -0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(50),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accent.withAlpha(100),
                  width: 1.2,
                ),
              ),
              child: Text(
                '$_totalBooksCount llibres',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Barra de cerca gran i accessible per a gent gran
                    _buildProminentSearchBar(),

                    const SizedBox(height: 16),

                    // Títol de secció d'alta llegibilitat
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(
                        isSearching
                            ? 'Resultats de la cerca ($_totalMatchesCount llibres trobats):'
                            : 'Les teves estanteries:',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMain,
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Contingut: Carrusel Cover Flow o Resultats agrupats per moble
                    Expanded(
                      child: isSearching
                          ? _buildGroupedSearchResults(groupedMatches)
                          : _buildCarousel(),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Preparant càmera per fotografiar baldes...',
                      style: TextStyle(fontSize: 16),
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_a_photo_rounded, size: 26),
              label: const Text(
                'Afegir balda / Foto',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildProminentSearchBar() {
    return Container(
      constraints: const BoxConstraints(minHeight: 60),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.accent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _searchController,
          onSubmitted: (_) => _handleSearchSubmit(),
          style: const TextStyle(
            color: AppColors.textMain,
            fontSize: 17,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: 'Escriu el títol o autor per trobar el llibre...',
            hintStyle: TextStyle(
              color: AppColors.textMuted.withAlpha(180),
              fontSize: 16,
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.cancel_rounded,
                      color: AppColors.textMuted,
                      size: 26,
                    ),
                    tooltip: 'Esborrar cerca',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: false,
          ),
        ),
      ),
    );
  }

  Widget _buildCarousel() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 85, top: 6),
      child: BookcaseCarousel(
        units: _units,
        onUnitSelected: (unit) => _navigateToShelfDetail(bookcase: unit),
      ),
    );
  }

  Widget _buildGroupedSearchResults(Map<ShelfUnit, List<BookModel>> grouped) {
    if (grouped.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 68,
                color: AppColors.textMuted.withAlpha(130),
              ),
              const SizedBox(height: 16),
              const Text(
                'No s\'ha trobat cap llibre',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Comprova que el títol o autor estiguin ben escrits.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted.withAlpha(220),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final total = _totalMatchesCount;
    // Cas 2: Múltiples resultats però TOTS a la mateixa estanteria
    final isSingleBookcaseWithMultipleBooks = grouped.length == 1 && total > 1;
    final singleBookcase = isSingleBookcaseWithMultipleBooks ? grouped.keys.first : null;

    return ListView(
      padding: const EdgeInsets.only(bottom: 90, top: 4),
      children: [
        // Botó gran destacat quan tots els resultats són a la mateixa estanteria
        if (isSingleBookcaseWithMultipleBooks && singleBookcase != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: InkWell(
                onTap: () {
                  _navigateToShelfDetail(
                    bookcase: singleBookcase,
                    initialSearchQuery: _searchQuery,
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(50),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.auto_stories_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Veure tots els llibres destacats a ${singleBookcase.name} →',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Obre l\'estanteria amb els $total llibres ressaltats alhora',
                              style: TextStyle(
                                fontSize: 13.5,
                                color: Colors.white.withAlpha(220),
                              ),
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

        // Llistat de grups per estanteria
        ...grouped.entries.map((entry) {
          final unit = entry.key;
          final booksInUnit = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Capçalera destacada del moble d'origen amb icona gran i fons circular
              Container(
                margin: const EdgeInsets.fromLTRB(4, 12, 4, 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.accent.withAlpha(90),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    // Icona a mida generosa (26px) amb fons circular per reforçar la identificació física
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withAlpha(25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          unit.icon,
                          color: AppColors.primary,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trobat a ${unit.name}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${booksInUnit.length} ${booksInUnit.length == 1 ? 'llibre coincident' : 'llibres coincidents'} · ${unit.location}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Acció per obrir l'estanteria sencera
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Obrir estanteria sencera',
                      onPressed: () {
                        _navigateToShelfDetail(
                          bookcase: unit,
                          initialSearchQuery: _searchQuery,
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Llista de targetes 100% interactives
              ...booksInUnit.map((book) {
                return BookCard(
                  book: book,
                  onTap: () {
                    // Navega a ShelfDetailScreen amb bookcase, initialShelfId i highlightBookId
                    _navigateToShelfDetail(
                      bookcase: unit,
                      initialShelfId: book.shelfCode,
                      highlightBookId: book.id,
                    );
                  },
                );
              }),
            ],
          );
        }),
      ],
    );
  }
}
