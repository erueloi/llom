import 'package:flutter/material.dart';
import '../core/feedback/app_feedback.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';
import '../models/bookcase_model.dart';
import '../services/book_enrichment_service.dart';
import '../services/bookcase_service.dart';

/// Mostra la bottom modal sheet per afegir o editar un llibre en una estanteria
Future<BookModel?> showBookFormBottomSheet(
  BuildContext context, {
  required String libraryId,
  required BookcaseModel bookcase,
  BookModel? existingBook,
  int? initialShelfIndex,
  BookcaseService? bookcaseService,
  BookEnrichmentService? enrichmentService,
}) async {
  return showModalBottomSheet<BookModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return AddEditBookBottomSheet(
        libraryId: libraryId,
        bookcase: bookcase,
        existingBook: existingBook,
        initialShelfIndex: initialShelfIndex,
        bookcaseService: bookcaseService,
        enrichmentService: enrichmentService,
      );
    },
  );
}

/// Mètode d'accessibilitat per obrir el formulari en mode creació (retrocompatible)
Future<BookModel?> showAddManualBookDialog(
  BuildContext context, {
  required String libraryId,
  required BookcaseModel bookcase,
  int? initialShelfIndex,
  BookcaseService? bookcaseService,
  BookEnrichmentService? enrichmentService,
}) {
  return showBookFormBottomSheet(
    context,
    libraryId: libraryId,
    bookcase: bookcase,
    initialShelfIndex: initialShelfIndex,
    bookcaseService: bookcaseService,
    enrichmentService: enrichmentService,
  );
}

/// Mètode d'accessibilitat per obrir el formulari en mode edició
Future<BookModel?> showEditBookBottomSheet(
  BuildContext context, {
  required String libraryId,
  required BookcaseModel bookcase,
  required BookModel book,
  BookcaseService? bookcaseService,
  BookEnrichmentService? enrichmentService,
}) {
  return showBookFormBottomSheet(
    context,
    libraryId: libraryId,
    bookcase: bookcase,
    existingBook: book,
    bookcaseService: bookcaseService,
    enrichmentService: enrichmentService,
  );
}

/// Widget tipus Bottom Sheet per a l'alta i edició manual de llibres
class AddEditBookBottomSheet extends StatefulWidget {
  final String libraryId;
  final BookcaseModel bookcase;
  final BookModel? existingBook;
  final int? initialShelfIndex;
  final BookcaseService? bookcaseService;
  final BookEnrichmentService? enrichmentService;

  const AddEditBookBottomSheet({
    super.key,
    required this.libraryId,
    required this.bookcase,
    this.existingBook,
    this.initialShelfIndex,
    this.bookcaseService,
    this.enrichmentService,
  });

  @override
  State<AddEditBookBottomSheet> createState() => _AddEditBookBottomSheetState();
}

/// Àlies per compatibilitat amb codi i tests anteriors
typedef AddManualBookDialog = AddEditBookBottomSheet;

