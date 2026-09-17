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
      expect(find.text('4 baldes · 80 llibres'), findsOneWidget);

      await tester.tap(find.byType(BookcaseCard));
      expect(tapped, isTrue);

      // El moble té llibres, per tant ha de renderitzar la planteta i el llibre inclinat
      expect(find.byKey(const Key('mini_plant_decoration')), findsOneWidget);
      expect(find.byKey(const Key('leaning_book_decoration')), findsOneWidget);
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
      expect(find.text('3 baldes · 0 llibres'), findsOneWidget);

      // Cap llibre ni detall decoratiu en un moble completament buit
      expect(find.byKey(const Key('mini_plant_decoration')), findsNothing);
      expect(find.byKey(const Key('leaning_book_decoration')), findsNothing);
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

      // Balda superior (amb llibres) té la planteta
      expect(find.byKey(const Key('mini_plant_decoration')), findsOneWidget);
      // Balda 2 (índex 1) està buida (0 llibres), per tant no hi ha llibre inclinat
      expect(find.byKey(const Key('leaning_book_decoration')), findsNothing);
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
