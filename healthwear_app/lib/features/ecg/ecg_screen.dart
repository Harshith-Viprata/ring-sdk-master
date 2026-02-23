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

class EcgScreen extends ConsumerStatefulWidget {
  const EcgScreen({super.key});

  @override
  ConsumerState<EcgScreen> createState() => _EcgScreenState();
}

class _EcgScreenState extends ConsumerState<EcgScreen> {
  bool _measuring = false;
  Timer? _ecgTimer;
  int _ecgProgress = 0;

  @override
  void dispose() {
    _ecgTimer?.cancel();
    super.dispose();
  }

  Future<void> _startECG() async {
    EasyLoading.show(status: 'Starting ECG...');
    final ok = await BleManager.instance.startECG();
    EasyLoading.dismiss();
    if (ok) {
      ref.read(isECGActiveProvider.notifier).state = true;
      ref.read(ecgPointsProvider.notifier).state = [];
      setState(() {
        _measuring = true;
        _ecgProgress = 0;
      });
      _startTimer();
    } else {
      EasyLoading.showError('Failed to start ECG');
    }
  }

  void _startTimer() {
    _ecgTimer?.cancel();
    int elapsed = 0;
    const totalMs = 30000;
    const intervalMs = 300;

    _ecgTimer = Timer.periodic(const Duration(milliseconds: intervalMs), (timer) {
      elapsed += intervalMs;
      if (mounted) {
        setState(() {
          _ecgProgress = ((elapsed / totalMs) * 100).clamp(0, 100).toInt();
        });
      }

      if (elapsed >= totalMs) {
        timer.cancel();
        if (mounted) {
          _stopECG();
        }
      }
    });
  }

  Future<void> _stopECG() async {
    _ecgTimer?.cancel();
    if (mounted) setState(() => _ecgProgress = 0);
    EasyLoading.show(status: 'Processing...');
    await BleManager.instance.stopECG();
    final result = await BleManager.instance.getECGResult();
    EasyLoading.dismiss();
    ref.read(isECGActiveProvider.notifier).state = false;
    setState(() => _measuring = false);
    if (result != null && mounted) {
      _showResultDialog(result);
    }
  }

  void _showResultDialog(DeviceECGResult result) {
    // Decode qrsType: 0=normal, 1=arrhythmia, 2=tachycardia, 3=bradycardia
    final qrsLabel = const {
      0: 'Normal Sinus Rhythm',
      1: 'Arrhythmia',
      2: 'Tachycardia',
      3: 'Bradycardia',
      4: 'ST Elevation',
    }[result.qrsType] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ECG Results',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.hearRate > 0)
              _ResultRow('Heart Rate', '${result.hearRate} BPM', AppColors.heartRate),
            if (result.hrvNorm != null)
              _ResultRow('HRV Norm', '${result.hrvNorm!.toStringAsFixed(1)}', AppColors.accentGreen),
            if (result.respiratoryRate != null)
              _ResultRow('Respiratory Rate', '${result.respiratoryRate} /min', AppColors.bloodOxygen),
            _ResultRow('QRS Diagnosis', qrsLabel, AppColors.ecg),
            if (result.afFlag)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '⚠️ Atrial Fibrillation detected',
                  style: TextStyle(color: AppColors.accentRed, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final points = ref.watch(ecgPointsProvider);
    final isActive = ref.watch(isECGActiveProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('ECG')),
      body: Column(
        children: [
          // Waveform area
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF001A1A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.ecg.withOpacity(0.3),
                ),
              ),
              child: points.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monitor_heart_outlined,
                            color: AppColors.ecg.withOpacity(0.3),
                            size: 64,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isActive ? 'Recording... $_ecgProgress%' : 'Press Start to measure',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          getDrawingHorizontalLine: (v) =>
                              FlLine(color: AppColors.ecg.withOpacity(0.1), strokeWidth: 1),
                          getDrawingVerticalLine: (v) =>
                              FlLine(color: AppColors.ecg.withOpacity(0.05), strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: points
                                .map((p) =>
                                    FlSpot(p.index.toDouble(), p.filteredValue))
                                .toList(),
                            isCurved: false,
                            color: AppColors.ecg,
                            barWidth: 1.5,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                        minY: -500,
                        maxY: 1000,
                        clipData: const FlClipData.all(),
                      ),
                    ),
            ),
          ),
          // Status + button area
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              children: [
                if (isActive) ...[
                  // Live indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _PulsingDot(),
                      const SizedBox(width: 8),
                      Text(
                        'Recording ECG — Stay still ($_ecgProgress%)',
                        style: const TextStyle(color: AppColors.ecg, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${points.length} data points',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                ],
                ElevatedButton.icon(
                  onPressed: isActive ? _stopECG : _startECG,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? AppColors.accentRed : AppColors.ecg,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(isActive ? Icons.stop_rounded : Icons.play_arrow_rounded),
                  label: Text(isActive ? 'Stop ECG' : 'Start ECG'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Place your finger on the sensor and remain still during measurement',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            color: AppColors.accentRed.withOpacity(0.4 + 0.6 * _c.value),
            shape: BoxShape.circle,
          ),
        ),
      );
}

class _ResultRow extends StatelessWidget {
  final String label, value;
  final Color color;
  const _ResultRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 14, fontWeight: FontWeight.w700)),
          ],
        ),
      );
}
