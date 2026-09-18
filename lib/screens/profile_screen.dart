import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/feedback/app_feedback.dart';
import '../core/theme/app_colors.dart';
import '../models/user_model.dart';
import '../providers/library_provider.dart';
import '../providers/settings_provider.dart';
import '../services/auth_service.dart';
import '../services/update_service.dart';
import '../services/shelf_vision_service.dart';
import '../widgets/library_dialogs.dart';
import '../widgets/release_notes_dialog.dart';

/// Pantalla de Perfil d'Usuari amb preferències d'accessibilitat i gestió de sessió
class ProfileScreen extends StatefulWidget {
  final AuthService? authService;
  final UpdateService? updateService;

  const ProfileScreen({super.key, this.authService, this.updateService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _versionDisplay = '1.2.2 (v7)';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.updateService != oldWidget.updateService) {
      _loadAppVersion();
    }
  }

  Future<void> _loadAppVersion() async {
    final service = widget.updateService ?? UpdateService();
    try {
      final v = await service.getLocalVersionDisplay();
      if (mounted && v.isNotEmpty) {
        setState(() {
          _versionDisplay = v;
        });
      }
    } catch (_) {}
  }

  String _getInitialLetter(UserModel? user, User? fbUser) {
    final name = user?.displayName ?? fbUser?.displayName ?? '';
    if (name.trim().isNotEmpty) {
      return name.trim().substring(0, 1).toUpperCase();
    }
    final email = user?.email ?? fbUser?.email ?? '';
    if (email.trim().isNotEmpty) {
      return email.trim().substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'owner':
        return '👑 Propietari/a';
      case 'editor':
        return '✏️ Editor/a';
      case 'viewer':
      default:
        return '👁️ Lector/a';
    }
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: AppColors.surface,
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: AppColors.primary, size: 28),
              SizedBox(width: 10),
              Text(
                'Tancar sessió',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
            ],
          ),
          content: const Text(
            'Segur que vols sortir del teu compte de Llom?',
            style: TextStyle(fontSize: 16, color: AppColors.textMuted),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel·lar',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ),
            ElevatedButton(
              key: const Key('confirm_sign_out_button'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Tancar sessió',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      final libraryProvider = context.read<LibraryProvider?>();
      libraryProvider?.clear();

      final service = widget.authService ?? AuthService();
      await service.signOut();

      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  Future<void> _handleCheckUpdate(BuildContext context, UpdateService service) async {
    AppFeedback.showInfo(
      context,
      'Comprovant actualitzacions...',
      duration: const Duration(seconds: 2),
    );

    final updateInfo = await service.checkUpdate();
    if (!context.mounted) return;

    if (updateInfo != null && updateInfo.hasUpdate) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: AppColors.surface,
            title: Row(
              children: [
                const Icon(Icons.system_update_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Nova versió disponible (v${updateInfo.latestVersion})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
              ],
            ),
            content: const Text(
              'Hi ha una actualització disponible amb millores i correccions.',
              style: TextStyle(fontSize: 15, color: AppColors.textMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Més tard', style: TextStyle(color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  service.downloadApk(updateInfo.apkUrl);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Descarregar i instal·lar'),
              ),
            ],
          );
        },
      );
    } else {
      AppFeedback.showSuccess(
        context,
        'Ja tens la darrera versió instal·lada.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUpdateService = widget.updateService ?? UpdateService();
    final libraryProvider = context.watch<LibraryProvider?>();
    final settingsProvider = context.watch<SettingsProvider?>();

    User? fbUser;
    try {
      fbUser = FirebaseAuth.instance.currentUser;
    } catch (_) {}

    final user = libraryProvider?.currentUser;
    final photoUrl = user?.photoUrl ?? fbUser?.photoURL;
    final displayName = user?.displayName ?? fbUser?.displayName ?? 'Usuari de Llom';
    final email = user?.email ?? fbUser?.email ?? '';
    final initialLetter = _getInitialLetter(user, fbUser);

    final activeLibrary = libraryProvider?.activeLibrary;
    final currentRole = libraryProvider?.currentRole ?? 'viewer';

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMain, size: 28),
          tooltip: 'Tornar enrere',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'El teu perfil',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: AppColors.textMain,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Capçalera d'usuari
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.accent,
                        foregroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                        onForegroundImageError: (photoUrl != null && photoUrl.isNotEmpty)
                            ? (error, stackTrace) {}
                            : null,
                        child: Text(
                          initialLetter,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        displayName.isNotEmpty ? displayName : 'Usuari de Llom',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 12),

                      // Badge de rol a la biblioteca activa
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(45),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.accent.withAlpha(120),
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          activeLibrary != null
                              ? '${_getRoleLabel(currentRole)} a ${activeLibrary.name}'
                              : 'Sense biblioteca activa',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 2. Secció d'Accessibilitat i Preferències (UI Sènior)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Text(
                    'Accessibilitat i Preferències',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accent.withAlpha(100),
                      width: 1.3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                        secondary: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(40),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.format_size_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        title: const Text(
                          'Mode text extra gran',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                        subtitle: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            'Augmenta la mida de la lletra a tota l\'aplicació per facilitar la lectura.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                              height: 1.3,
                            ),
                          ),
                        ),
                        value: settingsProvider?.isExtraLargeText ?? false,
                        activeThumbColor: AppColors.primary,
                        onChanged: (value) {
                          settingsProvider?.setExtraLargeText(value);
                        },
                      ),
                      const Divider(height: 1, color: AppColors.canvas),
                      InkWell(
                        key: const Key('profile_gemini_key_tile'),
                        onTap: () async {
                          await ShelfVisionService.promptApiKeyIfNeeded(context, forceShow: true);
                          if (mounted) {
                            setState(() {});
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withAlpha(40),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Clau de Gemini (IA)',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    FutureBuilder<String?>(
                                      future: ShelfVisionService.getEffectiveApiKey(),
                                      builder: (context, snapshot) {
                                        final hasKey = snapshot.data != null && snapshot.data!.isNotEmpty;
                                        return Text(
                                          hasKey
                                              ? 'Configurada al dispositiu'
                                              : 'Sense configurar · Toca per afegir-la',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: hasKey ? Colors.green[800] : AppColors.textMuted,
                                            fontWeight: hasKey ? FontWeight.w600 : FontWeight.normal,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.canvas),
                      InkWell(
                        onTap: () => showReleaseNotesModal(context),
                        borderRadius: !kIsWeb
                            ? const BorderRadius.vertical(top: Radius.circular(20))
                            : const BorderRadius.vertical(bottom: Radius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withAlpha(40),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.info_outline_rounded,
                                  color: AppColors.primary,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Versió de l\'aplicació',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMain,
                                      ),
                                    ),
                                    Text(
                                      'Què hi ha de nou? Toca per veure notes',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.canvas,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.accent.withAlpha(80)),
                                ),
                                child: Text(
                                  _versionDisplay,
                                  key: const Key('profile_app_version_text'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (!kIsWeb) ...[
                        const Divider(height: 1, color: AppColors.canvas),
                        InkWell(
                          key: const Key('check_updates_button'),
                          onTap: () => _handleCheckUpdate(context, effectiveUpdateService),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withAlpha(40),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.system_update_alt_rounded,
                                    color: AppColors.primary,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Comprovar actualitzacions',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                      Text(
                                        'Cerca noves versions de Llom per a Android',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 3. Accions de Compte
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Text(
                    'Gestió de Compte',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textMain,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Botó per descarregar APK en entorn Web
                if (kIsWeb) ...[
                  SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      key: const Key('download_apk_web_button'),
                      onPressed: () => effectiveUpdateService.downloadApk('https://llom-23d56.web.app/llom.apk'),
                      icon: const Icon(Icons.android_rounded, size: 24, color: Colors.white),
                      label: const Text(
                        'Descarregar APK per a Android / Tauleta',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Botó per canviar de biblioteca
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: () => showLibrarySelectorSheet(context),
                    icon: const Icon(Icons.swap_horiz_rounded, size: 24, color: AppColors.primary),
                    label: const Text(
                      'Canviar de biblioteca activa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      side: BorderSide(color: AppColors.accent.withAlpha(150), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Botó gran vermellós/suau per tancar sessió
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    key: const Key('profile_sign_out_button'),
                    onPressed: () => _handleSignOut(context),
                    icon: Icon(Icons.logout_rounded, size: 22, color: Colors.red.shade700),
                    label: Text(
                      'Tancar sessió',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade700,
                      elevation: 0,
                      side: BorderSide(color: Colors.red.shade200, width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