class _AddEditBookBottomSheetState extends State<AddEditBookBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final BookEnrichmentService _enrichmentService;
  late int _selectedShelf;
  bool _isLoading = false;
  bool _isSearchingAuthor = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingBook != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingBook?.title ?? '');
    _authorController = TextEditingController(text: widget.existingBook?.author ?? '');
    _enrichmentService = widget.enrichmentService ?? BookEnrichmentService();

    final maxShelves = widget.bookcase.shelfCount > 0 ? widget.bookcase.shelfCount : 1;

    // Extreure la balda del llibre existent o utilitzar initialShelfIndex
    int initial = widget.initialShelfIndex ?? 1;
    if (_isEditing && widget.existingBook!.shelfCode.isNotEmpty) {
      final match = RegExp(r'-B(\d+)$').firstMatch(widget.existingBook!.shelfCode);
      if (match != null) {
        final parsed = int.tryParse(match.group(1) ?? '');
        if (parsed != null) {
          initial = parsed;
        }
      }
    }
    _selectedShelf = initial.clamp(1, maxShelves);
  }

  Future<void> _lookupAuthor() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      AppFeedback.showWarning(context, 'Escriu primer el títol del llibre per cercar-ne l\'autor/a.');
      return;
    }

    setState(() {
      _isSearchingAuthor = true;
    });

    try {
      final foundAuthor = await _enrichmentService.lookupAuthorByTitle(title);
      if (!mounted) return;

      if (foundAuthor != null && foundAuthor.isNotEmpty) {
        setState(() {
          _authorController.text = foundAuthor;
        });
        AppFeedback.showSuccess(context, 'S\'ha trobat l\'autor/a: "$foundAuthor"');
      } else {
        AppFeedback.showInfo(context, 'No s\'ha trobat l\'autor/a automàticament.');
      }
    } catch (e) {
      if (mounted) {
        AppFeedback.showError(context, 'Error en consultar el servei d\'autors.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingAuthor = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final title = _titleController.text.trim();
      final author = _authorController.text.trim();
      final cleanBookcaseId = widget.bookcase.id.trim().isNotEmpty
          ? widget.bookcase.id.trim()
          : 'bookcase_default';
      final service = widget.bookcaseService ?? BookcaseService();

      if (_isEditing) {
        final updatedBook = widget.existingBook!.copyWith(
          title: title,
          author: author,
          shelfCode: '$cleanBookcaseId-B$_selectedShelf',
          bookcaseId: cleanBookcaseId,
        );

        final savedBook = await service.updateBook(
          widget.libraryId,
          updatedBook,
          oldBookcaseId: widget.existingBook!.bookcaseId,
        );

        if (mounted) {
          AppFeedback.showSuccess(context, 'Llibre "$title" actualitzat correctament!');
          Navigator.of(context).pop(savedBook);
        }
      } else {
        final newBook = BookModel(
          id: '',
          title: title,
          author: author,
          shelfCode: '$cleanBookcaseId-B$_selectedShelf',
          bookcaseId: cleanBookcaseId,
          positionIndex: DateTime.now().millisecondsSinceEpoch,
          createdAt: DateTime.now(),
        );

        final savedBook = await service.addBook(widget.libraryId, newBook);

        if (mounted) {
          AppFeedback.showSuccess(context, 'Llibre "$title" afegit a la balda $_selectedShelf!');
          Navigator.of(context).pop(savedBook);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "No s'ha pogut desar el llibre: ${e.toString()}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxShelves = widget.bookcase.shelfCount > 0 ? widget.bookcase.shelfCount : 1;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 20),
      child: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nansa superior per arrossegar
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(120),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                // Capçalera amb icona i títol
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(50),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        _isEditing ? Icons.edit_note_rounded : Icons.bookmark_add_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Editar llibre' : 'Afegir llibre',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Moble: ${widget.bookcase.name}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Camp Títol (obligatori)
                const Text(
                  'Títol del llibre *',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('book_title_field'),
                  controller: _titleController,
                  autofocus: !_isEditing,
                  style: const TextStyle(fontSize: 16, color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'Ex: El Petit Príncep',
                    prefixIcon: const Icon(Icons.menu_book_rounded, color: AppColors.textMuted),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El títol del llibre és obligatori.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Camp Autor (opcional)
                const Text(
                  'Autor / Autora (opcional)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  key: const Key('book_author_field'),
                  controller: _authorController,
                  style: const TextStyle(fontSize: 16, color: AppColors.textMain),
                  decoration: InputDecoration(
                    hintText: 'Ex: Antoine de Saint-Exupéry',
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                    suffixIcon: _isSearchingAuthor
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            key: const Key('auto_fill_author_button'),
                            icon: const Icon(Icons.auto_fix_high_rounded, color: AppColors.primary),
                            tooltip: 'Cercar l\'autor/a automàticament',
                            onPressed: _lookupAuthor,
                          ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 16),

                // Selector de balda
                const Text(
                  'A quina balda el vols desar?',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textMain),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  key: const Key('book_shelf_dropdown'),
                  initialValue: _selectedShelf,
                  items: List.generate(maxShelves, (index) {
                    final shelfNum = index + 1;
                    return DropdownMenuItem<int>(
                      value: shelfNum,
                      child: Text('Balda $shelfNum'),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedShelf = val;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.table_rows_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline_rounded, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(fontSize: 13, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Botons d'acció inferiors
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text(
                            'Cancel·lar',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          key: const Key('submit_book_button'),
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _isEditing ? 'Desar canvis' : 'Desar llibre',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
