import 'package:flutter/material.dart';

import '../values/app_colors.dart';

enum CustomButtonVariant { primary, outlined, danger, ghost }

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = CustomButtonVariant.primary,
    this.isLoading = false,
    this.expanded = false,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CustomButtonVariant variant;
  final bool isLoading;
  final bool expanded;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDisabled = onPressed == null || isLoading;
    final foreground = _foregroundColor(theme);

    final child = _ButtonContent(
      label: label,
      icon: icon,
      isLoading: isLoading,
      color: isLoading ? foreground : null,
    );

    final Widget button = switch (variant) {
      CustomButtonVariant.primary => FilledButton(
        onPressed: isDisabled ? null : onPressed,
        child: child,
      ),
      CustomButtonVariant.danger => FilledButton(
        onPressed: isDisabled ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.danger.withValues(alpha: 0.45),
        ),
        child: child,
      ),
      CustomButtonVariant.outlined => OutlinedButton(
        onPressed: isDisabled ? null : onPressed,
        child: child,
      ),
      CustomButtonVariant.ghost => TextButton(
        onPressed: isDisabled ? null : onPressed,
        style: TextButton.styleFrom(
          minimumSize: Size(0, height),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: child,
      ),
    };

    return SizedBox(
      width: expanded ? double.infinity : null,
      height: height,
      child: button,
    );
  }

  Color _foregroundColor(ThemeData theme) {
    return switch (variant) {
      CustomButtonVariant.primary => theme.colorScheme.onPrimary,
      CustomButtonVariant.danger => Colors.white,
      CustomButtonVariant.outlined ||
      CustomButtonVariant.ghost => theme.colorScheme.primary,
    };
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.color,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (isLoading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: color ?? Theme.of(context).colorScheme.onPrimary,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 19),
        if (isLoading || icon != null) const SizedBox(width: 9),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
