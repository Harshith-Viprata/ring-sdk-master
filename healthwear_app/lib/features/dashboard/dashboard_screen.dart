import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import '../../core/ble/ble_manager.dart';
import '../../core/providers/ble_provider.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/metric_card.dart';
import '../../shared/widgets/ble_status_bar.dart';
import '../device/scan_screen.dart';
import '../heart_rate/heart_rate_screen.dart';
import '../activity/activity_screen.dart';
import '../sleep/sleep_screen.dart';
import '../ecg/ecg_screen.dart';
import '../health_metrics/metrics_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _navIndex = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    initBleEventWiring(ref);
    // Request the device to continuously push live steps/distance data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initDashboard();
    });
  }

  void _initDashboard() {
    final feature = ref.read(connectedDeviceProvider)?.feature;
    
    // Initial sync of all supported metrics
    // We call them sequentially with a small delay to ensure the device handles each request
    Future.microtask(() async {
      final ble = BleManager.instance;
      
      // Step is usually always supported and a good "keep-alive"
      await ble.setRealTimeUpload(true, DeviceRealTimeDataType.step);
      
      if (feature?.isSupportHeartRate ?? true) {
        await Future.delayed(const Duration(milliseconds: 300));
        await ble.setRealTimeUpload(true, DeviceRealTimeDataType.heartRate);
      }
      
      if (feature?.isSupportBloodOxygen ?? true) {
        await Future.delayed(const Duration(milliseconds: 300));
        await ble.setRealTimeUpload(true, DeviceRealTimeDataType.bloodOxygen);
      }
      
      if (feature?.isSupportBloodPressure ?? true) {
        await Future.delayed(const Duration(milliseconds: 300));
        await ble.setRealTimeUpload(true, DeviceRealTimeDataType.bloodPressure);
      }
      
      if (feature?.isSupportTemperature ?? true) {
        await Future.delayed(const Duration(milliseconds: 300));
        await ble.setRealTimeUpload(true, DeviceRealTimeDataType.combinedData);
      }
    });
    
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted && ref.read(bleStateProvider) == BluetoothState.connected) {
        ref.invalidate(heartRateHistoryProvider);
        ref.invalidate(bloodOxygenHistoryProvider);
        ref.invalidate(bloodPressureHistoryProvider);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  final _pages = const [
    _HomeTab(),
    ActivityScreen(),
    SleepScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bleStateProvider);
    final isConnected = bleState == BluetoothState.connected;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Status bar
          SafeArea(
            bottom: false,
            child: Column(children: [
              BleStatusBar(),
            ]),
          ),
          Expanded(child: _pages[_navIndex]),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.surfaceLight, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _navIndex,
          onTap: (i) => setState(() => _navIndex = i),
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: AppColors.textMuted,
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

// ─── Home Tab ────────────────────────────────────────────────────────────────

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleStateProvider);
    final device = ref.watch(connectedDeviceProvider);
    final isConnected = bleState == BluetoothState.connected;
    final feature = device?.feature;

    final hr = ref.watch(heartRateProvider);
    final spo2 = ref.watch(bloodOxygenProvider);
    final temp = ref.watch(temperatureProvider);
    final steps = ref.watch(stepsProvider);
    final bp = ref.watch(bloodPressureProvider);
    final stress = ref.watch(pressureProvider);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // App Bar
        SliverAppBar(
          backgroundColor: AppColors.background,
          expandedHeight: 120,
          pinned: true,
          actions: [
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
              icon: Stack(
                children: [
                  const Icon(Icons.watch_rounded, color: AppColors.textPrimary),
                  if (!isConnected)
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accentRed,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(16, 0, 0, 16),
            title: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  'HealthWear',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (!isConnected)
          SliverFillRemaining(
            child: _NotConnectedCard(
              onConnect: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ScanScreen()),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick action buttons
                _QuickActionRow(feature: feature),
                const SizedBox(height: 20),
                  // Metrics grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      if (feature?.isSupportHeartRate ?? true)
                        MetricCard(
                          title: 'Heart Rate',
                          value: hr != null ? '${hr.bpm}' : '--',
                          unit: 'BPM',
                          icon: Icons.favorite_rounded,
                          color: AppColors.heartRate,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const HeartRateScreen())),
                        ),
                      if (feature?.isSupportStep ?? true)
                        MetricCard(
                          title: 'Steps',
                          value: steps != null ? '${steps.steps}' : '--',
                          unit: '',
                          icon: Icons.directions_walk_rounded,
                          color: AppColors.steps,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const ActivityScreen())),
                        ),
                      if (feature?.isSupportBloodOxygen ?? true)
                        MetricCard(
                          title: 'Blood Oxygen',
                          value: spo2 != null ? '${spo2.spo2}' : '--',
                          unit: '%',
                          icon: Icons.water_drop_rounded,
                          color: AppColors.bloodOxygen,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MetricsScreen())),
                        ),
                      if (feature?.isSupportBloodPressure ?? true)
                        MetricCard(
                          title: 'Blood Pressure',
                          value: bp != null ? '${bp.systolic}/${bp.diastolic}' : '--',
                          unit: 'mmHg',
                          icon: Icons.bloodtype_rounded,
                          color: AppColors.bloodPressure,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MetricsScreen())),
                        ),
                      if (feature?.isSupportBloodGlucose ?? true)
                        MetricCard(
                          title: 'Blood Glucose',
                          value: ref.watch(bloodGlucoseProvider) != null 
                                 ? ref.watch(bloodGlucoseProvider)!.mmolL.toStringAsFixed(1) 
                                 : '--',
                          unit: 'mmol/L',
                          icon: Icons.water_drop_outlined,
                          color: Colors.tealAccent,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MetricsScreen())),
                        ),
                      if (feature?.isSupportTemperature ?? true)
                        MetricCard(
                          title: 'Temperature',
                          value: temp != null ? temp.celsius.toStringAsFixed(1) : '--',
                          unit: '°C',
                          icon: Icons.thermostat_rounded,
                          color: AppColors.temperature,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MetricsScreen())),
                        ),
                      if (feature?.isSupportPressure ?? true)
                        MetricCard(
                          title: 'Stress',
                          value: stress != null ? '${stress.stressLevel}' : '--',
                          unit: '',
                          icon: Icons.psychology_rounded,
                          color: AppColors.stress,
                          onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => const MetricsScreen())),
                        ),
                    ],
                  ),
                const SizedBox(height: 16),
                // ECG banner (if supported)
                if (feature?.isSupportRealTimeECG ?? true)
                  _ECGBanner(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const EcgScreen())),
                  ),
              ]),
            ),
          ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning 🌅';
    if (h < 17) return 'Good afternoon ☀️';
    return 'Good evening 🌙';
  }
}

