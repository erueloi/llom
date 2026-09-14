import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:llom/core/theme/app_colors.dart';
import 'package:llom/models/user_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/screens/auth_screen.dart';
import 'package:llom/screens/home_screen.dart';
import 'package:llom/screens/no_library_screen.dart';
import 'package:llom/services/auth_service.dart';

class AuthGate extends StatefulWidget {
  final AuthService? authService;

  const AuthGate({super.key, this.authService});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final AuthService _authService;
  String? _initializedUid;
  bool _isInitializingUser = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  Future<void> _initLibraryProvider(User user) async {
    if (_initializedUid == user.uid || _isInitializingUser) return;

    setState(() {
      _isInitializingUser = true;
    });

    try {
      final userModel = await _authService.getCurrentUserData() ??
          UserModel(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName,
            activeLibraryId: null,
            createdAt: DateTime.now(),
          );

      if (mounted) {
        final libraryProvider = context.read<LibraryProvider>();
        await libraryProvider.initialize(userModel);
      }
    } catch (e) {
      debugPrint("Error inicialitzant dades d'usuari a AuthGate: $e");
    } finally {
      if (mounted) {
        setState(() {
          _initializedUid = user.uid;
          _isInitializingUser = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // Estat de càrrega inicial del stream
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingScaffold('Connectant amb Llom...');
        }

        final user = snapshot.data;

        // Sense sessió d'usuari -> Mostrar pantalla d'autenticació
        if (user == null) {
          _initializedUid = null;
          _isInitializingUser = false;
          return AuthScreen(authService: _authService);
        }

        // Sessió activa: Inicialitzem LibraryProvider si encara no s'ha fet per a aquest usuari
        if (_initializedUid != user.uid) {
          if (!_isInitializingUser) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initLibraryProvider(user);
            });
          }
          return _buildLoadingScaffold('Carregant les teves biblioteques...');
        }

        final libraryProvider = context.watch<LibraryProvider>();

        // Mentre es recupera l'usuari i es carreguen les biblioteques
        if (_isInitializingUser || libraryProvider.isLoading) {
          return _buildLoadingScaffold('Carregant les teves biblioteques...');
        }

        // Si l'usuari té biblioteca activa -> HomeScreen
        if (libraryProvider.hasActiveLibrary) {
          return const HomeScreen();
        }

        // Si no en té cap activa -> NoLibraryScreen
        return NoLibraryScreen(authService: _authService);
      },
    );
  }

  Widget _buildLoadingScaffold(String message) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textMain.withAlpha(20),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
