import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llom/models/book_model.dart';
import 'package:llom/models/shelf_unit_model.dart';
import 'package:llom/screens/shelf_detail_screen.dart';
import 'package:llom/widgets/book_spine_widget.dart';
import 'package:llom/widgets/shelf_row_widget.dart';

void main() {
  group('BookSpineWidget tests', () {
    testWidgets('Renders vertical rotated title and position', (WidgetTester tester) async {
      bool tapped = false;
      final book = BookModel(
        id: 'test-1',
        title: 'Solitud',
        author: 'Víctor Català',
        shelfCode: 'E1-B1',
        positionIndex: 1,
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BookSpineWidget(
                book: book,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Solitud'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);

      await tester.tap(find.byType(BookSpineWidget));
      expect(tapped, isTrue);
    });

    testWidgets('Renders ghost spine and indicator when book is borrowed', (WidgetTester tester) async {
      final borrowedBook = BookModel(
        id: 'test-borrowed',
        title: 'La mort i la primavera',
        author: 'Mercè Rodoreda',
        shelfCode: 'E1-B1',
        positionIndex: 2,
        isBorrowed: true,
        borrowedTo: 'Anna',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: BookSpineWidget(
                book: borrowedBook,
                displayIndex: 2,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('La mort i la primavera'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.byKey(const Key('borrowed_book_indicator')), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Fora de la balda: Anna');
    });
  });

  group('ShelfRowWidget tests', () {
    testWidgets('Renders shelf header, wooden base and horizontal books', (WidgetTester tester) async {
      final books = [
        BookModel(
          id: 'b1',
          title: 'Llibre 1',
          author: 'Autor 1',
          shelfCode: 'E1-B1',
          positionIndex: 1,
          createdAt: DateTime.now(),
        ),
        BookModel(
          id: 'b2',
          title: 'Llibre 2',
          author: 'Autor 2',
          shelfCode: 'E1-B1',
          positionIndex: 2,
          createdAt: DateTime.now(),
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShelfRowWidget(
              title: 'Balda 1 · Superior',
              subtitle: '2 llibres',
              books: books,
              onBookTap: (_) {},
              onCameraTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Balda 1 · Superior'), findsOneWidget);
      expect(find.text('2 llibres'), findsOneWidget);
      expect(find.text('Llibre 1'), findsOneWidget);
      expect(find.text('Llibre 2'), findsOneWidget);
    });
  });

  group('ShelfDetailScreen tests', () {
    testWidgets('Renders shelves, search bar and interactive modal', (WidgetTester tester) async {
      const unit = ShelfUnit(
        id: 'u1',
        name: 'Estanteria 1 · Finestra',
        location: 'Menjador',
        shelfCount: 3,
        bookCount: 15,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: ShelfDetailScreen(
            bookcase: unit,
            initialShelfId: 'E1-B1',
            highlightBookId: 'b1',
          ),
        ),
      );

      expect(find.text('Estanteria 1 · Finestra'), findsOneWidget);
      expect(find.text('Cerca un llibre en aquesta estanteria...'), findsOneWidget);

      // Baldes renderitzades
      expect(find.text('Balda 1 · Superior'), findsOneWidget);
      expect(find.text('La plaça del Diamant'), findsOneWidget);

      // Cerca ràpida
      await tester.enterText(find.byType(TextField), 'Rodoreda');
      await tester.pump();

      // Tap sobre un llibre per obrir el modal
      await tester.tap(find.text('La plaça del Diamant'));
      await tester.pumpAndSettle();

      expect(find.text('Mercè Rodoreda'), findsOneWidget);
      expect(find.textContaining('Posició #1'), findsOneWidget);
    });
  });
}
