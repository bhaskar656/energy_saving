import 'package:energy_saving/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Rounded, softly shadowed surface used for nearly every card in the app.
class EcoCard extends StatelessWidget {
  const EcoCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.gradient,
    this.borderColor,
    this.radius = AppPalette.cardRadius,
    this.onTap,
    this.shadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final borderRadius = BorderRadius.circular(radius);
    final decoration = BoxDecoration(
      color: gradient == null ? (color ?? theme.colorScheme.surface) : null,
      gradient: gradient,
      borderRadius: borderRadius,
      border: Border.all(
        color:
            borderColor ??
            (theme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.06)
                : AppPalette.mintBorder),
      ),
      boxShadow: shadow ?? AppPalette.softShadow,
    );
    final content = Padding(padding: padding, child: child);

    if (onTap == null) {
      return Container(decoration: decoration, child: content);
    }
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: decoration,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: content,
        ),
      ),
    );
  }
}

/// Gradient rounded square that holds an icon — the app's signature accent.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    this.accent,
    this.size = 44,
    this.iconSize = 22,
    this.useGradient = true,
  });

  final IconData icon;
  final Color? accent;
  final double size;
  final double iconSize;
  final bool useGradient;

  @override
  Widget build(BuildContext context) {
    final resolved =
        accent ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: useGradient ? null : resolved,
        gradient: useGradient ? AppPalette.gradientFor(resolved) : null,
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: AppPalette.shadowFor(resolved, opacity: 0.26),
      ),
      child: Icon(icon, size: iconSize, color: Colors.white),
    );
  }
}

/// Section title with optional icon, subtitle and trailing action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.accent,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? accent;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final resolvedAccent = accent ?? theme.colorScheme.primary;

    return Row(
      children: [
        if (icon != null) ...[
          IconTile(icon: icon!, accent: resolvedAccent, size: 38, iconSize: 19),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Small pill used for statuses, categories and metadata.
class SoftPill extends StatelessWidget {
  const SoftPill({
    super.key,
    required this.label,
    this.icon,
    this.accent,
    this.solid = false,
  });

  final String label;
  final IconData? icon;
  final Color? accent;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = accent ?? theme.colorScheme.primary;
    final foreground = solid
        ? Colors.white
        : theme.brightness == Brightness.dark
        ? resolved
        : Color.lerp(resolved, Colors.black, 0.28)!;

    return Container(
      padding: EdgeInsets.fromLTRB(icon == null ? 10 : 9, 5, 10, 5),
      decoration: BoxDecoration(
        color: solid
            ? resolved
            : resolved.withValues(alpha: theme.brightness == Brightness.dark
                  ? 0.22
                  : 0.12),
        borderRadius: BorderRadius.circular(AppPalette.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Rounded progress bar with a gradient fill and animated transitions.
class GradientProgressBar extends StatelessWidget {
  const GradientProgressBar({
    super.key,
    required this.value,
    this.accent,
    this.height = 9,
    this.trackColor,
  });

  final double value;
  final Color? accent;
  final double height;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = accent ?? theme.colorScheme.primary;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppPalette.pillRadius),
      child: Container(
        height: height,
        color:
            trackColor ??
            (theme.brightness == Brightness.dark
                ? Colors.white.withValues(alpha: 0.12)
                : AppPalette.mintSurfaceAlt),
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: clamped),
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) {
            if (animated <= 0) return const SizedBox.shrink();
            return FractionallySizedBox(
              widthFactor: animated,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppPalette.gradientFor(resolved),
                  borderRadius: BorderRadius.circular(AppPalette.pillRadius),
                  boxShadow: AppPalette.shadowFor(resolved, opacity: 0.3),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Decorative frosted pill for use on top of the gradient header.
class GlassChip extends StatelessWidget {
  const GlassChip({super.key, required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppPalette.pillRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular gradient progress indicator with a caption in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.caption,
    this.accent,
    this.size = 116,
    this.captionStyle,
  });

  final double value;
  final String caption;
  final Color? accent;
  final double size;
  final TextStyle? captionStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolved = accent ?? theme.colorScheme.primary;
    final clamped = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(
                  progress: animated,
                  accent: resolved,
                  trackColor: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.12)
                      : AppPalette.mintSurfaceAlt,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(size * 0.16),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style:
                        captionStyle ??
                        theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.accent,
    required this.trackColor,
  });

  final double progress;
  final Color accent;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.11;
    final rect = Offset.zero & size;
    final inner = rect.deflate(strokeWidth / 2);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawArc(inner, 0, 6.28318, false, trackPaint);

    if (progress <= 0) return;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -1.5708,
        endAngle: 4.7124,
        colors: [accent, Color.lerp(accent, AppPalette.teal, 0.7)!],
      ).createShader(inner);
    canvas.drawArc(inner, -1.5708, 6.28318 * progress, false, progressPaint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.accent != accent ||
        oldDelegate.trackColor != trackColor;
  }
}