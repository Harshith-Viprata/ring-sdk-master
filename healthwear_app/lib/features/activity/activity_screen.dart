import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/ble_provider.dart';
import '../../core/models/health_models.dart';
import '../../shared/theme/app_theme.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveSteps = ref.watch(stepsProvider);
    final historyAsync = ref.watch(stepHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Activity')),
      body: historyAsync.when(
        data: (records) => _buildBody(context, liveSteps, records),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.steps),
        ),
        error: (e, _) => _buildBody(context, liveSteps, []),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    RealTimeSteps? live,
    List<StepRecord> records,
  ) {
    final totalSteps = live?.steps ?? (records.isNotEmpty ? records.last.steps : 0);
    final goal = 10000;
    final progress = (totalSteps / goal).clamp(0.0, 1.0);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Progress ring card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _StepProgressCard(
              steps: totalSteps,
              goal: goal,
              progress: progress,
              calories: live?.calories ?? 0,
              distance: live?.distanceKm ?? 0,
            ),
          ),
        ),
        // Weekly bar chart
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('This Week',
                style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _WeeklyBarsChart(records: records),
          ),
        ),
      ],
    );
  }
}

class _StepProgressCard extends StatelessWidget {
  final int steps, goal, calories;
  final double progress, distance;
  const _StepProgressCard({
    required this.steps,
    required this.goal,
    required this.progress,
    required this.calories,
    required this.distance,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.steps.withOpacity(0.2),
              AppColors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.steps.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: const AlwaysStoppedAnimation(AppColors.steps),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$steps',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Text(
                      'steps',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    Text(
                      '/ $goal',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _MiniStat(
                  icon: Icons.local_fire_department_rounded,
                  value: '$calories',
                  label: 'kcal',
                  color: AppColors.accentOrange,
                ),
                _MiniStat(
                  icon: Icons.route_rounded,
                  value: distance.toStringAsFixed(2),
                  label: 'km',
                  color: AppColors.bloodOxygen,
                ),
                _MiniStat(
                  icon: Icons.flag_rounded,
                  value: '${(progress * 100).toInt()}%',
                  label: 'goal',
                  color: AppColors.steps,
                ),
              ],
            ),
          ],
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _MiniStat({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style:
                  const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      );
}

class _WeeklyBarsChart extends StatelessWidget {
  final List<StepRecord> records;
  const _WeeklyBarsChart({required this.records});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final last7 = records.length >= 7
        ? records.sublist(records.length - 7)
        : List<StepRecord?>.filled(7, null)
          ..setAll(7 - records.length, records);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) => Text(
                  days[v.toInt()],
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ),
            ),
          ),
          barGroups: List.generate(7, (i) {
            final record = last7[i];
            final steps = record?.steps.toDouble() ?? 0;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: steps == 0 ? 200 : steps,
                  gradient: LinearGradient(
                    colors: steps == 0
                        ? [AppColors.surfaceLight, AppColors.surfaceLight]
                        : [AppColors.steps, AppColors.accentGreen],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
