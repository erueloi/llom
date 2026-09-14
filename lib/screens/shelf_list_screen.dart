import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/book_model.dart';
import '../models/shelf_model.dart';
import '../models/shelf_unit_model.dart';
import '../widgets/book_card.dart';

class ShelfListScreen extends StatefulWidget {
  final ShelfUnit unit;
  final String? highlightedBookId;

  const ShelfListScreen({
    super.key,
    required this.unit,
    this.highlightedBookId,
  });

  @override
  State<ShelfListScreen> createState() => _ShelfListScreenState();
}

class _ShelfListScreenState extends State<ShelfListScreen> {
  late List<ShelfModel> _shelves;
  late List<BookModel> _allBooks;
  String? _selectedShelfCode;

  @override
  void initState() {
    super.initState();
    // Dades de prova per a les baldes d'aquest moble
    final unitPrefix = widget.unit.id == 'u1'
        ? 'E1'
        : widget.unit.id == 'u2'
            ? 'E2'
            : 'E3';

    _shelves = List.generate(
      widget.unit.shelfCount,
      (index) => ShelfModel(
        id: '${unitPrefix}_b${index + 1}',
        code: '$unitPrefix-B${index + 1}',
        bookCount: index == 0 ? 2 : (index == 1 ? 2 : 1),
        createdAt: DateTime.now().subtract(Duration(days: (index + 1) * 3)),
      ),
    );

    _allBooks = [
      BookModel(
        id: 'b1',
        title: 'La plaça del Diamant',
        author: 'Mercè Rodoreda',
        shelfCode: 'E1-B1',
        positionIndex: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      BookModel(
        id: 'b2',
        title: 'Incerta glòria',
        author: 'Joan Sales',
        shelfCode: 'E1-B1',
        positionIndex: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      ),
      BookModel(
        id: 'b3',
        title: 'El quadern gris',
        author: 'Josep Pla',
        shelfCode: 'E1-B2',
        positionIndex: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
      ),
      BookModel(
        id: 'b4',
        title: 'Mirall trencat',
        author: 'Mercè Rodoreda',
        shelfCode: 'E1-B2',
        positionIndex: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      BookModel(
        id: 'b5',
        title: 'Pedra de tartera',
        author: 'Maria Barbal',
        shelfCode: 'E2-B1',
        positionIndex: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];

    // Si hi ha un llibre ressaltat, seleccionem automàticament la seva balda
    if (widget.highlightedBookId != null) {
      final found = _allBooks.where((b) => b.id == widget.highlightedBookId);
      if (found.isNotEmpty) {
        _selectedShelfCode = found.first.shelfCode;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            size: 30,
            color: AppColors.textMain,
          ),
          tooltip: 'Tornar enrere',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.unit.name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textMain,
              ),
            ),
            Text(
              '${widget.unit.shelfCount} baldes · ${widget.unit.bookCount} llibres',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              // Capçalera d'instrucció clara per a gent gran
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _selectedShelfCode == null
                      ? 'Tria una balda per veure els llibres que conté:'
                      : 'Llibres a la balda ${_selectedShelfCode!.replaceAll('-', ' · ')}:',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
              ),

              // Selector de baldes horitzontal o llista
              SizedBox(
                height: 54,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _shelves.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedShelfCode == null;
                      return ChoiceChip(
                        label: const Text('Totes les baldes'),
                        selected: isSelected,
                        labelStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : AppColors.textMain,
                        ),
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.accent.withAlpha(90),
                          ),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedShelfCode = null;
                          });
                        },
                      );
                    }

                    final shelf = _shelves[index - 1];
                    final isSelected = _selectedShelfCode == shelf.code;
                    final formatted = shelf.code.replaceAll('-', ' · ');

                    return ChoiceChip(
                      label: Text('Balda $formatted'),
                      selected: isSelected,
                      labelStyle: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : AppColors.textMain,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.accent.withAlpha(90),
                        ),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selectedShelfCode = shelf.code;
                        });
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Llista de llibres de la balda seleccionada
              ..._buildBooksList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Foto de balda per a ${widget.unit.name} properament',
                style: const TextStyle(fontSize: 16),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.camera_alt_rounded, size: 26),
        label: const Text(
          'Fotografiar balda',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBooksList() {
    final filtered = _selectedShelfCode == null
        ? _allBooks
        : _allBooks.where((b) => b.shelfCode == _selectedShelfCode).toList();

    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.menu_book_rounded,
                  size: 64,
                  color: AppColors.textMuted.withAlpha(120),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Aquesta balda encara no té llibres registrats.',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fes una fotografia de la balda per catalogar-los.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        )
      ];
    }

    return filtered.map((book) {
      final isHighlighted = widget.highlightedBookId == book.id;
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: isHighlighted
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary, width: 2.5),
              )
            : null,
        child: BookCard(
          book: book,
          onTap: () {
            _showBookDetail(book);
          },
        ),
      );
    }).toList();
  }

  void _showBookDetail(BookModel book) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 56,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(50),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.book_rounded,
                      color: AppColors.primaryDark,
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          book.author,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withAlpha(90)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ubicació: Balda ${book.shelfCode.replaceAll('-', ' · ')}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textMain,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Posició #${book.positionIndex} d\'esquerra a dreta',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}
