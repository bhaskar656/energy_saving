import 'package:energy_saving/theme/app_palette.dart';
import 'package:flutter/material.dart';

/// Modern bottom navigation with a soft rounded surface, a mint active
/// indicator and a gradient icon for the selected tab.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _destinations = <_NavItem>[
    _NavItem(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      accent: AppPalette.emeraldDeep,
    ),
    _NavItem(
      label: 'Usage',
      icon: Icons.bolt_outlined,
      activeIcon: Icons.bolt_rounded,
      accent: AppPalette.skyDeep,
    ),
    _NavItem(
      label: 'Reminders',
      icon: Icons.notifications_none_rounded,
      activeIcon: Icons.notifications_active_rounded,
      accent: AppPalette.violet,
    ),
    _NavItem(
      label: 'Profile',
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      accent: AppPalette.tealDeep,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppPalette.mintBorder,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppPalette.forest.withValues(alpha: isDark ? 0.4 : 0.10),
            blurRadius: 26,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onChanged,
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon),
              selectedIcon: _GradientIcon(
                icon: destination.activeIcon,
                accent: destination.accent,
              ),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

class _GradientIcon extends StatelessWidget {
  const _GradientIcon({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        gradient: AppPalette.gradientFor(accent),
        borderRadius: BorderRadius.circular(9),
        boxShadow: AppPalette.shadowFor(accent, opacity: 0.35),
      ),
      child: Icon(icon, size: 16, color: Colors.white),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.accent,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Color accent;
}