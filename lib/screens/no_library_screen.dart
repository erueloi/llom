import 'package:flutter/material.dart';
import 'package:llom/core/theme/app_colors.dart';
import 'package:llom/services/auth_service.dart';
import 'package:llom/widgets/library_dialogs.dart';

class NoLibraryScreen extends StatelessWidget {
  final AuthService? authService;

  const NoLibraryScreen({super.key, this.authService});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrWeb = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              final auth = authService ?? AuthService();
              await auth.signOut();
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
            label: const Text(
              'Tancar sessió',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTabletOrWeb ? 32 : 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textMain.withAlpha(20),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: EdgeInsets.all(isTabletOrWeb ? 40 : 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icona gran de biblioteca
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(50),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withAlpha(80),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.local_library_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Títol gran
                    const Text(
                      'Encara no tens cap biblioteca',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Subtítol explicatiu
                    const Text(
                      'Pots crear la teva pròpia biblioteca o unir-te a una existent amb un codi d\'invitació.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textMuted,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 36),

                    // Botó gran 1: Crear una biblioteca nova
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => showCreateLibraryDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 24),
                        label: const Text(
                          'Crear una biblioteca nova',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botó gran 2: Unir-me amb codi d'invitació
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: () => showJoinLibraryDialog(context),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textMain,
                          side: BorderSide(
                            color: AppColors.accent.withAlpha(160),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.vpn_key_rounded, size: 22, color: AppColors.primary),
                        label: const Text(
                          'Unir-me amb codi d\'invitació',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textMain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
