import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/domain/repositories/health_repository.dart';
import '../../../../core/di/injection_container.dart';

class BloodPressurePage extends StatefulWidget {
  const BloodPressurePage({super.key});

  @override
  State<BloodPressurePage> createState() => _BloodPressurePageState();
}

class _BloodPressurePageState extends State<BloodPressurePage> {
  bool _isMeasuring = false;
  int _measureSeconds = 0;
  Timer? _measureTimer;
  static const int _measureDuration = 45;

  void _startMeasurement() {
    setState(() {
      _isMeasuring = true;
      _measureSeconds = 0;
    });
    sl<HealthRepository>().startMeasurement(MeasurementType.bloodPressure);
    _measureTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_measureSeconds >= _measureDuration) {
        _stopMeasurement();
      } else {
        setState(() => _measureSeconds++);
      }
    });
  }

  void _stopMeasurement() {
    _measureTimer?.cancel();
    sl<HealthRepository>().stopMeasurement(MeasurementType.bloodPressure);
    setState(() {
      _isMeasuring = false;
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
        title: const Text('Blood Pressure'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final history = state.bloodPressureHistory;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Live BP display
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            AppColors.bloodPressure.withOpacity(0.2),
                            AppColors.bloodPressure.withOpacity(0.05),
                          ]),
                          border: Border.all(
                              color: AppColors.bloodPressure.withOpacity(0.3),
                              width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.bloodtype_rounded,
                                color: AppColors.bloodPressure, size: 28),
                            const SizedBox(height: 4),
                            Text(
                              state.liveSystolic != null
                                  ? '${state.liveSystolic}/${state.liveDiastolic ?? 0}'
                                  : (history.isNotEmpty
                                      ? '${history.last.systolic}/${history.last.diastolic}'
                                      : '--/--'),
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700),
                            ),
                            const Text('mmHg',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (history.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _BpStat(
                                label: 'Avg SYS',
                                value:
                                    '${(history.map((r) => r.systolic).reduce((a, b) => a + b) / history.length).round()}',
                                color: const Color(0xFFFF5252)),
                            _BpStat(
                                label: 'Avg DIA',
                                value:
                                    '${(history.map((r) => r.diastolic).reduce((a, b) => a + b) / history.length).round()}',
                                color: const Color(0xFF42A5F5)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              // Chart — dual lines for systolic/diastolic
              if (history.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16)),
                    height: 200,
                    child: LineChart(LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: history
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(),
                                  e.value.systolic.toDouble()))
                              .toList(),
                          isCurved: true,
                          color: const Color(0xFFFF5252),
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                        ),
                        LineChartBarData(
                          spots: history
                              .asMap()
                              .entries
                              .map((e) => FlSpot(e.key.toDouble(),
                                  e.value.diastolic.toDouble()))
                              .toList(),
                          isCurved: true,
                          color: const Color(0xFF42A5F5),
                          barWidth: 2,
                          dotData: FlDotData(show: false),
                        ),
                      ],
                    )),
                  ),
                ),
              // Measure button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isMeasuring
                      ? Column(children: [
                          LinearProgressIndicator(
                              value: _measureSeconds / _measureDuration,
                              backgroundColor:
                                  AppColors.bloodPressure.withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.bloodPressure)),
                          const SizedBox(height: 8),
                          Text(
                              '${_measureDuration - _measureSeconds}s remaining',
                              style: const TextStyle(
                                  color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          OutlinedButton(
                              onPressed: _stopMeasurement,
                              child: const Text('Stop')),
                        ])
                      : ElevatedButton.icon(
                          onPressed: _startMeasurement,
                          icon: const Icon(Icons.bloodtype_rounded),
                          label: const Text('Measure Blood Pressure'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.bloodPressure,
                              minimumSize: const Size(double.infinity, 48)),
                        ),
                ),
              ),
              // History
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text('History (${history.length} records)',
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              if (history.isEmpty)
                const SliverFillRemaining(
                    child: Center(
                        child: Text('No blood pressure data yet',
                            style: TextStyle(color: AppColors.textMuted))))
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final record = history[history.length - 1 - index];
                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.bloodtype_rounded,
                            color: AppColors.bloodPressure, size: 20),
                        const SizedBox(width: 12),
                        Text('${record.systolic}/${record.diastolic} mmHg',
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text(
                            '${record.time.hour.toString().padLeft(2, '0')}:${record.time.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                      ]),
                    );
                  }, childCount: history.length),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _BpStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _BpStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 22, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ]);
}
