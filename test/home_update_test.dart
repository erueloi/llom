import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/providers/settings_provider.dart';
import 'package:llom/screens/home_screen.dart';
import 'package:llom/services/bookcase_service.dart';
import 'package:llom/services/update_service.dart';

class MockUpdateServiceForHome extends UpdateService {
  final UpdateInfo? updateInfoToReturn;
  bool checkUpdateCalled = false;
  String? downloadedApkUrl;

  MockUpdateServiceForHome({this.updateInfoToReturn});

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

class MockLibraryProviderForHomeUpdate extends LibraryProvider {
  MockLibraryProviderForHomeUpdate({
    UserModel? user,
    LibraryModel? activeLib,
  }) {
    currentUser = user;
    activeLibrary = activeLib;
  }
}

void main() {
  final testUser = UserModel(
    uid: 'user_home_test',
    email: 'home_test@llom.cat',
    displayName: 'Home Test User',
    createdAt: DateTime(2025, 1, 1),
  );

  Widget createTestWidget({
    required UpdateService updateService,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LibraryProvider>(
          create: (_) => MockLibraryProviderForHomeUpdate(user: testUser),
        ),
        ChangeNotifierProvider<SettingsProvider>(
          create: (_) => SettingsProvider(),
        ),
      ],
      child: MaterialApp(
        home: HomeScreen(
          bookcaseService: BookcaseService(),
          updateService: updateService,
        ),
      ),
    );
  }

  group('HomeScreen Silent Update Check', () {
    testWidgets('Shows SnackBar with Actualitzar action when update is available', (tester) async {
      final mockService = MockUpdateServiceForHome(
        updateInfoToReturn: const UpdateInfo(
          hasUpdate: true,
          currentVersion: '1.0.0+1',
          latestVersion: '1.2.0+3',
          apkUrl: 'https://llom-23d56.web.app/llom.apk',
        ),
      );

      await tester.pumpWidget(createTestWidget(updateService: mockService));
      // Allow post-frame callback and async checkUpdate to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockService.checkUpdateCalled, isTrue);
      expect(find.text('Nova versió disponible (v1.2.0+3)'), findsOneWidget);
      expect(find.text('Actualitzar'), findsOneWidget);

      // Wait for SnackBar slide-in animation to complete before tapping
      await tester.pump(const Duration(milliseconds: 750));

      await tester.tap(find.text('Actualitzar'));
      await tester.pump();

      expect(mockService.downloadedApkUrl, 'https://llom-23d56.web.app/llom.apk');
    });

    testWidgets('Does not show SnackBar when no update is available', (tester) async {
      final mockService = MockUpdateServiceForHome(
        updateInfoToReturn: const UpdateInfo(
          hasUpdate: false,
          currentVersion: '1.0.0+1',
          latestVersion: '1.0.0+1',
          apkUrl: 'https://llom-23d56.web.app/llom.apk',
        ),
      );

      await tester.pumpWidget(createTestWidget(updateService: mockService));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(mockService.checkUpdateCalled, isTrue);
      expect(find.text('Actualitzar'), findsNothing);
    });
  });
}
