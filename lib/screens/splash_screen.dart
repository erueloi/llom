import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:llom/core/theme/app_colors.dart';
import 'package:llom/screens/auth_gate.dart';

/// Pantalla d'inici (SplashScreen) amb identitat de marca, càrrega prèvia
/// i transició suau cap a AuthGate.
class SplashScreen extends StatefulWidget {
  final Duration initialDelay;
  final Widget? destination;
  final bool autoNavigate;

  const SplashScreen({
    super.key,
    this.initialDelay = const Duration(milliseconds: 1700),
    this.destination,
    this.autoNavigate = true,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _versionText = 'v1.0.0 (1)';

  @override
  void initState() {
    super.initState();
    _startPreloadAndNavigate();
  }

  Future<void> _startPreloadAndNavigate() async {
    final futures = <Future<void>>[
      _loadVersionInfo(),
      _preloadPreferences(),
    ];
    if (widget.initialDelay > Duration.zero) {
      futures.add(Future.delayed(widget.initialDelay));
    }
    await Future.wait(futures);

    if (!mounted || !widget.autoNavigate) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            widget.destination ?? const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _loadVersionInfo() async {
    try {
      final info = await PackageInfo.fromPlatform().timeout(
        const Duration(milliseconds: 600),
      );
      if (mounted) {
        setState(() {
          final buildSuffix =
              info.buildNumber.isNotEmpty ? ' (${info.buildNumber})' : '';
          _versionText = 'v${info.version}$buildSuffix';
        });
      }
    } catch (_) {
      // Valor per defecte si la plataforma no respon (ex: tests o temps d'espera esgotat)
    }
  }

  Future<void> _preloadPreferences() async {
    try {
      await SharedPreferences.getInstance().timeout(
        const Duration(milliseconds: 600),
      );
    } catch (_) {
      // Ignorar si falla la càrrega en entorn de test o temps d'espera esgotat
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Stack(
          children: [
            // Contingut vertical centrat
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo de marca
                    Image.asset(
                      'assets/images/logo.png',
                      width: 170,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_library_rounded,
                          size: 110,
                          color: AppColors.primary,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    // Títol de l'aplicació
                    const Text(
                      'Llom',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Lema editorial
                    const Text(
                      'Per no perdre cap llibre.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Indicador de càrrega discret amb opacitat
                    SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary.withAlpha(200),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Versió dinàmica a la part inferior
            Positioned(
              left: 0,
              right: 0,
              bottom: 16,
              child: Text(
                _versionText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
