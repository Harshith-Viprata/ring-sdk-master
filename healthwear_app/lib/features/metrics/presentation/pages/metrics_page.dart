import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/domain/repositories/health_repository.dart';
import '../../../../core/di/injection_container.dart';

class MetricsPage extends StatefulWidget {
  const MetricsPage({super.key});

  @override
  State<MetricsPage> createState() => _MetricsPageState();
}

class _MetricsPageState extends State<MetricsPage> {
  MeasurementType? _activeMeasurement;
  int _measureSeconds = 0;
  Timer? _measureTimer;
  static const int _measureDuration = 45;

  void _startMeasurement(MeasurementType type) {
    setState(() {
      _activeMeasurement = type;
      _measureSeconds = 0;
    });
    sl<HealthRepository>().startMeasurement(type);
    _measureTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_measureSeconds >= _measureDuration) {
        _stopMeasurement();
      } else {
        setState(() => _measureSeconds++);
      }
    });
  }

  void _stopMeasurement() {
    if (_activeMeasurement != null) {
      sl<HealthRepository>().stopMeasurement(_activeMeasurement!);
    }
    _measureTimer?.cancel();
    setState(() {
      _activeMeasurement = null;
      _measureSeconds = 0;
    });
  }

  @override
  void dispose() {
    _measureTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('All Metrics'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Blood Oxygen
              _MeasurableSection(
                title: 'Blood Oxygen',
                icon: Icons.water_drop_rounded,
                color: AppColors.bloodOxygen,
                currentValue: state.liveSpO2 != null
                    ? '${state.liveSpO2}%'
                    : state.bloodOxygenHistory.isNotEmpty
                        ? '${state.bloodOxygenHistory.last.spo2}%'
                        : '--',
                items: state.bloodOxygenHistory
                    .map((r) => _MetricItem(value: '${r.spo2}%', time: r.time))
                    .toList(),
                measurementType: MeasurementType.bloodOxygen,
                isMeasuring: _activeMeasurement == MeasurementType.bloodOxygen,
                measureProgress: _measureSeconds / _measureDuration,
                measureRemaining: _measureDuration - _measureSeconds,
                onMeasure: () => _startMeasurement(MeasurementType.bloodOxygen),
                onStop: _stopMeasurement,
              ),
              const SizedBox(height: 16),
              // Blood Pressure
              _MeasurableSection(
                title: 'Blood Pressure',
                icon: Icons.bloodtype_rounded,
                color: AppColors.bloodPressure,
                currentValue: state.liveSystolic != null
                    ? '${state.liveSystolic}/${state.liveDiastolic ?? 0} mmHg'
                    : state.bloodPressureHistory.isNotEmpty
                        ? '${state.bloodPressureHistory.last.systolic}/${state.bloodPressureHistory.last.diastolic} mmHg'
                        : '--',
                items: state.bloodPressureHistory
                    .map((r) => _MetricItem(
                        value: '${r.systolic}/${r.diastolic} mmHg',
                        time: r.time))
                    .toList(),
                measurementType: MeasurementType.bloodPressure,
                isMeasuring:
                    _activeMeasurement == MeasurementType.bloodPressure,
                measureProgress: _measureSeconds / _measureDuration,
                measureRemaining: _measureDuration - _measureSeconds,
                onMeasure: () =>
                    _startMeasurement(MeasurementType.bloodPressure),
                onStop: _stopMeasurement,
              ),
              const SizedBox(height: 16),
              // Temperature
              _MeasurableSection(
                title: 'Temperature',
                icon: Icons.thermostat_rounded,
                color: AppColors.temperature,
                currentValue: state.liveTemperature != null
                    ? '${state.liveTemperature!.toStringAsFixed(1)} °C'
                    : state.temperatureHistory.isNotEmpty
                        ? '${state.temperatureHistory.last.celsius.toStringAsFixed(1)} °C'
                        : '--',
                items: state.temperatureHistory
                    .map((r) => _MetricItem(
                        value: '${r.celsius.toStringAsFixed(1)} °C',
                        time: r.time))
                    .toList(),
                measurementType: MeasurementType.bodyTemperature,
                isMeasuring:
                    _activeMeasurement == MeasurementType.bodyTemperature,
                measureProgress: _measureSeconds / _measureDuration,
                measureRemaining: _measureDuration - _measureSeconds,
                onMeasure: () =>
                    _startMeasurement(MeasurementType.bodyTemperature),
                onStop: _stopMeasurement,
              ),
              const SizedBox(height: 16),
              // Blood Glucose
              _MeasurableSection(
                title: 'Blood Glucose',
                icon: Icons.opacity_rounded,
                color: const Color(0xFFFF8F00),
                currentValue: state.liveBloodGlucose != null
                    ? '${state.liveBloodGlucose!.toStringAsFixed(1)} mmol/L'
                    : '--',
                items: const [],
                measurementType: MeasurementType.bloodGlucose,
                isMeasuring: _activeMeasurement == MeasurementType.bloodGlucose,
                measureProgress: _measureSeconds / _measureDuration,
                measureRemaining: _measureDuration - _measureSeconds,
                onMeasure: () =>
                    _startMeasurement(MeasurementType.bloodGlucose),
                onStop: _stopMeasurement,
              ),
              const SizedBox(height: 16),
              // Stress Level (display-only)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.accentPurple.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.psychology_rounded,
                          color: AppColors.accentPurple, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Stress Level',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600)),
                        Text(
                          state.liveStress != null
                              ? '${state.liveStress}'
                              : '--',
                          style: TextStyle(
                            color: AppColors.accentPurple,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }
}

class _MetricItem {
  final String value;
  final DateTime time;
  _MetricItem({required this.value, required this.time});
}

class _MeasurableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String currentValue;
  final List<_MetricItem> items;
  final MeasurementType measurementType;
  final bool isMeasuring;
  final double measureProgress;
  final int measureRemaining;
  final VoidCallback onMeasure;
  final VoidCallback onStop;

  const _MeasurableSection({
    required this.title,
    required this.icon,
    required this.color,
    required this.currentValue,
    required this.items,
    required this.measurementType,
    required this.isMeasuring,
    required this.measureProgress,
    required this.measureRemaining,
    required this.onMeasure,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    Text(currentValue,
                        style: TextStyle(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Measure button or progress
          if (isMeasuring) ...[
            LinearProgressIndicator(
              value: measureProgress,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${measureRemaining}s remaining',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                GestureDetector(
                  onTap: onStop,
                  child: Text('Stop',
                      style:
                          TextStyle(color: color, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ] else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onMeasure,
                icon: Icon(icon, size: 16),
                label: const Text('Measure'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color.withOpacity(0.4)),
                ),
              ),
            ),
          // History entries
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: AppColors.surfaceLight),
            ...items.reversed.take(5).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text(item.value,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text(
                          '${item.time.hour.toString().padLeft(2, '0')}:${item.time.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
