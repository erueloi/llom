import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:llom/core/theme/app_colors.dart';
import 'package:llom/providers/library_provider.dart';

/// Mostra el diàleg per crear una nova biblioteca
Future<void> showCreateLibraryDialog(BuildContext context) async {
  final nameController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              setState(() {
                errorMessage = 'Si us plau, escriu el nom de la biblioteca.';
              });
              return;
            }

            setState(() {
              isLoading = true;
              errorMessage = null;
            });

            final provider = context.read<LibraryProvider>();
            final success = await provider.createAndSelectLibrary(name);

            if (context.mounted) {
              if (success) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Biblioteca "$name" creada i activada!',
                      style: const TextStyle(fontSize: 16),
                    ),
                    backgroundColor: AppColors.primaryDark,
                  ),
                );
              } else {
                setState(() {
                  isLoading = false;
                  errorMessage = provider.errorMessage ?? "No s'ha pogut crear la biblioteca.";
                });
              }
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
            title: const Row(
              children: [
                Icon(Icons.add_home_work_rounded, color: AppColors.primary, size: 28),
                SizedBox(width: 10),
                Text(
                  'Crear biblioteca',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Escriu un nom descriptiu per a la teva col·lecció (ex: Biblioteca Cal Jeroni o Sala d\'Estar).',
                    style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.3),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(fontSize: 18, color: AppColors.textMain),
                    decoration: InputDecoration(
                      hintText: 'Ex: Biblioteca Cal Jeroni',
                      prefixIcon: const Icon(Icons.bookmark_outline_rounded, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.accent.withAlpha(150)),
                      ),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'Cancel·lar',
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Crear',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Mostra el diàleg per unir-se a una biblioteca mitjançant codi
Future<void> showJoinLibraryDialog(BuildContext context) async {
  final codeController = TextEditingController();
  String? errorMessage;
  bool isLoading = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> submit() async {
            final code = codeController.text.trim().toUpperCase();
            if (code.isEmpty) {
              setState(() {
                errorMessage = "Si us plau, escriu el codi d'invitació.";
              });
              return;
            }

            setState(() {
              isLoading = true;
              errorMessage = null;
            });

            final provider = context.read<LibraryProvider>();
            final success = await provider.joinAndSelectLibrary(code);

            if (context.mounted) {
              if (success) {
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'T\'has unit a "${provider.activeLibrary?.name ?? 'la biblioteca'}"!',
                      style: const TextStyle(fontSize: 16),
                    ),
                    backgroundColor: AppColors.primaryDark,
                  ),
                );
              } else {
                setState(() {
                  isLoading = false;
                  errorMessage = provider.errorMessage ?? "Codi no vàlid o error en unir-se.";
                });
              }
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
            title: const Row(
              children: [
                Icon(Icons.vpn_key_rounded, color: AppColors.primary, size: 28),
                SizedBox(width: 10),
                Text(
                  'Unir-se amb codi',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Introdueix el codi de 6 caràcters que t\'ha facilitat el propietari de la biblioteca.',
                    style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.3),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: codeController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.characters,
                    maxLength: 6,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: AppColors.textMain,
                    ),
                    decoration: InputDecoration(
                      hintText: 'LLOM84',
                      counterText: '',
                      prefixIcon: const Icon(Icons.password_rounded, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: AppColors.accent.withAlpha(150)),
                      ),
                    ),
                    onSubmitted: (_) => submit(),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.primary.withAlpha(100)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.primaryDark, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'Cancel·lar',
                  style: TextStyle(fontSize: 16, color: AppColors.textMuted),
                ),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Unir-me',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Mostra el diàleg per compartir el codi d'invitació i veure els membres
Future<void> showShareLibraryDialog(BuildContext context) async {
  final provider = context.read<LibraryProvider>();
  final library = provider.activeLibrary;
  if (library == null) return;

  final isOwner = provider.isOwner;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
        title: Row(
          children: [
            const Icon(Icons.share_rounded, color: AppColors.primary, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Compartir ${library.name}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Fes servir aquest codi per convidar altres lectors o familiars a la biblioteca:',
                style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.3),
              ),
              const SizedBox(height: 16),

              // Targeta gran amb el codi monoespaiat de 32sp
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(50),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.accent.withAlpha(160),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      library.inviteCode,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: AppColors.textMain,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: library.inviteCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Codi "${library.inviteCode}" copiat al porta-retalls!',
                              style: const TextStyle(fontSize: 16),
                            ),
                            backgroundColor: AppColors.primaryDark,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text(
                        'Copiar codi',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),

              // Si és owner, llista els membres
              if (isOwner) ...[
                const SizedBox(height: 20),
                Text(
                  'Membres (${library.members.length}):',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: library.members.entries.map((entry) {
                    final uid = entry.key;
                    final role = entry.value;
                    final isCurrent = uid == provider.currentUser?.uid;

                    String roleLabel;
                    Color roleColor;
                    switch (role) {
                      case 'owner':
                        roleLabel = 'Propietari';
                        roleColor = AppColors.primary;
                        break;
                      case 'editor':
                        roleLabel = 'Editor';
                        roleColor = AppColors.primaryDark;
                        break;
                      default:
                        roleLabel = 'Lector';
                        roleColor = AppColors.textMuted;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isCurrent ? 'Tu ($roleLabel)' : '${uid.substring(0, uid.length > 8 ? 8 : uid.length)}... ($roleLabel)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: AppColors.textMain,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: roleColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: roleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Tancar',
              style: TextStyle(fontSize: 16, color: AppColors.textMain, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      );
    },
  );
}
