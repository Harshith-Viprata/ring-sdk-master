import 'dart:async';
import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/ble/ble_event_handler.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/domain/repositories/health_repository.dart';
import '../../../../core/di/injection_container.dart';

class HeartRatePage extends StatefulWidget {
  const HeartRatePage({super.key});

  @override
  State<HeartRatePage> createState() => _HeartRatePageState();
}

class _HeartRatePageState extends State<HeartRatePage> {
  bool _isMeasuring = false;
  int _measureSeconds = 0;
  Timer? _measureTimer;
  static const int _measureDuration = 45;

  void _startMeasurement() {
    setState(() {
      _isMeasuring = true;
      _measureSeconds = 0;
    });
    sl<HealthRepository>().startMeasurement(MeasurementType.heartRate);
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
    sl<HealthRepository>().stopMeasurement(MeasurementType.heartRate);
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
        title: const Text('Heart Rate'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final history = state.heartRateHistory;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Live BPM display with ValueListenableBuilder
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      ValueListenableBuilder<int?>(
                        valueListenable:
                            BleEventHandler.instance.heartRateNotifier,
                        builder: (context, liveBpm, _) {
                          final bpm = liveBpm ?? state.latestHeartRate;
                          return Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppColors.heartRate.withOpacity(0.2),
                                  AppColors.heartRate.withOpacity(0.05),
                                ],
                              ),
                              border: Border.all(
                                color: AppColors.heartRate.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.favorite_rounded,
                                    color: AppColors.heartRate, size: 32),
                                const SizedBox(height: 4),
                                Text(
                                  bpm != null ? '$bpm' : '--',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 40,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const Text(
                                  'BPM',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Stats row
                      if (history.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _StatChip(
                              label: 'Highest',
                              value: '${history.map((r) => r.bpm).reduce(max)}',
                              color: const Color(0xFFFF5252),
                            ),
                            _StatChip(
                              label: 'Lowest',
                              value: '${history.map((r) => r.bpm).reduce(min)}',
                              color: const Color(0xFF66BB6A),
                            ),
                            _StatChip(
                              label: 'Average',
                              value:
                                  '${(history.map((r) => r.bpm).reduce((a, b) => a + b) / history.length).round()}',
                              color: AppColors.accent,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              // 24h LineChart
              if (history.isNotEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: history
                                .asMap()
                                .entries
                                .map((e) => FlSpot(
                                    e.key.toDouble(), e.value.bpm.toDouble()))
                                .toList(),
                            isCurved: true,
                            color: AppColors.heartRate,
                            barWidth: 2,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.heartRate.withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              // On-demand measurement button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _isMeasuring
                      ? Column(
                          children: [
                            LinearProgressIndicator(
                              value: _measureSeconds / _measureDuration,
                              backgroundColor:
                                  AppColors.heartRate.withOpacity(0.15),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.heartRate),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_measureDuration - _measureSeconds}s remaining',
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: _stopMeasurement,
                              child: const Text('Stop'),
                            ),
                          ],
                        )
                      : ElevatedButton.icon(
                          onPressed: _startMeasurement,
                          icon: const Icon(Icons.favorite_rounded),
                          label: const Text('Measure Heart Rate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.heartRate,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                ),
              ),
              // History list
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'History (${history.length} records)',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (history.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No heart rate data yet',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final record =
                          history[history.length - 1 - index]; // reverse
                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.favorite_rounded,
                                color: AppColors.heartRate, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              '${record.bpm} BPM',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _formatTime(record.time),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: history.length,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      );
}
