import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Puissance de l'équipe affichée comme un tableau d'affichage de stade.
/// C'est LE détail mémorable de l'interface : le chiffre est la première chose lue.
class PowerNumeral extends StatelessWidget {
  const PowerNumeral({
    super.key,
    required this.value,
    this.size = 44,
    this.showLabel = true,
  });

  final int value;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel) Text('PUISSANCE', style: theme.textTheme.labelSmall),
        Text(
          '$value',
          style: theme.textTheme.displaySmall?.copyWith(
            fontSize: size,
            color: theme.colorScheme.primary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Lignes de terrain très discrètes, à placer derrière un en-tête.
class PitchBackdrop extends StatelessWidget {
  const PitchBackdrop({super.key, required this.child, this.opacity = 0.5});

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final lineColor = context.tokens.line;

    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity,
              child: CustomPaint(painter: _PitchPainter(lineColor)),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _PitchPainter extends CustomPainter {
  _PitchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;

    // Ligne médiane et rond central
    canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), paint);
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.18, paint);

    // Surfaces de réparation haut et bas
    final boxW = w * 0.5;
    final boxH = h * 0.14;
    canvas.drawRect(Rect.fromLTWH((w - boxW) / 2, 0, boxW, boxH), paint);
    canvas.drawRect(Rect.fromLTWH((w - boxW) / 2, h - boxH, boxW, boxH), paint);

    // Bordure du terrain
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h).deflate(0.75), paint);
  }

  @override
  bool shouldRepaint(_PitchPainter oldDelegate) => oldDelegate.color != color;
}

enum StatusTone { success, info, warning, danger, neutral }

/// Pastille de statut (commandes, vendeurs, annonces). Contour + texte, sans remplissage.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.tone});

  final String label;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final color = switch (tone) {
      StatusTone.success => tokens.success,
      StatusTone.info => tokens.info,
      StatusTone.warning => tokens.warning,
      StatusTone.danger => tokens.danger,
      StatusTone.neutral => tokens.textDim,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}
