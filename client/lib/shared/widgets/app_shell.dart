// App shell — bottom navigation + safe-area aware scaffold.
// During active multiplayer gameplay the bottom nav is hidden to prevent
// accidental navigation away from the match (prompt §5, §47).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/zen_colors.dart';
import '../../core/theme/zen_typography.dart';

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  static const List<_TabSpec> _tabs = [
    _TabSpec(
      path: '/home',
      label: 'Home',
      icon: Icons.sports_esports_outlined,
      activeIcon: Icons.sports_esports,
    ),
    _TabSpec(
      path: '/games',
      label: 'Games',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view,
    ),
    _TabSpec(
      path: '/friends',
      label: 'Friends',
      icon: Icons.group_outlined,
      activeIcon: Icons.group,
    ),
    _TabSpec(
      path: '/profile',
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
    ),
  ];

  bool _isMatchRoute(String loc) =>
      loc.contains('/match/') || loc.contains('/bingo/') || loc.contains('/sos/');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool showNav = !_isMatchRoute(location);
    return Scaffold(
      backgroundColor: ZenSurfaces.background,
      body: SafeArea(
        bottom: false,
        child: child,
      ),
      bottomNavigationBar: showNav
          ? _BottomNavBar(activePath: location, tabs: _tabs)
          : null,
    );
  }
}

class _TabSpec {
  const _TabSpec({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar({required this.activePath, required this.tabs});
  final String activePath;
  final List<_TabSpec> tabs;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: ZenSurfaces.containerLowest,
          boxShadow: [
            BoxShadow(
              color: Color(0x14000000),
              offset: Offset(0, -1),
              blurRadius: 12,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (final t in tabs)
                _TabButton(
                  spec: t,
                  active: activePath.startsWith(t.path),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({required this.spec, required this.active});
  final _TabSpec spec;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final Color color = active ? ZenAccent.primary : ZenText.secondary;
    return Expanded(
      child: InkWell(
        onTap: () => context.go(spec.path),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 56,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(active ? spec.activeIcon : spec.icon, color: color, size: 24),
              const SizedBox(height: 2),
              Text(
                spec.label,
                style: ZenTypography.labelSm.copyWith(
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}