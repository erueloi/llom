import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/providers/settings_provider.dart';
import 'package:llom/screens/profile_screen.dart';
import 'package:llom/services/update_service.dart';

class MockUpdateServiceForProfile extends UpdateService {
  final UpdateInfo? updateInfoToReturn;
  bool checkUpdateCalled = false;
  String? downloadedApkUrl;

  MockUpdateServiceForProfile({this.updateInfoToReturn});

  @override
  Future<UpdateInfo?> checkUpdate({String? currentVersionOverride}) async {
    checkUpdateCalled = true;
    return updateInfoToReturn;
  }

  @override
  Future<bool> downloadApk(String url) async {
    downloadedApkUrl = url;
    return true;
  }
}

class MockLibraryProviderForUpdate extends LibraryProvider {
  MockLibraryProviderForUpdate({
    UserModel? user,
    LibraryModel? activeLib,
  }) {
    currentUser = user;
    activeLibrary = activeLib;
  }
}

void main() {
  final testUser = UserModel(
    uid: 'user_test',
    email: 'test@llom.cat',
    displayName: 'Test User',
    createdAt: DateTime(2025, 1, 1),
  );

  Widget createTestWidget({
    required UpdateService updateService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => MockLibraryProviderForUpdate(user: testUser),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
      ],
      child: MaterialApp(
        home: ProfileScreen(updateService: updateService),
      ),
    );
  }

  group('ProfileScreen Update Checking', () {
    testWidgets('Shows AlertDialog when new version is available', (tester) async {
      final mockService = MockUpdateServiceForProfile(
        updateInfoToReturn: const UpdateInfo(
          hasUpdate: true,
          currentVersion: '1.0.0+1',
          latestVersion: '1.1.0+2',
          apkUrl: 'https://llom-23d56.web.app/llom.apk',
        ),
      );

      await tester.pumpWidget(createTestWidget(updateService: mockService));
      await tester.pump();

      // Verify "Comprovar actualitzacions" button is present
      final checkBtn = find.byKey(const Key('check_updates_button'));
      expect(checkBtn, findsOneWidget);

      // Ensure visible and tap on "Comprovar actualitzacions"
      await tester.ensureVisible(checkBtn);
      await tester.pumpAndSettle();
      await tester.tap(checkBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(mockService.checkUpdateCalled, isTrue);

      // Verify AlertDialog with update info
      expect(find.text('Nova versió disponible (v1.1.0+2)'), findsOneWidget);
      expect(find.text('Hi ha una actualització disponible amb millores i correccions.'), findsOneWidget);
      expect(find.text('Descarregar i instal·lar'), findsOneWidget);
      expect(find.text('Més tard'), findsOneWidget);

      // Tap download button
      await tester.tap(find.text('Descarregar i instal·lar'));
      await tester.pump();

      expect(mockService.downloadedApkUrl, 'https://llom-23d56.web.app/llom.apk');
    });

    testWidgets('Shows SnackBar when already up to date', (tester) async {
      final mockService = MockUpdateServiceForProfile(
        updateInfoToReturn: const UpdateInfo(
          hasUpdate: false,
          currentVersion: '1.0.0+1',
          latestVersion: '1.0.0+1',
          apkUrl: 'https://llom-23d56.web.app/llom.apk',
        ),
      );

      await tester.pumpWidget(createTestWidget(updateService: mockService));
      await tester.pump();

      final checkBtn = find.byKey(const Key('check_updates_button'));
      await tester.ensureVisible(checkBtn);
      await tester.pumpAndSettle();
      await tester.tap(checkBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(mockService.checkUpdateCalled, isTrue);
      expect(find.text('Ja tens la darrera versió instal·lada.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
