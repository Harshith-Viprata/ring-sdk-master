import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/activity/presentation/pages/activity_page.dart';
import '../../features/sleep/presentation/pages/sleep_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/device/presentation/pages/scan_page.dart';
import '../../features/heart_rate/presentation/pages/heart_rate_page.dart';
import '../../features/ecg/presentation/pages/ecg_page.dart';
import '../../features/metrics/presentation/pages/metrics_page.dart';
import '../../features/blood_oxygen/presentation/pages/blood_oxygen_page.dart';
import '../../features/blood_pressure/presentation/pages/blood_pressure_page.dart';
import '../../features/temperature/presentation/pages/temperature_page.dart';
import '../../features/blood_glucose/presentation/pages/blood_glucose_page.dart';
import '../../features/stress/presentation/pages/stress_page.dart';

// ─── Route Paths ─────────────────────────────────────────────────────────────

abstract class AppRoutes {
  static const home = '/';
  static const activity = '/activity';
  static const sleep = '/sleep';
  static const settings = '/settings';
  static const scan = '/scan';
  static const heartRate = '/heart-rate';
  static const ecg = '/ecg';
  static const metrics = '/metrics';
  static const bloodOxygen = '/blood-oxygen';
  static const bloodPressure = '/blood-pressure';
  static const temperature = '/temperature';
  static const bloodGlucose = '/blood-glucose';
  static const stress = '/stress';
}

// ─── Navigator Keys ──────────────────────────────────────────────────────────

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'home');
final _shellNavigatorActivityKey =
    GlobalKey<NavigatorState>(debugLabel: 'activity');
final _shellNavigatorSleepKey = GlobalKey<NavigatorState>(debugLabel: 'sleep');
final _shellNavigatorSettingsKey =
    GlobalKey<NavigatorState>(debugLabel: 'settings');

// ─── Router ──────────────────────────────────────────────────────────────────

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.home,
  routes: [
    // ── Shell for bottom navigation tabs ──────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return _ScaffoldWithNavBar(navigationShell: navigationShell);
      },
      branches: [
        // Tab 0 — Home / Dashboard
        StatefulShellBranch(
          navigatorKey: _shellNavigatorHomeKey,
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const DashboardPage(),
            ),
          ],
        ),
        // Tab 1 — Activity
        StatefulShellBranch(
          navigatorKey: _shellNavigatorActivityKey,
          routes: [
            GoRoute(
              path: AppRoutes.activity,
              builder: (context, state) => const ActivityPage(),
            ),
          ],
        ),
        // Tab 2 — Sleep
        StatefulShellBranch(
          navigatorKey: _shellNavigatorSleepKey,
          routes: [
            GoRoute(
              path: AppRoutes.sleep,
              builder: (context, state) => const SleepPage(),
            ),
          ],
        ),
        // Tab 3 — Settings
        StatefulShellBranch(
          navigatorKey: _shellNavigatorSettingsKey,
          routes: [
            GoRoute(
              path: AppRoutes.settings,
              builder: (context, state) => const SettingsPage(),
            ),
          ],
        ),
      ],
    ),

    // ── Full-screen routes pushed above the shell ─────────────────────────
    GoRoute(
      path: AppRoutes.scan,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ScanPage(),
    ),
    GoRoute(
      path: AppRoutes.heartRate,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const HeartRatePage(),
    ),
    GoRoute(
      path: AppRoutes.ecg,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const EcgPage(),
    ),
    GoRoute(
      path: AppRoutes.metrics,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MetricsPage(),
    ),
    GoRoute(
      path: AppRoutes.bloodOxygen,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BloodOxygenPage(),
    ),
    GoRoute(
      path: AppRoutes.bloodPressure,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BloodPressurePage(),
    ),
    GoRoute(
      path: AppRoutes.temperature,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const TemperaturePage(),
    ),
    GoRoute(
      path: AppRoutes.bloodGlucose,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BloodGlucosePage(),
    ),
    GoRoute(
      path: AppRoutes.stress,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StressPage(),
    ),
  ],
);

// ─── Bottom Navigation Shell ─────────────────────────────────────────────────

class _ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _ScaffoldWithNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor,
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_walk_rounded),
              label: 'Activity',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bedtime_rounded),
              label: 'Sleep',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
