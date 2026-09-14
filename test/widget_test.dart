import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llom/main.dart';
import 'package:llom/screens/home_screen.dart';
import 'package:llom/widgets/book_card.dart';

void main() {
  testWidgets('Llom UI sènior, cerca intel·ligent i navegació de focus test', (WidgetTester tester) async {
    await tester.pumpWidget(const LlomApp(home: HomeScreen()));

    // 1. Capçalera i títol
    expect(find.text('Llom'), findsOneWidget);
    expect(find.textContaining('llibres'), findsWidgets);

    // 2. Barra de cerca gran accessible
    expect(
      find.text('Escriu el títol o autor per trobar el llibre...'),
      findsOneWidget,
    );

    // 3. Carrusel de mobles visible inicialment
    expect(find.text('Les teves estanteries:'), findsOneWidget);
    expect(find.text('Estanteria 1 · Finestra'), findsOneWidget);

    // 4. Cas 2: Cerca d'autor amb múltiples llibres a la mateixa estanteria ("Mercè")
    await tester.enterText(find.byType(TextField), 'Mercè');
    await tester.pump();

    // El carrusel s'amaga
    expect(find.text('Les teves estanteries:'), findsNothing);

    // Botó destacat per veure tots els llibres a l'estanteria única
    expect(find.textContaining('Veure tots els llibres destacats a Estanteria 1 · Finestra'), findsOneWidget);

    // Capçalera destacada amb icona circular
    expect(find.text('Trobat a Estanteria 1 · Finestra'), findsOneWidget);

    // Botó d'acció explícit a cada targeta
    expect(find.text('Anar a Balda 1'), findsWidgets);
    expect(find.text('Anar a Balda 2'), findsOneWidget);

    // 5. Netejar la cerca amb el botó 'x' i comprovar que el carrusel es restableix sense parpelleig
    await tester.tap(find.byIcon(Icons.cancel_rounded));
    await tester.pump();
    expect(find.text('Les teves estanteries:'), findsOneWidget);
    expect(find.text('Estanteria 1 · Finestra'), findsOneWidget);

    // 6. Cas 1: Cerca d'un únic resultat ("Solitud")
    await tester.enterText(find.byType(TextField), 'Solitud');
    await tester.pump();

    expect(find.widgetWithText(BookCard, 'Solitud'), findsOneWidget);
    expect(find.text('Víctor Català'), findsOneWidget);
    expect(find.text('Anar a Balda 3'), findsOneWidget);

    // En prémer Intro al teclat (o prémer la targeta), navega directament amb focus
    await tester.showKeyboard(find.byType(TextField));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Estem a ShelfDetailScreen amb el llibre destacat
    expect(find.text('Estanteria 1 · Finestra'), findsOneWidget);
    expect(find.text('Balda 3 · Intermèdia 2'), findsOneWidget);
  });
}
