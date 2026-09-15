import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/mock_data.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';
import '../models/bookcase_model.dart';
import '../models/shelf_unit_model.dart';
import '../providers/library_provider.dart';
import '../services/bookcase_service.dart';
import '../services/update_service.dart';
import '../widgets/book_card.dart';
import '../widgets/bookcase_carousel.dart';
import '../widgets/library_dialogs.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'profile_screen.dart';
import 'shelf_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  final BookcaseService? bookcaseService;
  final UpdateService? updateService;

  const HomeScreen({super.key, this.bookcaseService, this.updateService});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final BookcaseService _bookcaseService;
  late final UpdateService _updateService;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<ShelfUnit> _units = MockData.mockUnits;
  final List<BookModel> _allBooks = MockData.mockBooks;

  @override
  void initState() {
    super.initState();
    _bookcaseService = widget.bookcaseService ?? BookcaseService();
    _updateService = widget.updateService ?? UpdateService();
    _searchController.addListener(() {
      final text = _searchController.text.trim().toLowerCase();
      if (_searchQuery != text) {
        setState(() {
          _searchQuery = text;
        });
      }
    });

    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForSilentUpdate());
    }
  }

  Future<void> _checkForSilentUpdate() async {
    try {
      final updateInfo = await _updateService.checkUpdate();
      if (!mounted) return;
      if (updateInfo != null && updateInfo.hasUpdate) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nova versió disponible (v${updateInfo.latestVersion})'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryDark,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Actualitzar',
              textColor: AppColors.accent,
              onPressed: () {
                _updateService.downloadApk(updateInfo.apkUrl);
              },
            ),
          ),
        );
      }
    } catch (_) {
      // Comprovació silenciosa
    }
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

  String _getInitialLetter(UserModel? user, User? fbUser) {
    final name = user?.displayName ?? fbUser?.displayName ?? '';
    if (name.trim().isNotEmpty) {
      return name.trim().substring(0, 1).toUpperCase();
    }
    final email = user?.email ?? fbUser?.email ?? '';
    if (email.trim().isNotEmpty) {
      return email.trim().substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  void _showLibrarySelectorSheet(BuildContext context) {
    showLibrarySelectorSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.isNotEmpty;
    final groupedMatches = _matchingBooksByBookcase;

    final libraryProvider = context.watch<LibraryProvider?>();
    final activeLibrary = libraryProvider?.activeLibrary;
    final canEdit = libraryProvider?.canEdit ?? true;

    User? fbUser;
    try {
      fbUser = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    final user = libraryProvider?.currentUser;
    final photoUrl = user?.photoUrl ?? fbUser?.photoURL;
    final initialLetter = _getInitialLetter(user, fbUser);

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
            if (activeLibrary != null && activeLibrary.id.isNotEmpty)
              StreamBuilder<List<BookcaseModel>>(
                stream: _bookcaseService.getBookcases(activeLibrary.id),
                builder: (context, snapshot) {
                  final bookcases = snapshot.data ?? [];
                  final totalBooks = bookcases.fold<int>(0, (sum, b) => sum + b.bookCount);
                  if (totalBooks == 0) return const SizedBox.shrink();
                  return Container(
                    key: const Key('book_count_badge'),
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
                      '$totalBooks ${totalBooks == 1 ? 'llibre' : 'llibres'}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  );
                },
              )
            else if (_totalBooksCount > 0)
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Tooltip(
                message: 'El teu perfil',
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.accent,
                  foregroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                      ? NetworkImage(photoUrl)
                      : null,
                  onForegroundImageError: (photoUrl != null && photoUrl.isNotEmpty)
                      ? (error, stackTrace) {}
                      : null,
                  child: Text(
                    initialLetter,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
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
                          : _buildBookcaseContent(activeLibrary?.id ?? '', canEdit),
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

  Widget _buildBookcaseContent(String libraryId, bool canEdit) {
    if (libraryId.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 85, top: 6),
        child: BookcaseCarousel(
          units: _units,
          onUnitSelected: (unit) => _navigateToShelfDetail(bookcase: unit),
        ),
      );
    }

    return StreamBuilder<List<BookcaseModel>>(
      stream: _bookcaseService.getBookcases(libraryId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 38,
              height: 38,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          );
        }

        final bookcases = snapshot.data ?? [];

        if (bookcases.isEmpty) {
          return _buildEmptyState(libraryId, canEdit);
        }

        final units = bookcases.map((b) => b.toShelfUnit()).toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 85, top: 6),
          child: BookcaseCarousel(
            units: units,
            onUnitSelected: (unit) => _navigateToShelfDetail(bookcase: unit),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String libraryId, bool canEdit) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.accent.withAlpha(120),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.textMain.withAlpha(15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(50),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withAlpha(80),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.shelves,
                    size: 42,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Encara no hi ha cap estanteria a aquesta biblioteca',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Afegeix el teu primer moble per començar a catalogar els llibres de cada balda.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                if (canEdit && libraryId.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => showAddBookcaseDialog(context, libraryId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 24),
                      label: const Text(
                        'Afegir la primera estanteria',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
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
