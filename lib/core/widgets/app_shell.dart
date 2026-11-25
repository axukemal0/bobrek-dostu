import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../router/app_router.dart';
import '../theme/app_colors.dart';
import '../theme/neumorphic.dart';
import 'responsive.dart';

/// Alt gezinme çubuğunun kapladığı yüksekliği sayfalara bildirir.
///
/// Gövde çubuğun altına uzandığı için (buzlu cam ancak arkasından içerik
/// akarsa anlamlıdır) sayfaların alt boşluğu bu kadar artmalı; yoksa son
/// kart çubuğun altında kalır.
class BottomBarInset extends InheritedWidget {
  const BottomBarInset({
    required this.height,
    required super.child,
    super.key,
  });

  final double height;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<BottomBarInset>()?.height ?? 0;

  @override
  bool updateShouldNotify(BottomBarInset oldWidget) =>
      oldWidget.height != height;
}

/// Kayan eylem butonunu alt gezinme çubuğunun üstüne kaldırır.
///
/// Kabuk `extendBody: true` kullanıyor (içerik camın arkasından aksın
/// diye); bu da iç ekranların kendi Scaffold'undaki FAB'ı çubuğun altında
/// bırakıyordu. "Yemek ekle" butonu görünmez olmuştu.
class ShellFabLocation implements FloatingActionButtonLocation {
  const ShellFabLocation(this.lift);

  /// Kabuk dışındaki (itilmiş) sayfalarda 0 gelir ve davranış değişmez.
  final double lift;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final base =
        FloatingActionButtonLocation.endFloat.getOffset(scaffoldGeometry);
    return Offset(base.dx, base.dy - lift);
  }

  @override
  String toString() => 'ShellFabLocation($lift)';
}

Color _homeTone(AppPalette p) => p.primary;
Color _nutritionTone(AppPalette p) => p.accents.energy;
Color _fluidTone(AppPalette p) => p.accents.fluid;
Color _medicationTone(AppPalette p) => p.accents.medication;
Color _moreTone(AppPalette p) => p.accents.appointment;

/// Alt navigasyonlu kabuk. Tek elle kullanım için gezinme ALTTA.
class AppShell extends StatelessWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  /// Sekmeler. `tone`, o bölümün rengini seçer (bkz. [AppAccents]) —
  /// seçili sekme gideceği alanın rengiyle yanar, böylece alt çubuk da
  /// yön bulmaya katkı verir.
  static const List<
      ({
        String path,
        String label,
        IconData icon,
        IconData activeIcon,
        Color Function(AppPalette) tone,
      })> tabs = [
    (
      path: Routes.home,
      label: 'Ana sayfa',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      tone: _homeTone,
    ),
    (
      path: Routes.nutrition,
      label: 'Besin',
      icon: Icons.restaurant_outlined,
      activeIcon: Icons.restaurant_rounded,
      tone: _nutritionTone,
    ),
    (
      path: Routes.fluid,
      label: 'Sıvı',
      icon: Icons.water_drop_outlined,
      activeIcon: Icons.water_drop_rounded,
      tone: _fluidTone,
    ),
    (
      path: Routes.medications,
      label: 'İlaç',
      icon: Icons.medication_outlined,
      activeIcon: Icons.medication_rounded,
      tone: _medicationTone,
    ),
    (
      path: Routes.more,
      label: 'Daha',
      icon: Icons.grid_view_outlined,
      activeIcon: Icons.grid_view_rounded,
      tone: _moreTone,
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
    final barHeight = r.isCompact ? 68.0 : 74.0;

    return Scaffold(
      backgroundColor: p.background,
      // Gövde çubuğun altına uzanır: içerik camın arkasından akar.
      extendBody: true,
      body: BottomBarInset(
        height: barHeight,
        child: SafeArea(bottom: false, child: child),
      ),
      bottomNavigationBar: GlassBar(
        blur: 18,
        borderSide: BorderSide(color: p.divider.withValues(alpha: 0.8)),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            height: barHeight,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            indicatorColor:
                tabs[_index].tone(p).withValues(alpha: p.isDark ? 0.26 : 0.16),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            // Seçili sekmenin yazısı da ikonuyla aynı renkte olsun;
            // yoksa ikon renkli, etiket nötr kalıp kopuk duruyor.
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              final selected = states.contains(WidgetState.selected);
              return Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected ? tabs[_index].tone(p) : p.textSecondary,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w600,
                  );
            }),
            onDestinationSelected: (i) {
              if (i == _index) return;
              context.go(tabs[i].path);
            },
            destinations: [
              for (final t in tabs)
                NavigationDestination(
                  icon: Icon(t.icon, color: p.textSecondary),
                  selectedIcon: Icon(t.activeIcon, color: t.tone(p)),
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
