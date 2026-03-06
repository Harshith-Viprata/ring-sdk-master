import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/domain/entities/health_data.dart';

class SleepPage extends StatelessWidget {
  const SleepPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            expandedHeight: 100,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 0, 14),
              title: const Text(
                'Sleep',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<DashboardBloc, DashboardState>(
              builder: (context, state) {
                final sleepHistory = state.sleepHistory;

                if (sleepHistory.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(Icons.bedtime_rounded,
                            color: AppColors.sleep.withOpacity(0.4), size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'No sleep data yet',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Wear your device to bed to track\nyour sleep patterns',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                final latest = sleepHistory.last;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ── Sleep Summary Card ──────────────────────
                      _SleepSummaryCard(record: latest),
                      const SizedBox(height: 16),

                      // ── Pie Chart ──────────────────────────────
                      _SleepPieChart(record: latest),
                      const SizedBox(height: 16),

                      // ── Sleep Stage Legend ─────────────────────
                      _StageLegend(record: latest),
                      const SizedBox(height: 20),

                      // ── History List ───────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'History (${sleepHistory.length} nights)',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            ...sleepHistory.reversed.take(7).map(
                                  (r) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Text(
                                          _formatDate(r.startTime),
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13),
                                        ),
                                        const Spacer(),
                                        Text(
                                          _formatDuration(r.totalMinutes),
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';

  String _formatDuration(int totalMinutes) {
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return '${h}h ${m}m';
  }
}

class _SleepSummaryCard extends StatelessWidget {
  final SleepRecord record;
  const _SleepSummaryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final totalH = record.totalMinutes ~/ 60;
    final totalM = record.totalMinutes % 60;
    final startStr =
        '${record.startTime.hour.toString().padLeft(2, '0')}:${record.startTime.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${record.endTime.hour.toString().padLeft(2, '0')}:${record.endTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.sleep.withOpacity(0.15),
            AppColors.sleep.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.sleep.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          const Icon(Icons.bedtime_rounded, color: AppColors.sleep, size: 32),
          const SizedBox(height: 8),
          Text(
            '${totalH}h ${totalM}m',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$startStr → $endStr',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SleepPieChart extends StatelessWidget {
  final SleepRecord record;
  const _SleepPieChart({required this.record});

  @override
  Widget build(BuildContext context) {
    final total = record.deepMinutes +
        record.lightMinutes +
        record.remMinutes +
        record.awakeMinutes;
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: [
            PieChartSectionData(
              value: record.deepMinutes.toDouble(),
              title: '${(record.deepMinutes / total * 100).round()}%',
              color: const Color(0xFF3949AB),
              radius: 50,
              titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
            PieChartSectionData(
              value: record.lightMinutes.toDouble(),
              title: '${(record.lightMinutes / total * 100).round()}%',
              color: const Color(0xFF42A5F5),
              radius: 50,
              titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
            PieChartSectionData(
              value: record.remMinutes.toDouble(),
              title: '${(record.remMinutes / total * 100).round()}%',
              color: const Color(0xFF7E57C2),
              radius: 50,
              titleStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
            if (record.awakeMinutes > 0)
              PieChartSectionData(
                value: record.awakeMinutes.toDouble(),
                title: '${(record.awakeMinutes / total * 100).round()}%',
                color: const Color(0xFFFF7043),
                radius: 50,
                titleStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
              ),
          ],
        ),
      ),
    );
  }
}

class _StageLegend extends StatelessWidget {
  final SleepRecord record;
  const _StageLegend({required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _LegendRow(
              color: const Color(0xFF3949AB),
              label: 'Deep Sleep',
              minutes: record.deepMinutes),
          const SizedBox(height: 8),
          _LegendRow(
              color: const Color(0xFF42A5F5),
              label: 'Light Sleep',
              minutes: record.lightMinutes),
          const SizedBox(height: 8),
          _LegendRow(
              color: const Color(0xFF7E57C2),
              label: 'REM',
              minutes: record.remMinutes),
          const SizedBox(height: 8),
          _LegendRow(
              color: const Color(0xFFFF7043),
              label: 'Awake',
              minutes: record.awakeMinutes),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int minutes;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(label,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          const Spacer(),
          Text(
            '${minutes ~/ 60}h ${minutes % 60}m',
            style: TextStyle(
                color: color, fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      );
}
