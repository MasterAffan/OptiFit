import 'package:flutter/material.dart';
import '../theme/theme.dart';

class CustomSnackBar extends StatelessWidget {
  final String message;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Duration duration;
  final SnackBarType type;

  const CustomSnackBar({
    super.key,
    required this.message,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.duration = const Duration(seconds: 2),
    this.type = SnackBarType.info,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg = backgroundColor ?? _getBgColor(type);
    final Color fg = textColor ?? _getTextColor(type);
    final IconData? ic = icon ?? _getIcon(type);
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(top: 24, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ic != null) ...[
              Icon(ic, color: fg, size: 22),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getBgColor(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return AppTheme.success;
      case SnackBarType.error:
        return AppTheme.error;
      case SnackBarType.warning:
        return AppTheme.warning;
      case SnackBarType.info:
      default:
        return AppTheme.primary;
    }
  }

  Color _getTextColor(SnackBarType type) {
    return Colors.white;
  }

  IconData? _getIcon(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle_outline;
      case SnackBarType.error:
        return Icons.error_outline;
      case SnackBarType.warning:
        return Icons.warning_amber_rounded;
      case SnackBarType.info:
      default:
        return Icons.info_outline;
    }
  }
}

enum SnackBarType { success, error, warning, info }

void showCustomSnackBar(
  BuildContext context, {
  required String message,
  IconData? icon,
  Color? backgroundColor,
  Color? textColor,
  Duration duration = const Duration(seconds: 2),
  SnackBarType type = SnackBarType.info,
}) {
  final overlay = Overlay.of(context);
  final entry = OverlayEntry(
    builder: (context) => SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: CustomSnackBar(
          message: message,
          icon: icon,
          backgroundColor: backgroundColor,
          textColor: textColor,
          duration: duration,
          type: type,
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Future.delayed(duration, entry.remove);
} 