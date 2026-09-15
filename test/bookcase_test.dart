import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llom/models/bookcase_model.dart';

void main() {
  group('BookcaseModel tests', () {
    final now = DateTime(2026, 9, 14, 12, 0, 0);

    test('Creates model and converts toMap / fromMap correctly', () {
      final model = BookcaseModel(
        id: 'bc_1',
        name: 'Estanteria Finestra',
        room: 'Menjador',
        shelfCount: 5,
        bookCount: 42,
        order: 3,
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['name'], 'Estanteria Finestra');
      expect(map['room'], 'Menjador');
      expect(map['shelfCount'], 5);
      expect(map['bookCount'], 42);
      expect(map['order'], 3);
      expect(map['createdAt'], isA<Timestamp>());

      final restored = BookcaseModel.fromMap(map, 'bc_1');
      expect(restored.id, 'bc_1');
      expect(restored.name, 'Estanteria Finestra');
      expect(restored.room, 'Menjador');
      expect(restored.shelfCount, 5);
      expect(restored.bookCount, 42);
      expect(restored.order, 3);
      expect(restored.createdAt, now);
    });

    test('toShelfUnit creates a compatible ShelfUnit with correct mapping', () {
      final model = BookcaseModel(
        id: 'bc_window',
        name: 'Finestra',
        room: 'Sala d\'Estar',
        shelfCount: 4,
        bookCount: 18,
        createdAt: now,
      );

      final shelfUnit = model.toShelfUnit();
      expect(shelfUnit.id, 'bc_window');
      expect(shelfUnit.name, 'Finestra');
      expect(shelfUnit.location, 'Sala d\'Estar');
      expect(shelfUnit.shelfCount, 4);
      expect(shelfUnit.bookCount, 18);
    });

    test('copyWith works properly', () {
      final model = BookcaseModel(
        id: 'bc_1',
        name: 'Original',
        room: 'Menjador',
        shelfCount: 3,
        bookCount: 5,
        createdAt: now,
      );

      final modified = model.copyWith(
        name: 'Modificada',
        shelfCount: 6,
      );

      expect(modified.id, 'bc_1');
      expect(modified.name, 'Modificada');
      expect(modified.room, 'Menjador');
      expect(modified.shelfCount, 6);
      expect(modified.bookCount, 5);
    });
  });
}
