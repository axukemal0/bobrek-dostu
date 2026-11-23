import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import 'responsive.dart';

/// Alt navigasyonlu kabuk. Tek elle kullanım için gezinme ALTTA.
class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  static const List<({String path, String label, IconData icon, IconData activeIcon})>
      tabs = [
    (
      path: Routes.home,
      label: 'Ana sayfa',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded
    ),
    (
      path: Routes.nutrition,
      label: 'Besin',
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant_rounded
    ),
    (
      path: Routes.fluid,
      label: 'Sıvı',
      icon: Icons.water_drop_outlined,
      activeIcon: Icons.water_drop_rounded
    ),
    (
      path: Routes.medications,
      label: 'İlaç',
      icon: Icons.medication_outlined,
      activeIcon: Icons.medication_rounded
    ),
    (
      path: Routes.more,
      label: 'Daha',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded
    ),
  ];

  int get _index {
    final i = tabs.indexWhere((t) => t.path == location);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final r = Responsive.fromContext(context);

    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(bottom: false, child: child),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: p.surface,
          boxShadow: [
            BoxShadow(
              color: p.shadowDark,
              offset: const Offset(0, -2),
              blurRadius: 16,
            ),
          ],
          border: Border(top: BorderSide(color: p.divider)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            height: r.isCompact ? 66 : 72,
            labelBehavior:
                NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (i) {
              if (i == _index) return;
              context.go(tabs[i].path);
            },
            destinations: [
              for (final t in tabs)
                NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                  tooltip: t.label,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
