import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:llom/core/feedback/app_feedback.dart';

void main() {
  group('AppFeedback Widget Tests', () {
    tearDown(() {
      AppFeedback.dismiss();
    });

    testWidgets('Renders success top pill toast with check icon and message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppFeedback.showSuccess(context, 'Llibre guardat correctament!'),
                child: const Text('Show Feedback'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Feedback'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Llibre guardat correctament!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Dismisses on tap
      await tester.tap(find.text('Llibre guardat correctament!'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Llibre guardat correctament!'), findsNothing);
    });

    testWidgets('Renders error toast with action button and executes onAction', (tester) async {
      bool actionExecuted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppFeedback.showError(
                  context,
                  'Error de quota exhaurida',
                  actionLabel: 'Reintentar',
                  onAction: () => actionExecuted = true,
                ),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Error de quota exhaurida'), findsOneWidget);
      expect(find.byIcon(Icons.error_rounded), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);

      await tester.tap(find.text('Reintentar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(actionExecuted, isTrue);
      expect(find.text('Error de quota exhaurida'), findsNothing);
    });

    testWidgets('Warning and Info toasts render their corresponding icons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  ElevatedButton(
                    onPressed: () => AppFeedback.showWarning(context, 'Atenció, camp obligatori'),
                    child: const Text('Warning'),
                  ),
                  ElevatedButton(
                    onPressed: () => AppFeedback.showInfo(context, 'Processant informació...'),
                    child: const Text('Info'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Warning'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Atenció, camp obligatori'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      await tester.tap(find.text('Info'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Processant informació...'), findsOneWidget);
      expect(find.byIcon(Icons.info_rounded), findsOneWidget);
      expect(find.text('Atenció, camp obligatori'), findsNothing); // Old one dismissed

      AppFeedback.dismiss();
      await tester.pumpAndSettle();
    });
  });
}
