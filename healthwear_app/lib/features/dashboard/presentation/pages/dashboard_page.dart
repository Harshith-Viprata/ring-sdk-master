import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/services/health_background_service.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/ble_status_bar.dart';
import '../../../../shared/widgets/metric_card.dart';
import '../../../device/presentation/bloc/device_bloc.dart';
import '../bloc/dashboard_bloc.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Listen for sync_complete messages from the foreground service
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  void _onReceiveTaskData(Object data) {
    if (data is Map && data['type'] == 'sync_complete') {
      print('[DashboardPage] Received sync_complete from BG service');
      if (mounted) {
        context.read<DashboardBloc>().add(BackgroundSyncComplete());
      }
    }
  }

  @override
  void dispose() {
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeviceBloc, DeviceState>(
      listenWhen: (prev, curr) =>
          prev.status != DeviceConnectionStatus.connected &&
          curr.status == DeviceConnectionStatus.connected,
      listener: (context, deviceState) {
        // Fire exactly once when device transitions to connected
        final dashBloc = context.read<DashboardBloc>();
        dashBloc.add(LoadHealthData());
        dashBloc.add(StartRealTimeMonitoring());

        // Start the foreground service for background monitoring
        HealthBackgroundService.start();
      },
      child: BlocBuilder<DeviceBloc, DeviceState>(
        builder: (context, deviceState) {
          final isConnected =
              deviceState.status == DeviceConnectionStatus.connected;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                SafeArea(
                  bottom: false,
                  child: const BleStatusBar(),
                ),
                Expanded(
                  child:
                      isConnected ? _ConnectedDashboard() : _NotConnectedView(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConnectedDashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        final isLoading = state.status == DashboardStatus.loading;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: AppColors.background,
              expandedHeight: 120,
              pinned: true,
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
              actions: [
                IconButton(
                  onPressed: () => context.push(AppRoutes.scan),
                  icon: const Icon(
                    Icons.watch_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick actions
                  _QuickActionRow(),
                  const SizedBox(height: 20),
                  // Metric grid
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      // Heart Rate
                      MetricCard(
                        title: 'Heart Rate',
                        value: state.latestHeartRate != null
                            ? '${state.latestHeartRate}'
                            : '--',
                        unit: 'BPM',
                        icon: Icons.favorite_rounded,
                        color: AppColors.heartRate,
                        isLoading: isLoading,
                        onTap: () => context.push(AppRoutes.heartRate),
                      ),
                      // Steps
                      MetricCard(
                        title: 'Steps',
                        value:
                            state.todaySteps > 0 ? '${state.todaySteps}' : '--',
                        unit: '',
                        icon: Icons.directions_walk_rounded,
                        color: AppColors.steps,
                        isLoading: isLoading,
                        onTap: () => context.push(AppRoutes.activity),
                      ),
                      // Blood Oxygen
                      MetricCard(
                        title: 'Blood Oxygen',
                        value: state.liveSpO2 != null
                            ? '${state.liveSpO2}'
                            : state.bloodOxygenHistory.isNotEmpty
                                ? '${state.bloodOxygenHistory.last.spo2}'
                                : '--',
                        unit: '%',
                        icon: Icons.water_drop_rounded,
                        color: AppColors.bloodOxygen,
                        isLoading: isLoading,
                        onTap: () => context.push(AppRoutes.bloodOxygen),
                      ),
                      // Blood Pressure
                      MetricCard(
                        title: 'Blood Pressure',
                        value: state.liveSystolic != null
                            ? '${state.liveSystolic}/${state.liveDiastolic ?? 0}'
                            : state.bloodPressureHistory.isNotEmpty
                                ? '${state.bloodPressureHistory.last.systolic}/${state.bloodPressureHistory.last.diastolic}'
                                : '--',
                        unit: 'mmHg',
                        icon: Icons.bloodtype_rounded,
                        color: AppColors.bloodPressure,
                        isLoading: isLoading,
                        onTap: () => context.push(AppRoutes.bloodPressure),
                      ),
                      // Temperature
                      MetricCard(
                        title: 'Temperature',
                        value: state.liveTemperature != null
                            ? state.liveTemperature!.toStringAsFixed(1)
                            : state.temperatureHistory.isNotEmpty
                                ? state.temperatureHistory.last.celsius
                                    .toStringAsFixed(1)
                                : '--',
                        unit: '°C',
                        icon: Icons.thermostat_rounded,
                        color: AppColors.temperature,
                        isLoading: isLoading,
                        onTap: () => context.push(AppRoutes.temperature),
                      ),
                      // Blood Glucose
                      MetricCard(
                        title: 'Glucose',
                        value: state.latestBloodGlucose != null
                            ? state.latestBloodGlucose!.toStringAsFixed(1)
                            : '--',
                        unit: 'mmol/L',
                        icon: Icons.opacity_rounded,
                        color: const Color(0xFFFF8F00),
                        isLoading: isLoading,
                        onTap: () => context.push(AppRoutes.bloodGlucose),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ECG banner
                  _EcgBanner(
                    onTap: () => context.push(AppRoutes.ecg),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
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
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            label: 'ECG',
            icon: Icons.monitor_heart_rounded,
            color: AppColors.ecg,
            onTap: () => context.push(AppRoutes.ecg),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            label: 'Metrics',
            icon: Icons.bar_chart_rounded,
            color: AppColors.accentPurple,
            onTap: () => context.push(AppRoutes.metrics),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _QuickAction(
            label: 'Sleep',
            icon: Icons.bedtime_rounded,
            color: AppColors.sleep,
            onTap: () => context.go(AppRoutes.sleep),
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

class _EcgBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _EcgBanner({required this.onTap});

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

class _NotConnectedView extends StatelessWidget {
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
                onPressed: () => context.push(AppRoutes.scan),
                icon: const Icon(Icons.bluetooth_searching_rounded),
                label: const Text('Connect Device'),
              ),
            ],
          ),
        ),
      );
}
