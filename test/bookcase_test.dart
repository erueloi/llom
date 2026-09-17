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
      expect(map['widthCm'], 80);
      expect(map['createdAt'], isA<Timestamp>());

      final restored = BookcaseModel.fromMap(map, 'bc_1');
      expect(restored.id, 'bc_1');
      expect(restored.name, 'Estanteria Finestra');
      expect(restored.room, 'Menjador');
      expect(restored.shelfCount, 5);
      expect(restored.bookCount, 42);
      expect(restored.order, 3);
      expect(restored.widthCm, 80);
      expect(restored.createdAt, now);
    });

    test('Handles custom widthCm and widthLabel correctly', () {
      final narrow = BookcaseModel(
        id: 'bc_narrow',
        name: 'Columna Estreta',
        room: 'Passadís',
        shelfCount: 5,
        widthCm: 40,
        createdAt: now,
      );
      expect(narrow.widthCm, 40);
      expect(narrow.widthLabel, 'Estreta (40 cm)');

      final medium = narrow.copyWith(widthCm: 60);
      expect(medium.widthLabel, 'Mitjana (60 cm)');

      final standard = narrow.copyWith(widthCm: 80);
      expect(standard.widthLabel, 'Ampla (80 cm)');

      final large = narrow.copyWith(widthCm: 100);
      expect(large.widthLabel, 'Gran (100 cm)');

      final custom = narrow.copyWith(widthCm: 55);
      expect(custom.widthLabel, '55 cm');
    });

    test('toShelfUnit creates a compatible ShelfUnit with correct mapping', () {
      final model = BookcaseModel(
        id: 'bc_window',
        name: 'Finestra',
        room: 'Sala d\'Estar',
        shelfCount: 4,
        bookCount: 18,
        widthCm: 40,
        createdAt: now,
      );

      final shelfUnit = model.toShelfUnit();
      expect(shelfUnit.id, 'bc_window');
      expect(shelfUnit.name, 'Finestra');
      expect(shelfUnit.location, 'Sala d\'Estar');
      expect(shelfUnit.shelfCount, 4);
      expect(shelfUnit.bookCount, 18);
      expect(shelfUnit.widthCm, 40);
    });

    test('copyWith works properly', () {
      final model = BookcaseModel(
        id: 'bc_1',
        name: 'Original',
        room: 'Menjador',
        shelfCount: 3,
        bookCount: 5,
        widthCm: 80,
        createdAt: now,
      );

      final modified = model.copyWith(
        name: 'Modificada',
        shelfCount: 6,
        widthCm: 40,
      );

      expect(modified.id, 'bc_1');
      expect(modified.name, 'Modificada');
      expect(modified.room, 'Menjador');
      expect(modified.shelfCount, 6);
      expect(modified.bookCount, 5);
      expect(modified.widthCm, 40);
    });
  });
}
