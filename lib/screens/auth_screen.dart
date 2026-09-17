import 'package:flutter/material.dart';
import 'package:llom/core/theme/app_colors.dart';
import 'package:llom/services/auth_service.dart';
import 'package:llom/widgets/google_logo_widget.dart';

class AuthScreen extends StatefulWidget {
  final AuthService? authService;

  const AuthScreen({super.key, this.authService});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AuthService _authService;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(bool isRegister) {
    if (_isRegisterMode == isRegister) return;
    setState(() {
      _isRegisterMode = isRegister;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  Future<void> _submit() async {
    if (_isLoading || _isGoogleLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    try {
      if (_isRegisterMode) {
        await _authService.registerWithEmail(
          email: email,
          password: password,
          name: name,
        );
      } else {
        await _authService.signInWithEmail(
          email: email,
          password: password,
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "S'ha produït un error inesperat: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || _isGoogleLoading) return;

    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
    } on AuthException catch (e) {
      if (mounted) {
        // No mostrem error si l'usuari simplement ha cancel·lat o tancat la finestra emergent
        if (e.code != 'cancelled') {
          setState(() {
            _errorMessage = e.message;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('database is closing') || errStr.contains('closing/hidden')) {
          setState(() {
            _errorMessage = "La connexió d'emmagatzematge del navegador s'ha tancat temporalment. Si us plau, torna a prémer el botó per accedir.";
          });
        } else {
          setState(() {
            _errorMessage = "S'ha produït un error inesperat: ${e.toString()}";
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGoogleLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrWeb = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isTabletOrWeb ? 32 : 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
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
                padding: EdgeInsets.all(isTabletOrWeb ? 36 : 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Monograma / Icona superior
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(60),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withAlpha(80),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            size: 38,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Títol i subtítol
                      const Text(
                        'Benvingut a Llom',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'El catàleg visual dels teus llibres a casa',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textMuted,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // Selector gran Entrar / Crear compte
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.canvas,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.accent.withAlpha(100),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildTabButton(
                                label: 'Entrar',
                                isSelected: !_isRegisterMode,
                                onTap: () => _switchMode(false),
                              ),
                            ),
                            Expanded(
                              child: _buildTabButton(
                                label: 'Crear compte',
                                isSelected: _isRegisterMode,
                                onTap: () => _switchMode(true),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Camp 'Nom' (només registre)
                      if (_isRegisterMode) ...[
                        _buildLabel('El teu nom'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(fontSize: 18, color: AppColors.textMain),
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: 'Ex: Jeroni Mas',
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textMuted),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            fillColor: AppColors.surface,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: AppColors.accent.withAlpha(150)),
                            ),
                          ),
                          validator: (value) {
                            if (_isRegisterMode && (value == null || value.trim().isEmpty)) {
                              return 'Si us plau, escriu el teu nom';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                      ],

                      // Camp 'Correu electrònic'
                      _buildLabel('Correu electrònic'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(fontSize: 18, color: AppColors.textMain),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          hintText: 'nom@exemple.cat',
                          prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.textMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          fillColor: AppColors.surface,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.accent.withAlpha(150)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Si us plau, escriu el correu electrònic';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Escriu un correu electrònic vàlid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),

                      // Camp 'Contrasenya'
                      _buildLabel('Contrasenya'),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _passwordController,
                        style: const TextStyle(fontSize: 18, color: AppColors.textMain),
                        obscureText: !_isPasswordVisible,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          hintText: 'Mínim 6 caràcters',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: AppColors.textMuted,
                              size: 24,
                            ),
                            tooltip: _isPasswordVisible ? 'Amagar contrasenya' : 'Mostrar contrasenya',
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          fillColor: AppColors.surface,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.accent.withAlpha(150)),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Si us plau, escriu la contrasenya';
                          }
                          if (value.length < 6) {
                            return 'La contrasenya ha de tenir com a mínim 6 caràcters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Missatge d'error destacat si s'ha produït
                      if (_errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppColors.primary.withAlpha(120),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: AppColors.primaryDark,
                                size: 22,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Botó d'acció principal gran accessible
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (_isLoading || _isGoogleLoading) ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            disabledBackgroundColor: AppColors.primary.withAlpha(120),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _isRegisterMode
                                      ? 'Registrar-me'
                                      : 'Entrar a la meva biblioteca',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Separador subtil amb línies horitzontals i "o bé"
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: AppColors.accent.withAlpha(120),
                              thickness: 1,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'o bé',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: AppColors.accent.withAlpha(120),
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Botó gran accessible per a Google
                      SizedBox(
                        height: 56,
                        child: OutlinedButton(
                          onPressed: (_isLoading || _isGoogleLoading)
                              ? null
                              : _handleGoogleSignIn,
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            side: const BorderSide(
                              color: AppColors.accent,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isGoogleLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primary,
                                    ),
                                  ),
                                )
                              : const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GoogleLogoWidget(size: 22),
                                      SizedBox(width: 12),
                                      Text(
                                        'Continua amb Google',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textMain,
                                        ),
                                      ),
                                    ],
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
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.textMain.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 17,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
