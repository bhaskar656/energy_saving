import 'package:energy_saving/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Friendly, colourful header shared by every top level screen.
///
/// Paints the signature green → emerald → teal gradient, soft decorative
/// blobs and an optional illustration so no screen starts on flat white.
class EcoHeader extends StatelessWidget {
  const EcoHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.illustration,
    this.trailing,
    this.chips = const <Widget>[],
    this.bottom,
    this.gradient,
    this.borderRadius = const BorderRadius.vertical(
      bottom: Radius.circular(34),
    ),
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? illustration;
  final Widget? trailing;
  final List<Widget> chips;
  final Widget? bottom;
  final Gradient? gradient;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: BoxDecoration(gradient: gradient ?? AppPalette.heroGradient),
        child: Stack(
          children: [
            const Positioned.fill(child: _HeaderDecorations()),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (illustration != null) ...[
                          illustration!,
                          const SizedBox(width: 16),
                        ],
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (eyebrow != null) ...[
                                Text(
                                  eyebrow!.toUpperCase(),
                                  style: textTheme.labelSmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],
                              Text(
                                title,
                                style: textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (subtitle != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subtitle!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 12),
                          trailing!,
                        ],
                      ],
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: chips,
                      ),
                    ],
                    if (bottom != null) ...[
                      const SizedBox(height: 18),
                      bottom!,
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderDecorations extends StatelessWidget {
  const _HeaderDecorations();

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: _Blob(size: 210, color: Colors.white.withValues(alpha: 0.10)),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: _Blob(size: 150, color: AppPalette.mint.withValues(alpha: 0.22)),
          ),
          Positioned(
            top: 28,
            right: 96,
            child: Transform.rotate(
              angle: 0.5,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ),
          Positioned(
            right: 26,
            bottom: 26,
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Lightweight vector illustration built from energy themed icons.
class EcoIllustration extends StatelessWidget {
  const EcoIllustration({
    super.key,
    this.size = 78,
    this.mainIcon = Icons.energy_savings_leaf_rounded,
    this.accent = AppPalette.amber,
  });

  final double size;
  final IconData mainIcon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Container(
            width: size * 0.58,
            height: size * 0.58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Colors.white, AppPalette.mint],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              mainIcon,
              color: AppPalette.forest,
              size: size * 0.3,
            ),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: _Badge(
              size: size * 0.32,
              gradient: AppPalette.sunGradient,
              icon: Icons.bolt_rounded,
            ),
          ),
          Positioned(
            bottom: 0,
            left: -4,
            child: _Badge(
              size: size * 0.3,
              gradient: AppPalette.skyGradient,
              icon: Icons.lightbulb_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.size,
    required this.gradient,
    required this.icon,
  });

  final double size;
  final Gradient gradient;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: AppPalette.forest.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, size: size * 0.52, color: Colors.white),
    );
  }
}