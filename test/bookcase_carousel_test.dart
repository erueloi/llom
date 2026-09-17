import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llom/models/shelf_unit_model.dart';
import 'package:llom/widgets/bookcase_card.dart';
import 'package:llom/widgets/bookcase_carousel.dart';

void main() {
  const units = [
    ShelfUnit(
      id: 'u1',
      name: 'Estanteria 1 · Finestra',
      location: 'Menjador',
      shelfCount: 4,
      bookCount: 80,
    ),
    ShelfUnit(
      id: 'u2',
      name: 'Estanteria 2 · Porta',
      location: 'Sala d\'estar',
      shelfCount: 3,
      bookCount: 60,
    ),
  ];

  group('BookcaseCard tests', () {
    testWidgets('Renders name, metadata and shelves', (WidgetTester tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: BookcaseCard(
                unit: units[0],
                isFocused: true,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Estanteria 1 · Finestra'), findsOneWidget);
      expect(find.text('80 cm · 4 baldes · 80 llibres'), findsOneWidget);

      await tester.tap(find.byType(BookcaseCard));
      expect(tapped, isTrue);

      // Comprova que el moble amb llibres renderitza decoracions artesanals
      final totalDecorations = find.byKey(const Key('mini_plant_decoration')).evaluate().length +
          find.byKey(const Key('leaning_book_decoration')).evaluate().length +
          find.byKey(const Key('stacked_books_decoration')).evaluate().length +
          find.byKey(const Key('bookend_decoration')).evaluate().length;
      expect(totalDecorations, greaterThanOrEqualTo(1));
    });

    testWidgets('Renders bare wooden shelves with no decorations when bookCount is 0', (WidgetTester tester) async {
      const emptyUnit = ShelfUnit(
        id: 'u_empty',
        name: 'Estanteria Buida',
        location: 'Estudi',
        shelfCount: 3,
        bookCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: BookcaseCard(
                unit: emptyUnit,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Estanteria Buida'), findsOneWidget);
      expect(find.text('80 cm · 3 baldes · 0 llibres'), findsOneWidget);

      // Cap llibre ni detall decoratiu en un moble completament buit
      expect(find.byKey(const Key('mini_plant_decoration')), findsNothing);
      expect(find.byKey(const Key('leaning_book_decoration')), findsNothing);
      expect(find.byKey(const Key('stacked_books_decoration')), findsNothing);
      expect(find.byKey(const Key('bookend_decoration')), findsNothing);
    });

    testWidgets('Renders narrow bookcase (40 cm) with slender proportions', (WidgetTester tester) async {
      const narrowUnit = ShelfUnit(
        id: 'u_narrow',
        name: 'Columna Estreta',
        location: 'Passadís',
        shelfCount: 5,
        bookCount: 25,
        widthCm: 40,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: BookcaseCard(
                unit: narrowUnit,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Columna Estreta'), findsOneWidget);
      expect(find.text('40 cm · 5 baldes · 25 llibres'), findsOneWidget);

      // Comprova que utilitza FractionallySizedBox amb el factor harmònic per a mobles estrets
      final fractionalBox = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox).first);
      expect(fractionalBox.widthFactor, closeTo(0.84, 0.01));
    });

    testWidgets('Respects shelfBookCounts with mixed empty and filled shelves', (WidgetTester tester) async {
      const unit = ShelfUnit(
        id: 'u_mixed',
        name: 'Estanteria Mixta',
        location: 'Saló',
        shelfCount: 3,
        bookCount: 6,
      );

      // Balda 1 té llibres (6), baldes 2 i 3 estan buides (0, 0)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 400,
              child: BookcaseCard(
                unit: unit,
                shelfBookCounts: const [6, 0, 0],
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Comprova que no hi ha desbordament ni decoracions anòmales
      final totalDecorations = find.byKey(const Key('mini_plant_decoration')).evaluate().length +
          find.byKey(const Key('leaning_book_decoration')).evaluate().length +
          find.byKey(const Key('stacked_books_decoration')).evaluate().length +
          find.byKey(const Key('bookend_decoration')).evaluate().length;
      expect(totalDecorations, lessThanOrEqualTo(1));
    });

    testWidgets('Renders all artisanal decoration varieties across diverse bookcases', (WidgetTester tester) async {
      // Provem diverses estanteries amb prou llibres per verificar que tots els tipus de decoració poden aparèixer
      final testUnits = List.generate(
        15,
        (i) => ShelfUnit(
          id: 'unit_$i',
          name: 'Llibreria Variada $i',
          location: 'Habitació $i',
          shelfCount: 5,
          bookCount: 50,
        ),
      );

      final foundDecorations = <String>{};

      for (final u in testUnits) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 400,
                child: BookcaseCard(
                  unit: u,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        if (find.byKey(const Key('mini_plant_decoration')).evaluate().isNotEmpty) {
          foundDecorations.add('plant');
        }
        if (find.byKey(const Key('leaning_book_decoration')).evaluate().isNotEmpty) {
          foundDecorations.add('leaning');
        }
        if (find.byKey(const Key('stacked_books_decoration')).evaluate().isNotEmpty) {
          foundDecorations.add('stacked');
        }
        if (find.byKey(const Key('bookend_decoration')).evaluate().isNotEmpty) {
          foundDecorations.add('bookend');
        }
      }

      // Totes les 4 classes de decoracions han estat renderitzades pel generador determinista
      expect(foundDecorations.contains('plant'), isTrue);
      expect(foundDecorations.contains('leaning'), isTrue);
      expect(foundDecorations.contains('stacked'), isTrue);
      expect(foundDecorations.contains('bookend'), isTrue);
    });
  });

  group('BookcaseCarousel tests', () {
    testWidgets('Renders carousel and navigation arrows', (WidgetTester tester) async {
      ShelfUnit? selected;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 500,
              child: BookcaseCarousel(
                units: units,
                shelfBookCountsMap: const {
                  'u1': [20, 20, 20, 20],
                  'u2': [20, 20, 20],
                },
                onUnitSelected: (u) => selected = u,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Estanteria 1 · Finestra'), findsOneWidget);

      // Tocar el moble central per seleccionar-lo
      await tester.tap(find.text('Estanteria 1 · Finestra'));
      expect(selected?.id, 'u1');

      // Botó de fletxa dreta visible
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_right_rounded));
      await tester.pumpAndSettle();

      // Ara el botó esquerre hauria de ser visible
      expect(find.byIcon(Icons.chevron_left_rounded), findsOneWidget);
    });
  });
}
