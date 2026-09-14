import 'package:flutter/material.dart';
import '../../models/book_model.dart';
import '../../models/shelf_unit_model.dart';

class MockData {
  MockData._();

  static const List<ShelfUnit> mockUnits = [
    ShelfUnit(
      id: 'u1',
      name: 'Estanteria 1 · Finestra',
      location: 'Menjador',
      shelfCount: 5,
      bookCount: 112,
      icon: Icons.shelves,
    ),
    ShelfUnit(
      id: 'u2',
      name: 'Estanteria 2 · Porta',
      location: 'Sala d\'estar',
      shelfCount: 4,
      bookCount: 86,
      icon: Icons.table_rows_rounded,
    ),
    ShelfUnit(
      id: 'u3',
      name: 'Estanteria 3 · Passadís',
      location: 'Corredor principal',
      shelfCount: 3,
      bookCount: 47,
      icon: Icons.inventory_2_outlined,
    ),
    ShelfUnit(
      id: 'u4',
      name: 'Estanteria 4 · Despatx',
      location: 'Estudi',
      shelfCount: 6,
      bookCount: 134,
      icon: Icons.auto_stories_outlined,
    ),
  ];

  static List<BookModel> get mockBooks => [
    // Estanteria 1 · Finestra (E1)
    BookModel(
      id: 'b1',
      title: 'La plaça del Diamant',
      author: 'Mercè Rodoreda',
      shelfCode: 'E1-B1',
      positionIndex: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    BookModel(
      id: 'b2',
      title: 'Incerta glòria',
      author: 'Joan Sales',
      shelfCode: 'E1-B1',
      positionIndex: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 18)),
    ),
    BookModel(
      id: 'b3',
      title: 'Aloma',
      author: 'Mercè Rodoreda',
      shelfCode: 'E1-B1',
      positionIndex: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 16)),
    ),
    BookModel(
      id: 'b4',
      title: 'El quadern gris',
      author: 'Josep Pla',
      shelfCode: 'E1-B2',
      positionIndex: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    BookModel(
      id: 'b5',
      title: 'Mirall trencat',
      author: 'Mercè Rodoreda',
      shelfCode: 'E1-B2',
      positionIndex: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 14)),
    ),
    BookModel(
      id: 'b6',
      title: 'Homenatge a Catalunya',
      author: 'George Orwell',
      shelfCode: 'E1-B2',
      positionIndex: 3,
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
    BookModel(
      id: 'b7',
      title: 'Solitud',
      author: 'Víctor Català',
      shelfCode: 'E1-B3',
      positionIndex: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    BookModel(
      id: 'b8',
      title: 'K.L. Reich',
      author: 'Joaquim Amat-Piniella',
      shelfCode: 'E1-B3',
      positionIndex: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 9)),
    ),

    // Estanteria 2 · Porta (E2)
    BookModel(
      id: 'b9',
      title: 'Pedra de tartera',
      author: 'Maria Barbal',
      shelfCode: 'E2-B1',
      positionIndex: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    BookModel(
      id: 'b10',
      title: 'Mecanoscrit del segon origen',
      author: 'Manuel de Pedrolo',
      shelfCode: 'E2-B1',
      positionIndex: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
    ),
    BookModel(
      id: 'b11',
      title: 'Josafat',
      author: 'Prudenci Bertrana',
      shelfCode: 'E2-B2',
      positionIndex: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    BookModel(
      id: 'b12',
      title: 'Tirant lo Blanc',
      author: 'Joanot Martorell',
      shelfCode: 'E2-B2',
      positionIndex: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),

    // Estanteria 3 · Passadís (E3)
    BookModel(
      id: 'b13',
      title: 'Camí de sirga',
      author: 'Jesús Moncada',
      shelfCode: 'E3-B1',
      positionIndex: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    BookModel(
      id: 'b14',
      title: 'Bearn o la sala de les nines',
      author: 'Llorenç Villalonga',
      shelfCode: 'E3-B1',
      positionIndex: 2,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),

    // Estanteria 4 · Despatx (E4)
    BookModel(
      id: 'b15',
      title: 'Canto jo i la muntanya balla',
      author: 'Irene Solà',
      shelfCode: 'E4-B1',
      positionIndex: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    BookModel(
      id: 'b16',
      title: 'Jo confesso',
      author: 'Jaume Cabré',
      shelfCode: 'E4-B2',
      positionIndex: 1,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  static ShelfUnit getUnitForShelfCode(String shelfCode) {
    if (shelfCode.startsWith('E2')) return mockUnits[1];
    if (shelfCode.startsWith('E3')) return mockUnits[2];
    if (shelfCode.startsWith('E4')) return mockUnits[3];
    return mockUnits[0];
  }
}
