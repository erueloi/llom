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
