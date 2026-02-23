import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import '../../core/ble/ble_manager.dart';
import '../../core/providers/ble_provider.dart';
import '../../core/models/health_models.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/metric_card.dart';

/// Shows SpO2, Blood Pressure, Temperature, HRV, and Stress metrics.
class MetricsScreen extends ConsumerStatefulWidget {
  const MetricsScreen({super.key});

  @override
  ConsumerState<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends ConsumerState<MetricsScreen> {
  // Measurement progress strings (null = idle, 'xx%' = measuring)
  String? _spo2Progress;
  String? _bpProgress;
  String? _tempProgress;

  String? _bgProgress;

  Timer? _spo2Timer;
  Timer? _bpTimer;
  Timer? _tempTimer;
  Timer? _bgTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRealtime());
  }

  // 15 seconds to reach 100%
  void _startSimulatedProgress(
      void Function(String?) setProgress, Timer? targetTimer, VoidCallback onFinish) {
    targetTimer?.cancel();
    int elapsed = 0;
    const totalMs = 15000;
    const intervalMs = 100;

    targetTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      elapsed += intervalMs;
      final percent = ((elapsed / totalMs) * 100).clamp(0, 100).toInt();
      
      if (mounted) {
        setProgress('$percent%');
      }

      if (elapsed >= totalMs) {
        timer.cancel();
        if (mounted) {
          setProgress(null);
          onFinish();
        }
      }
    });
  }

  Future<void> _startRealtime() async {
    final feature = ref.read(connectedDeviceProvider)?.feature;
    final ble = BleManager.instance;

    // Sequence through supported features
    if (feature?.isSupportBloodOxygen ?? true) {
      await ble.setRealTimeUpload(true, DeviceRealTimeDataType.bloodOxygen);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (feature?.isSupportBloodPressure ?? true) {
      await ble.setRealTimeUpload(true, DeviceRealTimeDataType.bloodPressure);
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (feature?.isSupportTemperature ?? true) {
      await ble.setRealTimeUpload(true, DeviceRealTimeDataType.combinedData);
    }
  }

  @override
  void dispose() {
    _spo2Timer?.cancel();
    _bpTimer?.cancel();
    _bgTimer?.cancel();
    BleManager.instance.setRealTimeUpload(false, DeviceRealTimeDataType.bloodOxygen);
    BleManager.instance.setRealTimeUpload(false, DeviceRealTimeDataType.bloodPressure);
    BleManager.instance.setRealTimeUpload(false, DeviceRealTimeDataType.combinedData);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feature = ref.watch(connectedDeviceProvider)?.feature;
    final spo2 = ref.watch(bloodOxygenProvider);
    final bp = ref.watch(bloodPressureProvider);
    final temp = ref.watch(temperatureProvider);
    final stress = ref.watch(pressureProvider);

    final bpoHistory = ref.watch(bloodOxygenHistoryProvider);
    final bpHistory = ref.watch(bloodPressureHistoryProvider);
    final tempHistory = ref.watch(temperatureHistoryProvider);
    // Note: We don't have a specific blood glucose history provider yet, we'll implement it next task. Let's provide a mock or empty list for now until then
    final bgHistory = const AsyncValue<List<dynamic>>.loading();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Health Metrics')),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Blood Oxygen
                if (feature?.isSupportBloodOxygen ?? true) ...[
                  _SectionHeader('Blood Oxygen (SpO₂)'),
                  const SizedBox(height: 8),
                  _MetricDetailCard(
                    title: 'Current SpO₂',
                    value: spo2 != null ? '${spo2.spo2}%' : '--',
                    icon: Icons.water_drop_rounded,
                    color: AppColors.bloodOxygen,
                    isMeasuring: _spo2Progress != null,
                    progressText: _spo2Progress,
                    onMeasure: () async {
                      await BleManager.instance.startMeasure(DeviceAppControlMeasureHealthDataType.bloodOxygen);
                      _startSimulatedProgress(
                        (p) => setState(() => _spo2Progress = p),
                        _spo2Timer,
                        () {
                          BleManager.instance.stopMeasure(DeviceAppControlMeasureHealthDataType.bloodOxygen);
                          ref.refresh(bloodOxygenHistoryProvider);
                        },
                      );
                    },
                    historyRows: bpoHistory.when(
                      data: (r) => r.take(5).map((rec) =>
                        _HistoryItem(
                          time: rec.time,
                          value: '${rec.spo2}%',
                          color: AppColors.bloodOxygen,
                        ),
                      ).toList(),
                      loading: () => [], error: (_, __) => [],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Blood Pressure
                if (feature?.isSupportBloodPressure ?? true) ...[
                  _SectionHeader('Blood Pressure'),
                  const SizedBox(height: 8),
                  _MetricDetailCard(
                    title: 'Systolic / Diastolic',
                    value: bp != null ? '${bp.systolic}/${bp.diastolic}' : '--',
                    unit: 'mmHg',
                    icon: Icons.bloodtype_rounded,
                    color: AppColors.bloodPressure,
                    isMeasuring: _bpProgress != null,
                    progressText: _bpProgress,
                    onMeasure: () async {
                      await BleManager.instance.startMeasure(DeviceAppControlMeasureHealthDataType.bloodPressure);
                      _startSimulatedProgress(
                        (p) => setState(() => _bpProgress = p),
                        _bpTimer,
                        () {
                          BleManager.instance.stopMeasure(DeviceAppControlMeasureHealthDataType.bloodPressure);
                          ref.refresh(bloodPressureHistoryProvider);
                        },
                      );
                    },
                    historyRows: bpHistory.when(
                      data: (r) => r.take(5).map((rec) =>
                        _HistoryItem(
                          time: rec.time,
                          value: '${rec.systolic}/${rec.diastolic} mmHg',
                          color: AppColors.bloodPressure,
                        ),
                      ).toList(),
                      loading: () => [], error: (_, __) => [],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Temperature
                if (feature?.isSupportTemperature ?? true) ...[
                  _SectionHeader('Body Temperature'),
                  const SizedBox(height: 8),
                  _MetricDetailCard(
                    title: 'Temperature',
                    value: temp != null ? '${temp.celsius.toStringAsFixed(1)}°C' : '--',
                    icon: Icons.thermostat_rounded,
                    color: AppColors.temperature,
                    isMeasuring: _tempProgress != null,
                    progressText: _tempProgress,
                    onMeasure: () async {
                      await BleManager.instance.startMeasure(DeviceAppControlMeasureHealthDataType.bodyTemperature);
                      _startSimulatedProgress(
                        (p) => setState(() => _tempProgress = p),
                        _tempTimer,
                        () {
                          BleManager.instance.stopMeasure(DeviceAppControlMeasureHealthDataType.bodyTemperature);
                          ref.refresh(temperatureHistoryProvider);
                        },
                      );
                    },
                    historyRows: tempHistory.when(
                      data: (r) => r.take(5).map((rec) =>
                        _HistoryItem(
                          time: rec.time,
                          value: '${rec.celsius.toStringAsFixed(1)}°C',
                          color: AppColors.temperature,
                        ),
                      ).toList(),
                      loading: () => [], error: (_, __) => [],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Blood Glucose
                if (feature?.isSupportBloodGlucose ?? true) ...[
                  _SectionHeader('Blood Glucose'),
                  const SizedBox(height: 8),
                  _MetricDetailCard(
                    title: 'Current Glucose',
                    value: ref.watch(bloodGlucoseProvider) != null ? '${ref.watch(bloodGlucoseProvider)!.mmolL.toStringAsFixed(1)} mmol/L' : '--',
                    icon: Icons.water_drop_outlined,
                    color: Colors.tealAccent,
                    isMeasuring: _bgProgress != null,
                    progressText: _bgProgress,
                    onMeasure: () async {
                      await BleManager.instance.startMeasure(DeviceAppControlMeasureHealthDataType.bloodGlucose);
                      _startSimulatedProgress(
                        (p) => setState(() => _bgProgress = p),
                        _bgTimer,
                        () {
                          BleManager.instance.stopMeasure(DeviceAppControlMeasureHealthDataType.bloodGlucose);
                          // ref.refresh(bloodGlucoseHistoryProvider);
                        },
                      );
                    },
                    historyRows: bgHistory.when(
                      data: (r) => [], // We will hook up BG history parsing later
                      loading: () => [], error: (_, __) => [],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Stress
                if (feature?.isSupportPressure ?? true) ...[
                  _SectionHeader('Stress Level'),
                  const SizedBox(height: 8),
                  MetricCard(
                    title: 'Current Stress',
                    value: stress != null ? '${stress.stressLevel}' : '--',
                    unit: '/ 100',
                    icon: Icons.psychology_rounded,
                    color: AppColors.stress,
                  ),
                  const SizedBox(height: 24),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      );
}

class _MetricDetailCard extends StatelessWidget {
  final String title, value;
  final String? unit;
  final IconData icon;
  final Color color;
  final List<Widget> historyRows;
  final VoidCallback? onMeasure;
  final bool isMeasuring;
  final String? progressText;

  const _MetricDetailCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.historyRows,
    this.unit,
    this.onMeasure,
    this.isMeasuring = false,
    this.progressText,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), AppColors.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (onMeasure != null)
                  ElevatedButton(
                    onPressed: isMeasuring ? null : onMeasure,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color.withOpacity(0.2),
                      foregroundColor: color,
                      elevation: 0,
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: isMeasuring 
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: color)),
                              const SizedBox(width: 8),
                              Text(progressText ?? '...', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : const Text('Measure', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            if (historyRows.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(color: AppColors.surfaceLight),
              const SizedBox(height: 8),
              ...historyRows,
            ],
          ],
        ),
      );
}

class _HistoryItem extends StatelessWidget {
  final DateTime time;
  final String value;
  final Color color;
  const _HistoryItem({required this.time, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}
