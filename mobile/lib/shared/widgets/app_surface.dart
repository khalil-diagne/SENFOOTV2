import 'package:efoot_market/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Bloc unique : une surface, une bordure, des coins arrondis.
/// À utiliser au niveau supérieur des écrans, jamais imbriqué dans un autre.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.highlight = false,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool highlight;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;

    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: highlight ? tokens.surfaceHigh : scheme.surface,
        border: Border.all(color: borderColor ?? tokens.line),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: child,
    );

    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: box,
      ),
    );
  }
}