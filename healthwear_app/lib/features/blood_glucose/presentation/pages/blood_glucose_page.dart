import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../dashboard/domain/repositories/health_repository.dart';
import '../../../../core/di/injection_container.dart';

class BloodGlucosePage extends StatefulWidget {
  const BloodGlucosePage({super.key});

  @override
  State<BloodGlucosePage> createState() => _BloodGlucosePageState();
}

class _BloodGlucosePageState extends State<BloodGlucosePage> {
  bool _isMeasuring = false;
  int _measureSeconds = 0;
  Timer? _measureTimer;
  static const int _measureDuration = 45;

  void _startMeasurement() {
    setState(() {
      _isMeasuring = true;
      _measureSeconds = 0;
    });
    sl<HealthRepository>().startMeasurement(MeasurementType.bloodGlucose);
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
    sl<HealthRepository>().stopMeasurement(MeasurementType.bloodGlucose);
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
        title: const Text('Blood Glucose'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final glucose = state.liveBloodGlucose;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Live glucose display
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(colors: [
                            const Color(0xFF81C784).withOpacity(0.2),
                            const Color(0xFF81C784).withOpacity(0.05),
                          ]),
                          border: Border.all(
                              color: const Color(0xFF81C784).withOpacity(0.3),
                              width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.local_hospital_rounded,
                                color: Color(0xFF81C784), size: 32),
                            const SizedBox(height: 4),
                            Text(
                              glucose != null
                                  ? glucose.toStringAsFixed(1)
                                  : '--',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700),
                            ),
                            const Text('mmol/L',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Normal range indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _RangeLabel(
                                label: 'Low',
                                range: '< 3.9',
                                color: const Color(0xFF42A5F5)),
                            _RangeLabel(
                                label: 'Normal',
                                range: '3.9 – 6.1',
                                color: const Color(0xFF66BB6A)),
                            _RangeLabel(
                                label: 'High',
                                range: '> 6.1',
                                color: const Color(0xFFFF5252)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (glucose != null) _StatusBadge(glucose: glucose),
                    ],
                  ),
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
                                const Color(0xFF81C784).withOpacity(0.15),
                            valueColor:
                                const AlwaysStoppedAnimation(Color(0xFF81C784)),
                          ),
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
                          icon: const Icon(Icons.local_hospital_rounded),
                          label: const Text('Measure Blood Glucose'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF81C784),
                              minimumSize: const Size(double.infinity, 48)),
                        ),
                ),
              ),
              // Info card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16)),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About Blood Glucose',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text(
                        'Blood glucose levels indicate how much sugar is in your bloodstream. '
                        'Normal fasting glucose is between 3.9 and 6.1 mmol/L. '
                        'Readings from the wearable use optical sensors and are for reference only.',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }
}

class _RangeLabel extends StatelessWidget {
  final String label, range;
  final Color color;
  const _RangeLabel(
      {required this.label, required this.range, required this.color});

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(range,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ]);
}

class _StatusBadge extends StatelessWidget {
  final double glucose;
  const _StatusBadge({required this.glucose});

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    if (glucose < 3.9) {
      text = 'Low';
      color = const Color(0xFF42A5F5);
    } else if (glucose <= 6.1) {
      text = 'Normal';
      color = const Color(0xFF66BB6A);
    } else {
      text = 'High';
      color = const Color(0xFFFF5252);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 14, fontWeight: FontWeight.w700)),
    );
  }
}
