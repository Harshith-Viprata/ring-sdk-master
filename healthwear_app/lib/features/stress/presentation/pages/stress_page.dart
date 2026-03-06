import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_theme.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';

class StressPage extends StatelessWidget {
  const StressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Stress Level'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final stress = state.liveStress;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Live stress display
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
                            const Color(0xFFBA68C8).withOpacity(0.2),
                            const Color(0xFFBA68C8).withOpacity(0.05),
                          ]),
                          border: Border.all(
                              color: const Color(0xFFBA68C8).withOpacity(0.3),
                              width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.psychology_rounded,
                                color: Color(0xFFBA68C8), size: 32),
                            const SizedBox(height: 4),
                            Text(
                              stress != null ? '$stress' : '--',
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w700),
                            ),
                            const Text('Level',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Stress level interpretation
                      if (stress != null) _StressLevelBar(stress: stress),
                    ],
                  ),
                ),
              ),
              // Stress zones guide
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Stress Zones',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      _StressZoneItem(
                          label: 'Relaxed',
                          range: '1 – 29',
                          color: const Color(0xFF66BB6A)),
                      _StressZoneItem(
                          label: 'Normal',
                          range: '30 – 59',
                          color: const Color(0xFFFFA726)),
                      _StressZoneItem(
                          label: 'Medium',
                          range: '60 – 79',
                          color: const Color(0xFFFF7043)),
                      _StressZoneItem(
                          label: 'High',
                          range: '80 – 100',
                          color: const Color(0xFFEF5350)),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              // Info
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
                      Text('About Stress Monitoring',
                          style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                      SizedBox(height: 8),
                      Text(
                        'Stress levels are estimated using Heart Rate Variability (HRV) data from the ring sensor. '
                        'Higher variability indicates lower stress. This is a passive measurement that updates periodically '
                        'when real-time monitoring is active.',
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

class _StressLevelBar extends StatelessWidget {
  final int stress;
  const _StressLevelBar({required this.stress});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    if (stress < 30) {
      label = 'Relaxed';
      color = const Color(0xFF66BB6A);
    } else if (stress < 60) {
      label = 'Normal';
      color = const Color(0xFFFFA726);
    } else if (stress < 80) {
      label = 'Medium';
      color = const Color(0xFFFF7043);
    } else {
      label = 'High';
      color = const Color(0xFFEF5350);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          child: Text(label,
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          height: 8,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: stress / 100,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ),
      ],
    );
  }
}

class _StressZoneItem extends StatelessWidget {
  final String label, range;
  final Color color;
  const _StressZoneItem(
      {required this.label, required this.range, required this.color});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3))),
          const SizedBox(width: 12),
          Text(label,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
          const Spacer(),
          Text(range,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ]),
      );
}
