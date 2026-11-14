import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:outpost_cadet/core/theme/design_tokens.dart';

/// Bottom chrome matching the Training Command mockup navbar.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = <_NavTab>[
    _NavTab(label: 'Dashboard', icon: Icons.speed_rounded),
    _NavTab(label: 'Missions', icon: Icons.rocket_launch_rounded),
    _NavTab(label: 'Journal', icon: Icons.article_outlined),
    _NavTab(label: 'Progress', icon: Icons.bar_chart_rounded),
    _NavTab(label: 'Cadet', icon: Icons.person_outline_rounded),
  ];

  static const _active = Color(0xFFE65100);
  static const _inactive = Color(0xFF9A9A9A);
  static const _statusTan = Color(0xFFC4B09A);
  static const _barBg = Color(0xFF0A0A0A);

  @override
  Widget build(BuildContext context) {
    final index = navigationShell.currentIndex;

    return Scaffold(
      backgroundColor: OcTokens.spaceBlack,
      body: navigationShell,
      bottomNavigationBar: ColoredBox(
        color: _barBg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _MarsStatusBar(color: _statusTan),
            const Divider(height: 1, thickness: 1, color: Color(0xFF2A2A2A)),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final tab = _tabs[i];
                    final selected = i == index;
                    final color = selected ? _active : _inactive;
                    return Expanded(
                      child: InkWell(
                        onTap: () => navigationShell.goBranch(
                          i,
                          initialLocation: i == index,
                        ),
                        splashColor: _active.withValues(alpha: 0.12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tab.icon, size: 22, color: color),
                            const SizedBox(height: 5),
                            Text(
                              tab.label.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: OcTokens.bodyFamily,
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              height: 2.5,
                              width: selected ? 22 : 0,
                              decoration: BoxDecoration(
                                color: _active,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTab {
  const _NavTab({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _MarsStatusBar extends StatelessWidget {
  const _MarsStatusBar({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'MARS TIME • SOL 142 • DUSK',
              style: TextStyle(
                fontFamily: OcTokens.bodyFamily,
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.7,
              ),
            ),
          ),
          Text(
            'OUTPOST COORD: 18.65°S 77.48°E',
            style: TextStyle(
              fontFamily: OcTokens.bodyFamily,
              color: color.withValues(alpha: 0.85),
              fontSize: 8.5,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
