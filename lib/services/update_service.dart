import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Model amb la informació d'actualització de l'aplicació
class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String apkUrl;

  const UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.apkUrl,
  });

  @override
  String toString() =>
      'UpdateInfo(hasUpdate: $hasUpdate, currentVersion: $currentVersion, latestVersion: $latestVersion, apkUrl: $apkUrl)';
}

/// Servei per comprovar actualitzacions remotes i descarregar l'APK
class UpdateService {
  static const String defaultVersionUrl = 'https://llom-23d56.web.app/version.json';
  static const String defaultApkUrl = 'https://llom-23d56.web.app/llom.apk';

  final http.Client _client;
  final String versionUrl;

  UpdateService({
    http.Client? client,
    String? versionUrl,
  })  : _client = client ?? http.Client(),
        versionUrl = versionUrl ?? defaultVersionUrl;

  /// Comprova si hi ha una versió més nova disponible a Firebase Hosting
  Future<UpdateInfo?> checkUpdate({String? currentVersionOverride}) async {
    try {
      final currentVersion = currentVersionOverride ?? await _getLocalVersion();
      final uri = Uri.parse(versionUrl);

      final response = await _client.get(
        uri,
        headers: {
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        debugPrint("UpdateService: Error ${response.statusCode} consultant $versionUrl");
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latestVersion = (data['version'] ?? '').toString().trim();
      final apkUrl = (data['apkUrl'] ?? defaultApkUrl).toString().trim();

      if (latestVersion.isEmpty) {
        return null;
      }

      final hasUpdate = isNewerVersion(latestVersion, currentVersion);

      return UpdateInfo(
        hasUpdate: hasUpdate,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        apkUrl: apkUrl.isNotEmpty ? apkUrl : defaultApkUrl,
      );
    } catch (e) {
      debugPrint("UpdateService: No s'ha pogut verificar actualització: $e");
      return null;
    }
  }

  /// Compara dues versions semàntiques (ex: '1.0.1' vs '1.0.0+1')
  static bool isNewerVersion(String remoteVersion, String localVersion) {
    if (remoteVersion.isEmpty || localVersion.isEmpty) return false;

    // Normalitzem traient 'v' inicial
    String cleanRemote = remoteVersion.trim().toLowerCase();
    if (cleanRemote.startsWith('v')) cleanRemote = cleanRemote.substring(1);

    String cleanLocal = localVersion.trim().toLowerCase();
    if (cleanLocal.startsWith('v')) cleanLocal = cleanLocal.substring(1);

    // Separem versió base i número de build si n'hi ha
    final remoteParts = cleanRemote.split('+');
    final localParts = cleanLocal.split('+');

    final remoteSemVer = remoteParts[0].split('.');
    final localSemVer = localParts[0].split('.');

    // Comparem major, minor, patch
    final length = remoteSemVer.length > localSemVer.length
        ? remoteSemVer.length
        : localSemVer.length;

    for (int i = 0; i < length; i++) {
      final r = i < remoteSemVer.length ? (int.tryParse(remoteSemVer[i]) ?? 0) : 0;
      final l = i < localSemVer.length ? (int.tryParse(localSemVer[i]) ?? 0) : 0;

      if (r > l) return true;
      if (r < l) return false;
    }

    // Si SemVer és idèntic, comparem els builds si existeixen
    final remoteBuild = remoteParts.length > 1 ? (int.tryParse(remoteParts[1]) ?? 0) : 0;
    final localBuild = localParts.length > 1 ? (int.tryParse(localParts[1]) ?? 0) : 0;

    return remoteBuild > localBuild;
  }

  /// Obre el navegador o gestor de descàrregues per baixar l'APK
  Future<bool> downloadApk(String url) async {
    try {
      final uri = Uri.parse(url);
      return await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint("UpdateService: Error obrint URL de descàrrega: $e");
      return false;
    }
  }

  Future<String> _getLocalVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final buildSuffix =
          info.buildNumber.isNotEmpty ? '+${info.buildNumber}' : '';
      return '${info.version}$buildSuffix';
    } catch (_) {
      return '1.0.0+1';
    }
  }
}
