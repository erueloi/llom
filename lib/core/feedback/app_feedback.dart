import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum FeedbackType {
  success,
  error,
  warning,
  info,
}

class AppFeedback {
  AppFeedback._();

  static OverlayEntry? _currentEntry;

  /// Mostra una notificació d'èxit amb icona verda menta
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 3500),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: FeedbackType.success,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Mostra una notificació d'error amb icona carmesí
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 5000),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: FeedbackType.error,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Mostra una notificació d'avís amb icona ambre càlid
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 4000),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: FeedbackType.warning,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Mostra una notificació informativa amb icona salmó corporatiu
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(milliseconds: 4000),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    show(
      context,
      message: message,
      type: FeedbackType.info,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Mostra una notificació personalitzada amb píndola flotant superior (Top Pill Toast)
  static void show(
    BuildContext context, {
    required String message,
    FeedbackType type = FeedbackType.info,
    Duration duration = const Duration(milliseconds: 3500),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    dismiss();

    final overlay = Overlay.maybeOf(context, rootOverlay: true) ??
        Navigator.maybeOf(context, rootNavigator: true)?.overlay;

    if (overlay == null) {
      // Fallback resilient per a entorns de test o sense Overlay actiu
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          behavior: SnackBarBehavior.floating,
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(label: actionLabel, onPressed: onAction)
              : null,
        ),
      );
      return;
    }

    final entry = OverlayEntry(
      builder: (ctx) => _TopPillToastWidget(
        message: message,
        type: type,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: dismiss,
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Tanca la notificació actual immediatament si està visible
  static void dismiss() {
    if (_currentEntry != null) {
      try {
        _currentEntry?.remove();
      } catch (_) {}
      _currentEntry = null;
    }
  }
}

class _TopPillToastWidget extends StatefulWidget {
  final String message;
  final FeedbackType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _TopPillToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_TopPillToastWidget> createState() => _TopPillToastWidgetState();
}

class _TopPillToastWidgetState extends State<_TopPillToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();

    _dismissTimer = Timer(widget.duration, () {
      _handleDismiss();
    });
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismiss();
  }

  IconData _getIcon() {
    switch (widget.type) {
      case FeedbackType.success:
        return Icons.check_circle_rounded;
      case FeedbackType.error:
        return Icons.error_rounded;
      case FeedbackType.warning:
        return Icons.warning_amber_rounded;
      case FeedbackType.info:
        return Icons.info_rounded;
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case FeedbackType.success:
        return const Color(0xFF4EBA6F); // Verd menta càlid
      case FeedbackType.error:
        return const Color(0xFFE55353); // Vermell carmesí
      case FeedbackType.warning:
        return const Color(0xFFE5A038); // Ambre càlid
      case FeedbackType.info:
        return AppColors.primary; // Terracota / Salmó corporatiu
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPadding + 14,
      left: 16,
      right: 16,
      child: Align(
        alignment: Alignment.topCenter,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _handleDismiss,
                onVerticalDragEnd: (details) {
                  if (details.primaryVelocity != null && details.primaryVelocity! < 0) {
                    _handleDismiss();
                  }
                },
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF221F1E), // Carbó fosc editorial d'alt contrast
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withAlpha(28), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(55),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_getIcon(), color: _getIconColor(), size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.actionLabel != null && widget.onAction != null) ...[
                        const SizedBox(width: 10),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: AppColors.accent,
                          ),
                          onPressed: () {
                            _handleDismiss();
                            widget.onAction!();
                          },
                          child: Text(
                            widget.actionLabel!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: Color(0xFFF8B4A6),
                            ),
                          ),
                        ),
                      ],
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
}
