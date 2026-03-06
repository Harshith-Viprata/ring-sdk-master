import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

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
                'Activity',
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
                final steps = state.todaySteps;
                final calories = state.todayCalories;
                final distance = state.todayDistance;
                const goal = 10000;
                final progress = (steps / goal).clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ── Circular Progress Ring ──────────────
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.steps.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              width: 180,
                              height: 180,
                              child: CustomPaint(
                                painter: _CircularProgressPainter(
                                  progress: progress,
                                  color: AppColors.steps,
                                  bgColor: AppColors.steps.withOpacity(0.1),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.directions_walk_rounded,
                                          color: AppColors.steps, size: 28),
                                      const SizedBox(height: 4),
                                      Text(
                                        '$steps',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        '/ $goal steps',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _StatColumn(
                                  icon: Icons.local_fire_department_rounded,
                                  value: '$calories',
                                  label: 'Calories',
                                  color: const Color(0xFFFF5722),
                                ),
                                _StatColumn(
                                  icon: Icons.straighten_rounded,
                                  value: '${distance.toStringAsFixed(1)} km',
                                  label: 'Distance',
                                  color: const Color(0xFF2196F3),
                                ),
                                _StatColumn(
                                  icon: Icons.flag_rounded,
                                  value:
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                  label: 'Goal',
                                  color: AppColors.steps,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── Weekly Bar Chart ───────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Weekly Steps',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 180,
                              child: _buildWeeklyChart(state),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // ── History list ───────────────────────
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
                              'History (${state.stepHistory.length} days)',
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            if (state.stepHistory.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No step data yet',
                                    style:
                                        TextStyle(color: AppColors.textMuted)),
                              )
                            else
                              ...state.stepHistory.reversed.take(7).map((r) =>
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Text(
                                          _formatDate(r.date),
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${r.steps} steps',
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
                                    ),
                                  )),
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

  Widget _buildWeeklyChart(DashboardState state) {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final barGroups = <BarChartGroupData>[];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      int stepsForDay = 0;
      for (final r in state.stepHistory) {
        if (r.date.year == day.year &&
            r.date.month == day.month &&
            r.date.day == day.day) {
          stepsForDay += r.steps;
        }
      }
      barGroups.add(
        BarChartGroupData(
          x: 6 - i,
          barRods: [
            BarChartRodData(
              toY: stepsForDay.toDouble(),
              color: AppColors.steps,
              width: 16,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, _) {
                final dayIdx =
                    (now.subtract(Duration(days: 6 - value.toInt())).weekday -
                            1) %
                        7;
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(days[dayIdx],
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
                );
              },
            ),
          ),
        ),
        barGroups: barGroups,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color bgColor;

  _CircularProgressPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;
    const strokeWidth = 12.0;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 16, fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      );
}