class _QuickActionRow extends StatelessWidget {
  final DeviceFeature? feature;
  const _QuickActionRow({this.feature});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (feature?.isSupportRealTimeECG ?? true)
          Expanded(
            child: _QuickAction(
              label: 'ECG',
              icon: Icons.monitor_heart_rounded,
              color: AppColors.ecg,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EcgScreen())),
            ),
          ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            label: 'Metrics',
            icon: Icons.bar_chart_rounded,
            color: AppColors.accentPurple,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const MetricsScreen())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            label: 'Sleep',
            icon: Icons.bedtime_rounded,
            color: AppColors.sleep,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SleepScreen())),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ECGBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _ECGBanner({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF001A2E), Color(0xFF002040)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.ecg.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.ecg.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.monitor_heart_rounded,
                    color: AppColors.ecg, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ECG Measurement',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                    SizedBox(height: 3),
                    Text('Tap to start real-time ECG',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.ecg),
            ],
          ),
        ),
      );
}

class _NotConnectedCard extends StatelessWidget {
  final VoidCallback onConnect;
  const _NotConnectedCard({required this.onConnect});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.1),
                  border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                ),
                child: const Icon(Icons.bluetooth_rounded,
                    color: AppColors.accent, size: 48),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Device Connected',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Connect your YC ring or smartwatch\nto view real-time health data',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onConnect,
                icon: const Icon(Icons.bluetooth_searching_rounded),
                label: const Text('Connect Device'),
              ),
            ],
          ),
        ),
      );
}
