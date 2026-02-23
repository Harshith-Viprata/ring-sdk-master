import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import '../../core/ble/ble_manager.dart';
import '../../core/providers/ble_provider.dart';
import '../../core/models/health_models.dart';
import '../../shared/theme/app_theme.dart';

class HeartRateScreen extends ConsumerStatefulWidget {
  const HeartRateScreen({super.key});

  @override
  ConsumerState<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends ConsumerState<HeartRateScreen> {
  bool _realTimeActive = false;
  String? _progress;
  Timer? _measureTimer;

  @override
  void initState() {
    super.initState();
    // Start real-time HR upload
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRealtime());
  }

  Future<void> _startRealtime() async {
    await BleManager.instance
        .setRealTimeUpload(true, DeviceRealTimeDataType.heartRate);
    setState(() => _realTimeActive = true);
  }

  void _startMeasure() async {
    if (_progress != null) return;
    bool ok = await BleManager.instance.startMeasure(DeviceAppControlMeasureHealthDataType.heartRate);
    if (!ok) {
      EasyLoading.showError('Failed to start');
      return;
    }

    setState(() => _progress = '1%');
    int elapsed = 0;
    const totalMs = 15000;
    const interval = 100;

    _measureTimer?.cancel();
    _measureTimer = Timer.periodic(const Duration(milliseconds: interval), (timer) {
      elapsed += interval;
      int percentage = ((elapsed / totalMs) * 100).clamp(1, 100).toInt();

      if (mounted) {
        setState(() => _progress = '$percentage%');
      }

      if (elapsed >= totalMs) {
        timer.cancel();
        if (mounted) {
          setState(() => _progress = null);
          BleManager.instance.stopMeasure(DeviceAppControlMeasureHealthDataType.heartRate);
          // Explicitly refresh history provider to capture newly saved result
          ref.refresh(heartRateHistoryProvider);
        }
      }
    });
  }

  @override
  void dispose() {
    _measureTimer?.cancel();
    BleManager.instance.setRealTimeUpload(false, DeviceRealTimeDataType.heartRate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final liveHr = ref.watch(heartRateProvider);
    final historyAsync = ref.watch(heartRateHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Heart Rate'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: _realTimeActive ? AppColors.accentGreen : AppColors.textMuted,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _realTimeActive ? 'Live' : 'Offline',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Live HR card at top
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _LiveHRCard(
                bpm: liveHr?.bpm,
                progress: _progress,
                onMeasure: _startMeasure,
              ),
            ),
          ),
          // History chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Today\'s History',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: historyAsync.when(
                data: (records) => _HRChart(records: records),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.heartRate),
                  ),
                ),
                error: (e, _) => Center(
                  child: Text('Failed to load history',
                      style: const TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ),
          ),
          // Stats row
          SliverToBoxAdapter(
            child: historyAsync.when(
              data: (records) => records.isNotEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _HRStats(records: records),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveHRCard extends StatelessWidget {
  final int? bpm;
  final String? progress;
  final VoidCallback? onMeasure;

  const _LiveHRCard({this.bpm, this.progress, this.onMeasure});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.heartRate.withOpacity(0.2),
              AppColors.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.heartRate.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      bpm != null ? '$bpm' : '--',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 64,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 10, left: 6),
                      child: Text(
                        'BPM',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Heart Rate',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: progress != null ? null : onMeasure,
                  icon: progress != null
                      ? const SizedBox(
                          width: 16, height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                        )
                      : const Icon(Icons.favorite_outline),
                  label: Text(progress ?? 'Measure Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.heartRate.withOpacity(0.2),
                    foregroundColor: AppColors.heartRate,
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const Spacer(),
            _HeartbeatIcon(active: bpm != null || progress != null),
          ],
        ),
      );
}

class _HeartbeatIcon extends StatefulWidget {
  final bool active;
  const _HeartbeatIcon({required this.active});

  @override
  State<_HeartbeatIcon> createState() => _HeartbeatIconState();
}

class _HeartbeatIconState extends State<_HeartbeatIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);
    _scale = Tween(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _scale,
        builder: (_, __) => Transform.scale(
          scale: widget.active ? _scale.value : 1.0,
          child: Icon(
            Icons.favorite_rounded,
            color: widget.active ? AppColors.heartRate : AppColors.textMuted,
            size: 72,
          ),
        ),
      );
}

class _HRChart extends StatelessWidget {
  final List<HeartRateRecord> records;
  const _HRChart({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'No data recorded today',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final spots = records.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.bpm.toDouble());
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: AppColors.surfaceLight,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.heartRate,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.heartRate.withOpacity(0.25),
                    AppColors.heartRate.withOpacity(0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HRStats extends StatelessWidget {
  final List<HeartRateRecord> records;
  const _HRStats({required this.records});

  @override
  Widget build(BuildContext context) {
    final bpms = records.map((r) => r.bpm).toList();
    final avg = (bpms.reduce((a, b) => a + b) / bpms.length).round();
    final min = bpms.reduce((a, b) => a < b ? a : b);
    final max = bpms.reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _StatItem(label: 'Min', value: '$min', unit: 'BPM', color: AppColors.bloodOxygen),
          Expanded(child: _StatItem(label: 'Avg', value: '$avg', unit: 'BPM', color: AppColors.heartRate)),
          _StatItem(label: 'Max', value: '$max', unit: 'BPM', color: AppColors.accentRed),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label, value, unit;
  final Color color;
  const _StatItem({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 24, fontWeight: FontWeight.w700)),
            Text(unit,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
      );
}
