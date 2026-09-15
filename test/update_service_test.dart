import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:llom/services/update_service.dart';

void main() {
  group('UpdateService.isNewerVersion', () {
    test('detects patch, minor and major updates correctly', () {
      expect(UpdateService.isNewerVersion('1.0.1', '1.0.0'), isTrue);
      expect(UpdateService.isNewerVersion('1.1.0', '1.0.9'), isTrue);
      expect(UpdateService.isNewerVersion('2.0.0', '1.9.9'), isTrue);
      expect(UpdateService.isNewerVersion('v1.0.2', '1.0.1'), isTrue);
      expect(UpdateService.isNewerVersion('1.0.0+2', '1.0.0+1'), isTrue);

      expect(UpdateService.isNewerVersion('1.0.0', '1.0.0'), isFalse);
      expect(UpdateService.isNewerVersion('0.9.9', '1.0.0'), isFalse);
      expect(UpdateService.isNewerVersion('1.0.0+1', '1.0.0+2'), isFalse);
      expect(UpdateService.isNewerVersion('', '1.0.0'), isFalse);
    });
  });

  group('UpdateService.checkUpdate', () {
    test('returns UpdateInfo with hasUpdate = true when remote version is higher',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/version.json')) {
          return http.Response(
            jsonEncode({
              'version': '1.1.0',
              'apkUrl': 'https://llom-23d56.web.app/llom.apk',
            }),
            200,
          );
        }
        return http.Response('Not Found', 404);
      });

      final service = UpdateService(
        client: mockClient,
        versionUrl: 'https://test.example.com/version.json',
      );

      final updateInfo = await service.checkUpdate(currentVersionOverride: '1.0.0');

      expect(updateInfo, isNotNull);
      expect(updateInfo!.hasUpdate, isTrue);
      expect(updateInfo.latestVersion, '1.1.0');
      expect(updateInfo.currentVersion, '1.0.0');
      expect(updateInfo.apkUrl, 'https://llom-23d56.web.app/llom.apk');
    });

    test('returns UpdateInfo with hasUpdate = false when already up to date',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'version': '1.0.0',
            'apkUrl': 'https://llom-23d56.web.app/llom.apk',
          }),
          200,
        );
      });

      final service = UpdateService(
        client: mockClient,
        versionUrl: 'https://test.example.com/version.json',
      );

      final updateInfo = await service.checkUpdate(currentVersionOverride: '1.0.0');

      expect(updateInfo, isNotNull);
      expect(updateInfo!.hasUpdate, isFalse);
    });

    test('returns null gracefully on server error', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Server Error', 500);
      });

      final service = UpdateService(
        client: mockClient,
        versionUrl: 'https://test.example.com/version.json',
      );

      final updateInfo = await service.checkUpdate(currentVersionOverride: '1.0.0');
      expect(updateInfo, isNull);
    });
  });
}
