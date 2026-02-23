import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/ble_provider.dart';
import '../../core/models/health_models.dart';
import '../../shared/theme/app_theme.dart';

class SleepScreen extends ConsumerWidget {
  const SleepScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(sleepHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sleep')),
      body: historyAsync.when(
        data: (records) => records.isEmpty
            ? _buildEmpty()
            : _buildContent(context, records),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.sleep),
        ),
        error: (e, _) => _buildEmpty(),
      ),
    );
  }

  Widget _buildEmpty() => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bedtime_outlined, color: AppColors.sleep, size: 72),
              SizedBox(height: 16),
              Text('No sleep data yet',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Wear your device to bed to track sleep',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );

  Widget _buildContent(BuildContext context, List<SleepRecord> records) {
    final latest = records.last;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Summary card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _SleepSummaryCard(record: latest),
          ),
        ),
        // Stage breakdown
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Sleep Stages', style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _SleepStagesChart(record: latest),
          ),
        ),
        // Stage legend
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SleepLegend(record: latest),
          ),
        ),
        // History list
        if (records.length > 1) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text('History', style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final r = records.reversed.skip(1).toList()[i];
                return _SleepHistoryTile(record: r);
              },
              childCount: (records.length - 1).clamp(0, 7),
            ),
          ),
        ],
      ],
    );
  }
}

class _SleepSummaryCard extends StatelessWidget {
  final SleepRecord record;
  const _SleepSummaryCard({required this.record});

  String _formatDuration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.sleep.withOpacity(0.2),
              AppColors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.sleep.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bedtime_rounded, color: AppColors.sleep, size: 20),
                const SizedBox(width: 8),
                Text(
                  DateFormat('EEE, MMM d').format(record.startTime),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatDuration(record.totalMinutes),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Total Sleep',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${DateFormat('h:mm a').format(record.startTime)} → '
              '${DateFormat('h:mm a').format(record.endTime)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      );
}

class _SleepStagesChart extends StatelessWidget {
  final SleepRecord record;
  const _SleepStagesChart({required this.record});

  @override
  Widget build(BuildContext context) {
    final total = (record.totalMinutes + record.awakeMinutes).toDouble();
    if (total == 0) return const SizedBox.shrink();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: record.deepMinutes.toDouble(),
              color: const Color(0xFF3B82F6),
              title: '${(record.deepMinutes / total * 100).toInt()}%',
              titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              radius: 60,
            ),
            PieChartSectionData(
              value: record.lightMinutes.toDouble(),
              color: AppColors.sleep,
              title: '${(record.lightMinutes / total * 100).toInt()}%',
              titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
              radius: 60,
            ),
            if (record.remMinutes > 0)
              PieChartSectionData(
                value: record.remMinutes.toDouble(),
                color: AppColors.accentPurple,
                title: '${(record.remMinutes / total * 100).toInt()}%',
                titleStyle: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                radius: 60,
              ),
            if (record.awakeMinutes > 0)
              PieChartSectionData(
                value: record.awakeMinutes.toDouble(),
                color: AppColors.textMuted,
                title: '',
                radius: 40,
              ),
          ],
          centerSpaceRadius: 30,
          sectionsSpace: 2,
        ),
      ),
    );
  }
}

class _SleepLegend extends StatelessWidget {
  final SleepRecord record;
  const _SleepLegend({required this.record});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _LegendItem('Deep', '${record.deepMinutes ~/ 60}h ${record.deepMinutes % 60}m', const Color(0xFF3B82F6)),
            _LegendItem('Light', '${record.lightMinutes ~/ 60}h ${record.lightMinutes % 60}m', AppColors.sleep),
            if (record.remMinutes > 0)
              _LegendItem('REM', '${record.remMinutes ~/ 60}h ${record.remMinutes % 60}m', AppColors.accentPurple),
          ],
        ),
      );
}

class _LegendItem extends StatelessWidget {
  final String label, duration;
  final Color color;
  const _LegendItem(this.label, this.duration, this.color);

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 10, height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(label,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(duration,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
        ],
      );
}

class _SleepHistoryTile extends StatelessWidget {
  final SleepRecord record;
  const _SleepHistoryTile({required this.record});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Text(
              DateFormat('EEE, d').format(record.startTime),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const Spacer(),
            Text(
              '${record.totalMinutes ~/ 60}h ${record.totalMinutes % 60}m',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
}
