import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import '../../core/ble/ble_manager.dart';
import '../../core/ble/ble_event_handler.dart';
import '../../core/models/health_models.dart';
import '../../core/providers/ble_provider.dart';

const Color kPrimaryColor = Color(0xFFFF6D3A);
const Color kCardLight = Color(0xFFFFFFFF);
const Color kCardDark = Color(0xFF1C1C1E);
const Color kBackgroundLight = Color(0xFFF9FAFB);
const Color kBackgroundDark = Color(0xFF0F0F0F);
const Color kTealStatus = Color(0xFF2DD4BF);
const Color kGrayText = Color(0xFF9CA3AF);

class HeartRateScreen extends ConsumerStatefulWidget {
  const HeartRateScreen({super.key});

  @override
  ConsumerState<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends ConsumerState<HeartRateScreen> {
  bool _isMeasuring = false;
  String? _progress;
  Timer? _measureTimer;
  String _selectedTab = 'Day';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startRealtime());
  }

  Future<void> _startRealtime() async {
    await BleManager.instance.setRealTimeUpload(true, DeviceRealTimeDataType.combinedData);
  }

  void _startMeasure() async {
    if (_isMeasuring) return;
    bool ok = await BleManager.instance.startMeasure(DeviceAppControlMeasureHealthDataType.heartRate);
    if (!ok) {
      EasyLoading.showError('Failed to start measure');
      return;
    }

    setState(() {
      _isMeasuring = true;
      _progress = '0%';
    });

    int elapsed = 0;
    const totalMs = 45000; // Increased from 15000 to allow the ring measurement to finish
    const interval = 100;

    _measureTimer?.cancel();
    _measureTimer = Timer.periodic(const Duration(milliseconds: interval), (timer) {
      elapsed += interval;
      int percentage = ((elapsed / totalMs) * 100).clamp(1, 100).toInt();

      if (mounted) setState(() => _progress = '$percentage%');

      if (elapsed >= totalMs) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isMeasuring = false;
            _progress = null;
          });
          BleManager.instance.stopMeasure(DeviceAppControlMeasureHealthDataType.heartRate);
          ref.refresh(heartRateHistoryProvider);
        }
      }
    });
  }

  @override
  void dispose() {
    _measureTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    final Color bgColor = isDark ? kBackgroundDark : kBackgroundLight;
    final Color textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final Color cardColor = isDark ? kCardDark : kCardLight;
    
    final historyAsync = ref.watch(heartRateHistoryProvider);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: textColor, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text('HR', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: Icon(Icons.share_outlined, color: textColor, size: 22),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Tabs & Date Row
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: ['Month', 'Week', 'Day'].map((tab) {
                              final isSelected = _selectedTab == tab;
                              return GestureDetector(
                                onTap: () => setState(() => _selectedTab = tab),
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 24),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tab,
                                        style: TextStyle(
                                          color: isSelected ? kPrimaryColor : kGrayText,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                      if (isSelected) 
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          height: 2,
                                          width: 24,
                                          color: kPrimaryColor,
                                        )
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined, color: kPrimaryColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                DateFormat('M/d').format(DateTime.now()),
                                style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),

                    // Chart Section
                    SizedBox(
                      height: 180,
                      child: historyAsync.when(
                        data: (records) => _HRChart(records: records),
                        loading: () => const Center(child: CircularProgressIndicator(color: kPrimaryColor)),
                        error: (_, __) => const Center(child: Text('Chart Error', style: TextStyle(color: kGrayText))),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8).copyWith(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: ['00:00', '06:00', '12:00', '18:00', '24:00']
                            .map((t) => Text(t, style: const TextStyle(color: kGrayText, fontSize: 10, letterSpacing: 1.2)))
                            .toList(),
                      ),
                    ),

                    // Big Real-time Number Section
                    Padding(
                      padding: const EdgeInsets.only(top: 32, bottom: 40),
                      child: ValueListenableBuilder<int?>(
                        valueListenable: BleEventHandler.instance.heartRateNotifier,
                        builder: (context, liveBpm, _) {
                          // Provide a fallback to history if stream is silent (using local variable extraction technique)
                          int fallbackBpm = 0;
                          if (liveBpm == null) {
                            historyAsync.whenData((rec) {
                              if (rec.isNotEmpty) fallbackBpm = rec.last.bpm;
                            });
                          }
                          final activeVal = liveBpm ?? fallbackBpm;

                          return Column(
                            children: [
                              Text(
                                activeVal > 0 ? '$activeVal' : '--',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isMeasuring ? 'LIVE MEASURING $_progress' : 'LIVE BPM',
                                style: const TextStyle(color: kGrayText, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.w500),
                              ),
                            ],
                          );
                        }
                      ),
                    ),

                    // High / Low Stats (Derived from history)
                    historyAsync.when(
                      data: (records) {
                        int highest = records.isEmpty ? 0 : records.map((e) => e.bpm).reduce(max);
                        int lowest = records.isEmpty ? 0 : records.map((e) => e.bpm).reduce(min);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _StatColumn(
                              icon: Icons.arrow_upward_rounded,
                              val: highest,
                              label: 'HIGHEST',
                              textColor: textColor,
                            ),
                            const SizedBox(width: 48),
                            _StatColumn(
                              icon: Icons.arrow_downward_rounded,
                              val: lowest,
                              label: 'LOWEST',
                              textColor: textColor,
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_,__) => const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 32),

                    // Measurement Button
                    ElevatedButton(
                      onPressed: _startMeasure,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        shadowColor: kPrimaryColor.withOpacity(0.4),
                      ),
                      child: Text(
                        _isMeasuring ? 'Measuring... $_progress' : 'Heart rate measurement',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Analysis Card
                    _CardContainer(
                      color: cardColor,
                      child: Row(
                        children: [
                          const Icon(Icons.analytics_outlined, color: kPrimaryColor),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Heart rate analysis', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                              const SizedBox(height: 4),
                              const Text('Your heart rate is normal.', style: TextStyle(color: kGrayText, fontSize: 13)),
                            ],
                          )
                        ],
                      ),
                    ),

                    // Settings Card
                    _CardContainer(
                      color: cardColor,
                      child: Row(
                        children: [
                          const Icon(Icons.settings_outlined, color: kGrayText),
                          const SizedBox(width: 12),
                          Text('Health settings', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                          const Spacer(),
                          const Icon(Icons.chevron_right, color: kGrayText),
                        ],
                      ),
                    ),

                    // History Section
                    _CardContainer(
                      color: cardColor,
                      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 20, right: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.history_outlined, color: kGrayText),
                              const SizedBox(width: 12),
                              Text('history record', style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)),
                              const Spacer(),
                              const Icon(Icons.expand_more, color: kGrayText),
                            ],
                          ),
                          const SizedBox(height: 16),
                          historyAsync.when(
                            data: (records) {
                              if (records.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 16.0),
                                  child: Text('No records for today.', style: TextStyle(color: kGrayText, fontSize: 13)),
                                );
                              }
                              // Sort descending by time
                              final sorted = List.of(records)
                                ..sort((a, b) => b.time.compareTo(a.time));
                              // show up to 5 items to mimic UI
                              return Column(
                                children: sorted.take(5).map((r) => _HistoryRow(record: r, textColor: textColor)).toList(),
                              );
                            },
                            loading: () => const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 2)),
                            ),
                            error: (_,__) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final int val;
  final String label;
  final Color textColor;
  
  const _StatColumn({required this.icon, required this.val, required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: kPrimaryColor, size: 16),
            const SizedBox(width: 4),
            Text('$val', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: kGrayText, fontSize: 10, letterSpacing: 1.2)),
      ],
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  
  const _CardContainer({required this.child, required this.color, this.padding = const EdgeInsets.all(20)});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), offset: const Offset(0, 4), blurRadius: 10),
        ],
      ),
      child: child,
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final HeartRateRecord record;
  final Color textColor;
  const _HistoryRow({required this.record, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: const BoxDecoration(color: kPrimaryColor, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(DateFormat('HH:mm').format(record.time), style: const TextStyle(color: kGrayText, fontWeight: FontWeight.w500, fontSize: 13)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${record.bpm}', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold, height: 1)),
                const SizedBox(width: 4),
                const Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text('bpm', style: TextStyle(color: kGrayText, fontSize: 11)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          const Text('Normal', style: TextStyle(color: kTealStatus, fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }
}

// Chart mimicking the exact SVG shape provided
class _HRChart extends StatelessWidget {
  final List<HeartRateRecord> records;
  const _HRChart({required this.records});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const Center(child: Text('No chart data', style: TextStyle(color: kGrayText)));
    }
    
    // Sort chronologically for charting
    final sorted = List.of(records)..sort((a,b) => a.time.compareTo(b.time));
    
    // Create spots, assuming x is a normalized time of day 0..24
    final spots = sorted.map((r) {
      double timeVal = r.time.hour + (r.time.minute / 60.0);
      return FlSpot(timeVal, r.bpm.toDouble());
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => FlLine(color: kGrayText.withOpacity(0.1), strokeWidth: 1, dashArray: [4, 4]),
        ),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 24, // 0 to 24 hours
        minY: 40,
        maxY: 180,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: kPrimaryColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [kPrimaryColor.withOpacity(0.6), kPrimaryColor.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
