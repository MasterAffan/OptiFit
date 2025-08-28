import 'package:flutter/material.dart';
import '../theme/theme.dart';

/// Reusable button widget following the design system
class AppButton extends StatelessWidget {
  final String? text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    this.text,
    this.icon,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.width,
    this.height,
  }) : assert(text != null || icon != null, 'Either text or icon must be provided');

  @override
  Widget build(BuildContext context) {
    final buttonWidget = _buildButtonWidget(context);
    
    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height ?? 48.0,
        child: buttonWidget,
      );
    }
    
    if (width != null || height != null) {
      return SizedBox(
        width: width,
        height: height ?? 48.0,
        child: buttonWidget,
      );
    }
    
    return buttonWidget;
  }

  Widget _buildButtonWidget(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: AppTheme.buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusM,
            ),
            elevation: 0,
          ),
          child: _buildButtonContent(),
        );
        
      case AppButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primary,
            side: const BorderSide(color: AppTheme.borderColor),
            padding: AppTheme.buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusM,
            ),
          ),
          child: _buildButtonContent(),
        );
        
      case AppButtonVariant.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppTheme.primary,
            padding: AppTheme.buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: AppTheme.borderRadiusM,
            ),
          ),
          child: _buildButtonContent(),
        );
        
      case AppButtonVariant.icon:
        return Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: AppTheme.borderRadiusXXL,
            boxShadow: AppTheme.baseShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isLoading ? null : onPressed,
              borderRadius: AppTheme.borderRadiusXXL,
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      )
                    : Icon(
                        icon,
                        size: 20,
                        color: AppTheme.primary,
                      ),
              ),
            ),
          ),
        );
    }
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            variant == AppButtonVariant.primary ? Colors.white : AppTheme.primary,
          ),
        ),
      );
    }

    if (text != null && icon != null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: AppTheme.spacingS),
            Flexible(
              child: Text(
                text!,
                style: const TextStyle(
                  fontSize: AppTheme.fontSizeBody,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                softWrap: false,
              ),
            ),
          ],
        ),
      );
    }

    if (icon != null) {
      return Icon(icon, size: 20);
    }

    return Text(
      text!,
      style: const TextStyle(
        fontSize: AppTheme.fontSizeBody,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

/// Button variants based on design.json
enum AppButtonVariant {
  primary,
  secondary,
  text,
  icon,
}

/// Extension for easy button creation
extension AppButtonExtension on AppButton {
  /// Create a primary button
  static AppButton primary({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? icon,
  }) {
    return AppButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: AppButtonVariant.primary,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// Create a secondary button
  static AppButton secondary({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? icon,
  }) {
    return AppButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: AppButtonVariant.secondary,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// Create a text button
  static AppButton text({
    required String text,
    VoidCallback? onPressed,
    bool isLoading = false,
    bool isFullWidth = false,
    IconData? icon,
  }) {
    return AppButton(
      text: text,
      icon: icon,
      onPressed: onPressed,
      variant: AppButtonVariant.text,
      isLoading: isLoading,
      isFullWidth: isFullWidth,
    );
  }

  /// Create an icon button
  static AppButton icon({
    required IconData icon,
    VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return AppButton(
      icon: icon,
      onPressed: onPressed,
      variant: AppButtonVariant.icon,
      isLoading: isLoading,
    );
  }
} 