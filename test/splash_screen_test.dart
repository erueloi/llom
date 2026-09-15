import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llom/screens/splash_screen.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Llom',
      packageName: 'com.example.llom',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('SplashScreen displays brand elements, slogan and progress indicator',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          initialDelay: Duration.zero,
          autoNavigate: false,
        ),
      ),
    );

    // Initial pump to render UI and complete any pending microtasks
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Verify title and slogan
    expect(find.text('Llom'), findsOneWidget);
    expect(find.text('Per no perdre cap llibre.'), findsOneWidget);

    // Verify loading indicator
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Verify version text is rendered
    expect(find.textContaining('v1.'), findsOneWidget);
  });

  testWidgets('SplashScreen navigates smoothly to destination widget after delay',
      (WidgetTester tester) async {
    const destinationKey = Key('destination_screen');

    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(
          initialDelay: Duration(milliseconds: 50),
          destination: Scaffold(
            key: destinationKey,
            body: Text('Destination Screen'),
          ),
          autoNavigate: true,
        ),
      ),
    );

    // Initial pump
    await tester.pump();

    // Advance past initialDelay (50ms) + preload futures
    await tester.pump(const Duration(milliseconds: 100));

    // Pump to process pushReplacement transition
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Verify destination is visible
    expect(find.byKey(destinationKey), findsOneWidget);
    expect(find.text('Destination Screen'), findsOneWidget);
  });
}
