import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/mock_data.dart';
import '../core/feedback/app_feedback.dart';
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
import 'bookshelf_detail_screen.dart';
import 'shelf_detail_screen.dart';
import '../services/shelf_vision_service.dart';

class HomeScreen extends StatefulWidget {
  final BookcaseService? bookcaseService;
  final UpdateService? updateService;
  final bool promptApiKeyIfMissing;

  const HomeScreen({
    super.key,
    this.bookcaseService,
    this.updateService,
    this.promptApiKeyIfMissing = false,
  });

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!kIsWeb) {
        _checkForSilentUpdate();
      }
      if (widget.promptApiKeyIfMissing) {
        _checkGeminiApiKey();
      }
    });
  }

  Future<void> _checkGeminiApiKey() async {
    try {
      final key = await ShelfVisionService.getEffectiveApiKey();
      if (!mounted) return;
      if (key == null || key.trim().isEmpty) {
        await ShelfVisionService.promptApiKeyIfNeeded(context);
      }
    } catch (_) {
      // Comprovació silenciosa
    }
  }

  Future<void> _checkForSilentUpdate() async {
    try {
      final updateInfo = await _updateService.checkUpdate();
      if (!mounted) return;
      if (updateInfo != null && updateInfo.hasUpdate) {
        AppFeedback.showInfo(
          context,
          'Nova versió disponible (v${updateInfo.latestVersion})',
          duration: const Duration(seconds: 8),
          actionLabel: 'Actualitzar',
          onAction: () {
            _updateService.downloadApk(updateInfo.apkUrl);
          },
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

  void _navigateToBookshelfDetail({
    required BookcaseModel bookcase,
    required String libraryId,
    String? highlightBookId,
    String? initialSearchQuery,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookshelfDetailScreen(
          bookcase: bookcase,
          libraryId: libraryId,
          bookcaseService: _bookcaseService,
          highlightBookId: highlightBookId,
          initialSearchQuery: initialSearchQuery,
        ),
      ),
    );
  }

  Map<BookcaseModel, List<BookModel>> _getMatchingRealBooks(
    List<BookModel> allBooks,
    List<BookcaseModel> bookcases,
  ) {
    if (_searchQuery.isEmpty) return {};

    final Map<BookcaseModel, List<BookModel>> grouped = {};

    final matches = allBooks.where((book) {
      final titleMatch = book.title.toLowerCase().contains(_searchQuery);
      final authorMatch = book.author.toLowerCase().contains(_searchQuery);
      return titleMatch || authorMatch;
    }).toList();

    for (final book in matches) {
      final bookcase = bookcases.firstWhere(
        (b) => b.id == book.bookcaseId,
        orElse: () => BookcaseModel(
          id: book.bookcaseId ?? '',
          name: 'Estanteria',
          room: '',
          shelfCount: 1,
          bookCount: 1,
          order: 0,
          createdAt: DateTime.now(),
        ),
      );
      grouped.putIfAbsent(bookcase, () => []).add(book);
    }

    return grouped;
  }

  void _handleRealSearchSubmit(
    String libraryId,
    List<BookcaseModel> bookcases,
    List<BookModel> allBooks,
  ) {
    final grouped = _getMatchingRealBooks(allBooks, bookcases);
    final total = grouped.values.fold<int>(0, (sum, list) => sum + list.length);

    if (total == 1) {
      final entry = grouped.entries.first;
      final bookcase = entry.key;
      final book = entry.value.first;
      _navigateToBookshelfDetail(
        bookcase: bookcase,
        libraryId: libraryId,
        highlightBookId: book.id,
        initialSearchQuery: _searchQuery,
      );
    } else if (grouped.length == 1 && total > 1) {
      final bookcase = grouped.keys.first;
      _navigateToBookshelfDetail(
        bookcase: bookcase,
        libraryId: libraryId,
        initialSearchQuery: _searchQuery,
      );
    }
  }

  /// Navegació intel·ligent directa quan es confirma la cerca amb el teclat (Intro) en mode mock
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
        initialSearchQuery: _searchQuery,
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
          if (activeLibrary != null && activeLibrary.id.isNotEmpty) {
            return StreamBuilder<List<BookcaseModel>>(
              stream: _bookcaseService.getBookcases(activeLibrary.id),
              builder: (context, bcSnapshot) {
                final bookcases = bcSnapshot.data ?? [];
                return StreamBuilder<List<BookModel>>(
                  stream: _bookcaseService.getAllBooks(activeLibrary.id),
                  builder: (context, booksSnapshot) {
                    final allBooks = booksSnapshot.data ?? [];
                    final realMatches = _getMatchingRealBooks(allBooks, bookcases);
                    final totalRealMatches = realMatches.values.fold<int>(0, (sum, l) => sum + l.length);

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              _buildProminentSearchBar(
                                onSubmitted: () => _handleRealSearchSubmit(activeLibrary.id, bookcases, allBooks),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                child: Text(
                                  isSearching
                                      ? 'Resultats de la cerca ($totalRealMatches llibres trobats):'
                                      : 'Les teves estanteries:',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textMain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: isSearching
                                    ? _buildGroupedRealSearchResults(
                                        grouped: realMatches,
                                        libraryId: activeLibrary.id,
                                        isLibraryEmpty: allBooks.isEmpty,
                                      )
                                    : (bcSnapshot.connectionState == ConnectionState.waiting
                                        ? const Center(
                                            child: SizedBox(
                                              width: 38,
                                              height: 38,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                                              ),
                                            ),
                                          )
                                        : (bookcases.isEmpty
                                            ? _buildEmptyState(activeLibrary.id, canEdit)
                                            : _buildRealBookcaseCarousel(bookcases, activeLibrary.id, canEdit, allBooks: allBooks))),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }

          // Fallback per a mode mock / sense biblioteca activa (ex. tests unitaris)
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    _buildProminentSearchBar(),
                    const SizedBox(height: 16),
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
                    Expanded(
                      child: isSearching
                          ? _buildGroupedSearchResults(groupedMatches)
                          : _buildBookcaseContent('', canEdit),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: (canEdit && !isSearching)
          ? FloatingActionButton.extended(
              key: const Key('add_bookcase_fab'),
              onPressed: () {
                final libId = activeLibrary?.id ?? '';
                if (libId.isNotEmpty) {
                  showAddBookcaseDialog(context, libId);
                } else {
                  AppFeedback.showWarning(context, 'Primer has de tenir una biblioteca activa.');
                }
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 3,
              icon: const Icon(Icons.add_rounded, size: 28),
              label: const Text(
                'Afegir estanteria',
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

  Widget _buildProminentSearchBar({VoidCallback? onSubmitted}) {
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
          onSubmitted: (_) {
            if (onSubmitted != null) {
              onSubmitted();
            } else {
              _handleSearchSubmit();
            }
          },
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

  Map<String, List<int>> _calculateShelfBookCounts(
    List<BookcaseModel> bookcases,
    List<BookModel> allBooks,
  ) {
    final Map<String, List<int>> countsMap = {};
    for (final bc in bookcases) {
      final counts = List<int>.filled(bc.shelfCount, 0);
      for (final book in allBooks) {
        final matchesBookcase = book.bookcaseId == bc.id ||
            book.shelfCode.trim().startsWith('${bc.id}-B');
        if (matchesBookcase) {
          final match = RegExp(r'-B(\d+)$').firstMatch(book.shelfCode.trim());
          if (match != null) {
            final shelfNum = int.tryParse(match.group(1)!);
            if (shelfNum != null && shelfNum >= 1 && shelfNum <= bc.shelfCount) {
              counts[shelfNum - 1]++;
            }
          }
        }
      }
      countsMap[bc.id] = counts;
    }
    return countsMap;
  }

  Widget _buildRealBookcaseCarousel(
    List<BookcaseModel> bookcases,
    String libraryId,
    bool canEdit, {
    List<BookModel> allBooks = const [],
  }) {
    final units = bookcases.map((b) => b.toShelfUnit()).toList();
    final shelfBookCountsMap = allBooks.isNotEmpty
        ? _calculateShelfBookCounts(bookcases, allBooks)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 85, top: 6),
      child: BookcaseCarousel(
        units: units,
        shelfBookCountsMap: shelfBookCountsMap,
        canEdit: canEdit,
        onUnitSelected: (unit) {
          final bookcase = bookcases.firstWhere(
            (b) => b.id == unit.id,
            orElse: () => BookcaseModel(
              id: unit.id,
              name: unit.name,
              room: unit.location,
              shelfCount: unit.shelfCount,
              bookCount: unit.bookCount,
              createdAt: DateTime.now(),
            ),
          );
          _navigateToBookshelfDetail(bookcase: bookcase, libraryId: libraryId);
        },
        onEditUnit: (unit) {
          final bookcase = bookcases.firstWhere((b) => b.id == unit.id);
          showEditBookcaseNameDialog(context, libraryId, bookcase, bookcaseService: _bookcaseService);
        },
        onDeleteUnit: (unit) {
          final bookcase = bookcases.firstWhere((b) => b.id == unit.id);
          showDeleteBookcaseDialog(context, libraryId, bookcase, bookcaseService: _bookcaseService);
        },
      ),
    );
  }

  Widget _buildBookcaseContent(String libraryId, bool canEdit) {
    if (libraryId.isEmpty) {
      final mockCounts = <String, List<int>>{};
      for (int i = 0; i < _units.length; i++) {
        final unit = _units[i];
        final prefix = 'E${i + 1}';
        final counts = List<int>.filled(unit.shelfCount, 0);
        for (final b in MockData.mockBooks) {
          if (b.shelfCode.startsWith(prefix)) {
            final match = RegExp(r'-B(\d+)$').firstMatch(b.shelfCode);
            if (match != null) {
              final sNum = int.tryParse(match.group(1)!);
              if (sNum != null && sNum >= 1 && sNum <= unit.shelfCount) {
                counts[sNum - 1]++;
              }
            }
          }
        }
        mockCounts[unit.id] = counts;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 85, top: 6),
        child: BookcaseCarousel(
          units: _units,
          shelfBookCountsMap: mockCounts,
          canEdit: canEdit,
          onUnitSelected: (unit) {
            final bookcase = BookcaseModel(
              id: unit.id,
              name: unit.name,
              room: unit.location,
              shelfCount: unit.shelfCount,
              bookCount: unit.bookCount,
              createdAt: DateTime.now(),
            );
            _navigateToBookshelfDetail(bookcase: bookcase, libraryId: '');
          },
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
            canEdit: canEdit,
            onUnitSelected: (unit) {
              final bookcase = bookcases.firstWhere(
                (b) => b.id == unit.id,
                orElse: () => BookcaseModel(
                  id: unit.id,
                  name: unit.name,
                  room: unit.location,
                  shelfCount: unit.shelfCount,
                  bookCount: unit.bookCount,
                  createdAt: DateTime.now(),
                ),
              );
              _navigateToBookshelfDetail(bookcase: bookcase, libraryId: libraryId);
            },
            onEditUnit: (unit) {
              final bookcase = bookcases.firstWhere((b) => b.id == unit.id);
              showEditBookcaseNameDialog(context, libraryId, bookcase, bookcaseService: _bookcaseService);
            },
            onDeleteUnit: (unit) {
              final bookcase = bookcases.firstWhere((b) => b.id == unit.id);
              showDeleteBookcaseDialog(context, libraryId, bookcase, bookcaseService: _bookcaseService);
            },
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

  Widget _buildGroupedRealSearchResults({
    required Map<BookcaseModel, List<BookModel>> grouped,
    required String libraryId,
    required bool isLibraryEmpty,
  }) {
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
                isLibraryEmpty
                    ? 'Encara no hi ha cap llibre catalogat en aquesta biblioteca.'
                    : 'Comprova que el títol o autor estiguin ben escrits.',
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

    final total = grouped.values.fold<int>(0, (sum, list) => sum + list.length);
    final isSingleBookcaseWithMultipleBooks = grouped.length == 1 && total > 1;
    final singleBookcase = isSingleBookcaseWithMultipleBooks ? grouped.keys.first : null;

    return ListView(
      padding: const EdgeInsets.only(bottom: 90, top: 4),
      children: [
        if (isSingleBookcaseWithMultipleBooks && singleBookcase != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
              elevation: 2,
              child: InkWell(
                onTap: () {
                  _navigateToBookshelfDetail(
                    bookcase: singleBookcase,
                    libraryId: libraryId,
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

        ...grouped.entries.map((entry) {
          final bookcase = entry.key;
          final booksInBookcase = entry.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                      child: const Center(
                        child: Icon(
                          Icons.shelves,
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
                            'Trobat a ${bookcase.name}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${booksInBookcase.length} ${booksInBookcase.length == 1 ? 'llibre coincident' : 'llibres coincidents'}${bookcase.room.isNotEmpty ? ' · ${bookcase.room}' : ''}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      tooltip: 'Obrir estanteria sencera',
                      onPressed: () {
                        _navigateToBookshelfDetail(
                          bookcase: bookcase,
                          libraryId: libraryId,
                          initialSearchQuery: _searchQuery,
                        );
                      },
                    ),
                  ],
                ),
              ),

              ...booksInBookcase.map((book) {
                return BookCard(
                  book: book,
                  onTap: () {
                    _navigateToBookshelfDetail(
                      bookcase: bookcase,
                      libraryId: libraryId,
                      highlightBookId: book.id,
                      initialSearchQuery: _searchQuery,
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
                      initialSearchQuery: _searchQuery,
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
