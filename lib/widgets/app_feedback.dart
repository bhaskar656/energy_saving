import 'package:energy_saving/theme/app_palette.dart';
import 'package:energy_saving/widgets/eco_card.dart';
import 'package:flutter/material.dart';

/// Friendly, colourful empty / error / message panel.
class AppFeedbackPanel extends StatelessWidget {
  const AppFeedbackPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.isError = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final accent = isError ? theme.colorScheme.error : AppPalette.emeraldDeep;

    return EcoCard(
      gradient: AppPalette.washFor(accent, strength: isError ? 0.7 : 1),
      borderColor: accent.withValues(alpha: 0.22),
      shadow: AppPalette.shadowFor(accent, opacity: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconTile(icon: icon, accent: accent, size: 62, iconSize: 30),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: Icon(
                actionIcon ?? (isError ? Icons.refresh_rounded : Icons.add_rounded),
              ),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Centred loading state with the app's gradient spinner.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.message = 'Loading'});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 46,
          height: 46,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            strokeCap: StrokeCap.round,
            backgroundColor: AppPalette.mint,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}