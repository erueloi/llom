import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:llom/core/theme/app_colors.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/services/auth_service.dart';

class SetupLibraryScreen extends StatefulWidget {
  const SetupLibraryScreen({super.key});

  @override
  State<SetupLibraryScreen> createState() => _SetupLibraryScreenState();
}

class _SetupLibraryScreenState extends State<SetupLibraryScreen> {
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();

  bool _isJoinMode = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _createLibrary() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() {
        _errorMessage = 'Si us plau, escriu un nom per a la teva biblioteca.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = context.read<LibraryProvider>();
    final success = await provider.createAndSelectLibrary(name);

    if (mounted && !success) {
      setState(() {
        _isLoading = false;
        _errorMessage = provider.errorMessage ?? "No s'ha pogut crear la biblioteca.";
      });
    }
  }

  Future<void> _joinLibrary() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _errorMessage = "Si us plau, escriu el codi d'invitació de 6 caràcters.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final provider = context.read<LibraryProvider>();
    final success = await provider.joinAndSelectLibrary(code);

    if (mounted && !success) {
      setState(() {
        _isLoading = false;
        _errorMessage = provider.errorMessage ?? "No s'ha pogut unir a la biblioteca.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTabletOrWeb = screenWidth > 600;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await AuthService().signOut();
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
              constraints: const BoxConstraints(maxWidth: 480),
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icona destacada
                    Center(
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(60),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.primary.withAlpha(80),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.shelves,
                          size: 40,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Comencem amb els teus llibres',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMain,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Crea una biblioteca nova per a casa teva o uneix-te a una existent mitjançant un codi.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),

                    // Selector de mode
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
                              label: 'Crear nova',
                              isSelected: !_isJoinMode,
                              onTap: () {
                                setState(() {
                                  _isJoinMode = false;
                                  _errorMessage = null;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: _buildTabButton(
                              label: 'Unir-me amb codi',
                              isSelected: _isJoinMode,
                              onTap: () {
                                setState(() {
                                  _isJoinMode = true;
                                  _errorMessage = null;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (!_isJoinMode) ...[
                      // Mode Crear
                      const Text(
                        'Nom de la biblioteca',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 18, color: AppColors.textMain),
                        decoration: InputDecoration(
                          hintText: 'Ex: Biblioteca Cal Jeroni',
                          prefixIcon: const Icon(Icons.bookmark_border_rounded, color: AppColors.textMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          fillColor: AppColors.surface,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.accent.withAlpha(150)),
                          ),
                        ),
                        onSubmitted: (_) => _createLibrary(),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Mode Unir-se
                      const Text(
                        "Codi d'invitació (6 caràcters)",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _codeController,
                        style: const TextStyle(
                          fontSize: 22,
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textMain,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: 'Ex: LLOM84',
                          prefixIcon: const Icon(Icons.vpn_key_outlined, color: AppColors.textMuted),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          fillColor: AppColors.surface,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.accent.withAlpha(150)),
                          ),
                        ),
                        onSubmitted: (_) => _joinLibrary(),
                      ),
                      const SizedBox(height: 20),
                    ],

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

                    // Botó gran d'acció
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : (_isJoinMode ? _joinLibrary : _createLibrary),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
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
                                !_isJoinMode ? 'Crear la biblioteca' : "Unir-me a la biblioteca",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
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
