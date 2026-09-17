import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:llom/core/feedback/app_feedback.dart';
import 'package:llom/core/theme/app_colors.dart';
import 'package:llom/models/bookcase_model.dart';
import 'package:llom/models/library_model.dart';
import 'package:llom/providers/library_provider.dart';
import 'package:llom/services/bookcase_service.dart';

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
                AppFeedback.showSuccess(context, 'Biblioteca "$name" creada i activada!');
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
                AppFeedback.showSuccess(
                  context,
                  'T\'has unit a "${provider.activeLibrary?.name ?? 'la biblioteca'}"!',
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
                        AppFeedback.showSuccess(
                          context,
                          'Codi "${library.inviteCode}" copiat al porta-retalls!',
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

/// Diàleg de confirmació per abandonar una biblioteca (per a membres no propietaris)
Future<void> showLeaveLibraryDialog(BuildContext context, LibraryModel library) async {
  bool isLoading = false;
  String? errorMessage;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> leave() async {
            setState(() {
              isLoading = true;
              errorMessage = null;
            });

            final provider = context.read<LibraryProvider>();
            final success = await provider.leaveLibrary(library.id);

            if (context.mounted) {
              if (success) {
                Navigator.of(dialogContext).pop();
                AppFeedback.showSuccess(context, 'Has sortit de "${library.name}".');
              } else {
                setState(() {
                  isLoading = false;
                  errorMessage = provider.errorMessage ?? "No s'ha pogut sortir de la biblioteca.";
                });
              }
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
            title: const Row(
              children: [
                Icon(Icons.exit_to_app_rounded, color: AppColors.primaryDark, size: 28),
                SizedBox(width: 10),
                Text(
                  'Sortir de la biblioteca',
                  style: TextStyle(
                    fontSize: 21,
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
                  Text(
                    'Vols sortir de "${library.name}"?',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Perdràs l'accés a les seves estanteries i llibres catalogats a menys que tornis a introduir el codi d'invitació.",
                    style: TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.3),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      errorMessage!,
                      style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel·lar', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
              ),
              ElevatedButton(
                onPressed: isLoading ? null : leave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : const Text(
                        'Sortir',
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

/// Diàleg crític amb salvaguarda per eliminar una biblioteca (només per al propietari)
/// Requereix escriure exactament el nom de la biblioteca per desbloquejar l'acció
Future<void> showDeleteLibraryDialog(BuildContext context, LibraryModel library) async {
  final confirmController = TextEditingController();
  bool isLoading = false;
  String? errorMessage;
  bool canDelete = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> delete() async {
            setState(() {
              isLoading = true;
              errorMessage = null;
            });

            final provider = context.read<LibraryProvider>();
            final success = await provider.deleteLibrary(library.id);

            if (context.mounted) {
              if (success) {
                Navigator.of(dialogContext).pop();
                AppFeedback.showSuccess(
                  context,
                  'S\'ha eliminat la biblioteca "${library.name}".',
                );
              } else {
                setState(() {
                  isLoading = false;
                  errorMessage = provider.errorMessage ?? "No s'ha pogut eliminar la biblioteca.";
                });
              }
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 10),
                Text(
                  'Eliminar biblioteca',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
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
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withAlpha(80)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Aquesta acció no es pot desfer. S\'eliminaran definitivament la biblioteca, totes les estanteries i tots els llibres catalogats.',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.red.shade900,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Per confirmar l\'eliminació, escriu exactament el nom de la biblioteca:',
                    style: TextStyle(fontSize: 15, color: AppColors.textMain),
                  ),
                  const SizedBox(height: 6),
                  SelectableText(
                    library.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: library.name,
                      prefixIcon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onChanged: (val) {
                      final match = val.trim() == library.name.trim();
                      if (match != canDelete) {
                        setState(() {
                          canDelete = match;
                        });
                      }
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel·lar', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
              ),
              ElevatedButton(
                key: const Key('confirm_delete_library_button'),
                onPressed: (canDelete && !isLoading) ? delete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade200,
                  disabledForegroundColor: Colors.grey.shade500,
                  elevation: canDelete ? 2 : 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : Text(
                        'Eliminar definitivament',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: canDelete ? Colors.white : Colors.grey.shade500,
                        ),
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Bottom modal sheet accessible per afegir una nova estanteria / moble a la biblioteca activa
Future<void> showAddBookcaseDialog(BuildContext context, String libraryId) async {
  final nameController = TextEditingController();
  final roomController = TextEditingController();
  final customWidthController = TextEditingController();
  int shelfCount = 4;
  int selectedWidthCm = 80;
  bool isCustomWidth = false;
  bool isLoading = false;
  String? errorMessage;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;

          Future<void> submit() async {
            final name = nameController.text.trim();
            final room = roomController.text.trim();

            if (name.isEmpty) {
              setState(() {
                errorMessage = "Si us plau, escriu el nom de l'estanteria.";
              });
              return;
            }

            int widthToSave = selectedWidthCm;
            if (isCustomWidth) {
              final customParsed = int.tryParse(customWidthController.text.trim());
              if (customParsed != null && customParsed > 0) {
                widthToSave = customParsed.clamp(20, 300);
              }
            }

            setState(() {
              isLoading = true;
              errorMessage = null;
            });

            try {
              final newBookcase = BookcaseModel(
                id: '',
                name: name,
                room: room.isNotEmpty ? room : 'Menjador',
                shelfCount: shelfCount,
                bookCount: 0,
                widthCm: widthToSave,
                createdAt: DateTime.now(),
              );

              await BookcaseService().addBookcase(libraryId, newBookcase);

              if (context.mounted) {
                Navigator.of(sheetContext).pop();
                AppFeedback.showSuccess(context, 'Estanteria "$name" afegida correctament!');
              }
            } catch (e) {
              if (context.mounted) {
                setState(() {
                  isLoading = false;
                  errorMessage = "Error en crear l'estanteria: ${e.toString()}";
                });
              }
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 20),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nansa superior per arrossegar
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(120),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Capçalera amb icona i títol
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(50),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.shelves, color: AppColors.primary, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nova estanteria',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Defineix les característiques físiques del moble',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Camp Nom del moble
                    const Text(
                      'Nom del moble',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Ex: Estanteria Finestra o Llibreria Gran',
                        prefixIcon: const Icon(Icons.title_rounded, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Camp Habitació / Ubicació
                    const Text(
                      'Habitació / Ubicació',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: roomController,
                      decoration: InputDecoration(
                        hintText: 'Ex: Menjador, Sala d\'Estar, Despatx',
                        prefixIcon: const Icon(Icons.room_rounded, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector de Baldes
                    const Text(
                      'Quantes baldes té?',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.canvas,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.accent.withAlpha(120)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.table_rows_rounded, color: AppColors.primary, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                '$shelfCount baldes',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textMain),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                onPressed: shelfCount > 1
                                    ? () {
                                        setState(() {
                                          shelfCount--;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.primary),
                                tooltip: 'Menys baldes',
                              ),
                              IconButton(
                                onPressed: shelfCount < 10
                                    ? () {
                                        setState(() {
                                          shelfCount++;
                                        });
                                      }
                                    : null,
                                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primary),
                                tooltip: 'Més baldes',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector d'Amplada del moble
                    _BookcaseWidthSelector(
                      selectedWidthCm: selectedWidthCm,
                      isCustomWidth: isCustomWidth,
                      customWidthController: customWidthController,
                      onChanged: (w, isCustom) {
                        setState(() {
                          selectedWidthCm = w;
                          isCustomWidth = isCustom;
                        });
                      },
                    ),

                    if (errorMessage != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Botons d'acció
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : () => Navigator.of(sheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: AppColors.accent.withAlpha(120)),
                            ),
                            child: const Text('Cancel·lar', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                  )
                                : const Text(
                                    'Afegir estanteria',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Mostra el desplegable inferior per gestionar i canviar la biblioteca activa
void showLibrarySelectorSheet(BuildContext context) {
  final libraryProvider = context.read<LibraryProvider>();
  final activeLibrary = libraryProvider.activeLibrary;
  final userLibraries = libraryProvider.userLibraries;
  final canEdit = libraryProvider.canEdit;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    isScrollControlled: true,
    builder: (sheetContext) {
      final librariesToShow = userLibraries.isNotEmpty
          ? userLibraries
          : (activeLibrary != null ? [activeLibrary] : <LibraryModel>[]);

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted.withAlpha(50),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Les teves biblioteques',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain,
                ),
              ),
              const SizedBox(height: 12),

              if (librariesToShow.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'No hi ha cap biblioteca configurada.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                  ),
                )
              else
                ...librariesToShow.map((lib) {
                  final isActive = lib.id == activeLibrary?.id;
                  return InkWell(
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      if (!isActive) {
                        await libraryProvider.switchLibrary(lib);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isActive ? AppColors.accent.withAlpha(40) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? AppColors.accent : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.shelves,
                            color: isActive ? AppColors.primary : AppColors.textMuted,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lib.name,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Codi: ${lib.inviteCode} · ${lib.members.length} membres',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          if (isActive)
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 16),
              const Divider(color: AppColors.accent, height: 1),
              const SizedBox(height: 14),

              // Botó "Compartir codi d'invitació" (visible només per a 'owner' o 'editor')
              if (canEdit && activeLibrary != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(40),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.share_rounded, color: AppColors.primary),
                  ),
                  title: const Text(
                    "Compartir codi d'invitació",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  subtitle: Text(
                    'Codi: ${activeLibrary.inviteCode}',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    showShareLibraryDialog(context);
                  },
                ),
                const SizedBox(height: 10),
              ],

              // Accions ràpides inferiors: "Crear nova biblioteca" i "Unir-se amb un altre codi"
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        showCreateLibraryDialog(context);
                      },
                      icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                      label: const Text(
                        'Crear nova',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.accent.withAlpha(150)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        showJoinLibraryDialog(context);
                      },
                      icon: const Icon(Icons.vpn_key_rounded, size: 18, color: AppColors.primary),
                      label: const Text(
                        'Unir-me amb codi',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textMain),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.accent.withAlpha(150)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Opció vermella: "Eliminar biblioteca" (si és propietari) o "Sortir d'aquesta biblioteca" (si no)
              if (activeLibrary != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      libraryProvider.isOwner
                          ? Icons.delete_forever_rounded
                          : Icons.exit_to_app_rounded,
                      color: Colors.red.shade700,
                    ),
                  ),
                  title: Text(
                    libraryProvider.isOwner
                        ? 'Eliminar biblioteca'
                        : "Sortir d'aquesta biblioteca",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade700,
                    ),
                  ),
                  subtitle: Text(
                    libraryProvider.isOwner
                        ? "S'esborrarà definitivament el moble i llibres"
                        : 'Deixaràs de tenir accés a aquesta biblioteca',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.red.shade400,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.red.shade400,
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    if (libraryProvider.isOwner) {
                      showDeleteLibraryDialog(context, activeLibrary);
                    } else {
                      showLeaveLibraryDialog(context, activeLibrary);
                    }
                  },
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Bottom modal sheet per editar les dades d'un moble d'estanteria
Future<void> showEditBookcaseNameDialog(
  BuildContext context,
  String libraryId,
  BookcaseModel bookcase, {
  BookcaseService? bookcaseService,
}) async {
  final nameController = TextEditingController(text: bookcase.name);
  final roomController = TextEditingController(text: bookcase.room);
  final customWidthController = TextEditingController(
    text: ![40, 60, 80, 100].contains(bookcase.widthCm) ? bookcase.widthCm.toString() : '',
  );
  int selectedWidthCm = bookcase.widthCm;
  bool isCustomWidth = ![40, 60, 80, 100].contains(bookcase.widthCm);
  String? errorMessage;
  bool isLoading = false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final bottomInset = MediaQuery.of(context).viewInsets.bottom;

          Future<void> submit() async {
            final newName = nameController.text.trim();
            final newRoom = roomController.text.trim();
            if (newName.isEmpty) {
              setState(() {
                errorMessage = "El nom de l'estanteria no pot estar buit.";
              });
              return;
            }

            int widthToSave = selectedWidthCm;
            if (isCustomWidth) {
              final customParsed = int.tryParse(customWidthController.text.trim());
              if (customParsed != null && customParsed > 0) {
                widthToSave = customParsed.clamp(20, 300);
              }
            }

            setState(() {
              isLoading = true;
              errorMessage = null;
            });

            try {
              final service = bookcaseService ?? BookcaseService();
              await service.updateBookcase(
                libraryId,
                bookcase.id,
                name: newName,
                room: newRoom.isNotEmpty ? newRoom : bookcase.room,
                widthCm: widthToSave,
              );

              if (context.mounted) {
                Navigator.of(sheetContext).pop();
                AppFeedback.showSuccess(context, 'Dades de l\'estanteria actualitzades correctament!');
              }
            } catch (e) {
              if (context.mounted) {
                setState(() {
                  isLoading = false;
                  errorMessage = "Error en actualitzar: ${e.toString()}";
                });
              }
            }
          }

          return Container(
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(24, 12, 24, bottomInset + 20),
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nansa superior per arrossegar
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withAlpha(120),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Capçalera
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(50),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.edit_rounded, color: AppColors.primary, size: 26),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Editar estanteria',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textMain,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Escriu el nou nom per a aquesta estanteria:',
                                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Camp Nom
                    const Text(
                      'Nom del moble',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      style: const TextStyle(fontSize: 16, color: AppColors.textMain),
                      decoration: InputDecoration(
                        hintText: 'Ex: Estanteria Menjador',
                        prefixIcon: const Icon(Icons.shelves, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Camp Habitació / Ubicació
                    const Text(
                      'Habitació / Ubicació',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: roomController,
                      style: const TextStyle(fontSize: 16, color: AppColors.textMain),
                      decoration: InputDecoration(
                        hintText: 'Ex: Menjador, Sala d\'Estar, Despatx',
                        prefixIcon: const Icon(Icons.room_rounded, color: AppColors.textMuted),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selector d'Amplada del moble
                    _BookcaseWidthSelector(
                      selectedWidthCm: selectedWidthCm,
                      isCustomWidth: isCustomWidth,
                      customWidthController: customWidthController,
                      onChanged: (w, isCustom) {
                        setState(() {
                          selectedWidthCm = w;
                          isCustomWidth = isCustom;
                        });
                      },
                    ),
                    if (errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        errorMessage!,
                        style: TextStyle(fontSize: 14, color: Colors.red.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Botons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading ? null : () => Navigator.of(sheetContext).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: AppColors.accent.withAlpha(120)),
                            ),
                            child: const Text('Cancel·lar', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Desar canvis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Diàleg de confirmació de seguretat per eliminar una estanteria
Future<void> showDeleteBookcaseDialog(
  BuildContext context,
  String libraryId,
  BookcaseModel bookcase, {
  BookcaseService? bookcaseService,
}) async {
  bool isLoading = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          Future<void> confirmDelete() async {
            setState(() {
              isLoading = true;
            });

            try {
              final service = bookcaseService ?? BookcaseService();
              await service.deleteBookcase(libraryId, bookcase.id);

              if (context.mounted) {
                Navigator.of(dialogContext).pop();
                AppFeedback.showSuccess(context, 'Estanteria "${bookcase.name}" eliminada.');
              }
            } catch (e) {
              if (context.mounted) {
                setState(() {
                  isLoading = false;
                });
                AppFeedback.showError(context, 'Error en eliminar: ${e.toString()}');
              }
            }
          }

          return AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
                const SizedBox(width: 10),
                const Text(
                  'Eliminar estanteria',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                'Segur que vols eliminar definitivament "${bookcase.name}"? '
                'Tots els llibres catalogats en aquesta estanteria també s\'esborraran.',
                style: const TextStyle(fontSize: 15, color: AppColors.textMuted, height: 1.4),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel·lar', style: TextStyle(color: AppColors.textMuted, fontSize: 16)),
              ),
              ElevatedButton(
                key: const Key('confirm_delete_bookcase_button'),
                onPressed: isLoading ? null : confirmDelete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Eliminar definitivament', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Selector visual d'amplada física del moble amb opcions ràpides i mida lliure
class _BookcaseWidthSelector extends StatelessWidget {
  final int selectedWidthCm;
  final bool isCustomWidth;
  final TextEditingController customWidthController;
  final void Function(int widthCm, bool isCustom) onChanged;

  const _BookcaseWidthSelector({
    required this.selectedWidthCm,
    required this.isCustomWidth,
    required this.customWidthController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const presets = [
      (40, '40 cm · Estreta'),
      (60, '60 cm · Mitjana'),
      (80, '80 cm · Ampla'),
      (100, '100 cm · Gran'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amplada del moble',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textMain),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...presets.map((p) {
              final isSelected = !isCustomWidth && selectedWidthCm == p.$1;
              return ChoiceChip(
                key: Key('width_chip_${p.$1}'),
                label: Text(p.$2),
                selected: isSelected,
                onSelected: (sel) {
                  if (sel) onChanged(p.$1, false);
                },
                selectedColor: AppColors.primary.withAlpha(40),
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textMain,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }),
            ChoiceChip(
              key: const Key('width_chip_custom'),
              label: const Text('Personalitzada...'),
              selected: isCustomWidth,
              onSelected: (sel) {
                if (sel) onChanged(selectedWidthCm, true);
              },
              selectedColor: AppColors.primary.withAlpha(40),
              labelStyle: TextStyle(
                color: isCustomWidth ? AppColors.primary : AppColors.textMain,
                fontWeight: isCustomWidth ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        if (isCustomWidth) ...[
          const SizedBox(height: 10),
          TextField(
            key: const Key('custom_width_field'),
            controller: customWidthController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: 'Ex: 75',
              suffixText: 'cm',
              prefixIcon: const Icon(Icons.straighten_rounded, color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ],
    );
  }
}
