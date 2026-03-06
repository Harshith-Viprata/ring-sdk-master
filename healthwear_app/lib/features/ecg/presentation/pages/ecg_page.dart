import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../shared/theme/app_theme.dart';
import '../bloc/ecg_bloc.dart';

class EcgPage extends StatelessWidget {
  const EcgPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('ECG Measurement'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            context.read<EcgBloc>().add(StopEcgMeasurement());
            Navigator.pop(context);
          },
        ),
      ),
      body: BlocBuilder<EcgBloc, EcgState>(
        builder: (context, state) {
          return Column(
            children: [
              // Waveform area
              Expanded(
                flex: 3,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.ecg.withOpacity(0.3),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: state.waveformData.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.monitor_heart_rounded,
                                    color: AppColors.ecg.withOpacity(0.5),
                                    size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  state.status == EcgStatus.measuring
                                      ? 'Waiting for ECG signal…\nPlace finger on electrode'
                                      : 'Press Start to begin',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : CustomPaint(
                            painter: _EcgWaveformPainter(
                              data: state.waveformData,
                              color: AppColors.ecg,
                            ),
                            size: Size.infinite,
                          ),
                  ),
                ),
              ),
              // Info chips row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _InfoChip(
                      label: 'Heart Rate',
                      value: state.heartRate != null
                          ? '${state.heartRate} BPM'
                          : '-- BPM',
                      color: AppColors.heartRate,
                    ),
                    _InfoChip(
                      label: 'HRV',
                      value: state.hrvNorm != null
                          ? '${state.hrvNorm!.toStringAsFixed(1)}'
                          : '--',
                      color: const Color(0xFF7E57C2),
                    ),
                    _InfoChip(
                      label: 'Duration',
                      value: _formatDuration(state.elapsedSeconds),
                      color: AppColors.accent,
                    ),
                    _InfoChip(
                      label: 'Status',
                      value: _statusText(state.status),
                      color: _statusColor(state.status),
                    ),
                    if (state.respiratoryRate != null)
                      _InfoChip(
                        label: 'Resp Rate',
                        value: '${state.respiratoryRate} /min',
                        color: const Color(0xFF26A69A),
                      ),
                    if (state.afFlag == true)
                      const _InfoChip(
                        label: 'AF Detected',
                        value: '⚠ Yes',
                        color: Color(0xFFFF5252),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Error message
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    state.errorMessage!,
                    style:
                        const TextStyle(color: Color(0xFFFF5252), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Start/Stop button
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final bloc = context.read<EcgBloc>();
                      if (state.status == EcgStatus.measuring) {
                        bloc.add(StopEcgMeasurement());
                      } else {
                        bloc.add(StartEcgMeasurement());
                      }
                    },
                    icon: Icon(state.status == EcgStatus.measuring
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded),
                    label: Text(
                      state.status == EcgStatus.measuring
                          ? 'Stop ECG'
                          : 'Start ECG',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: state.status == EcgStatus.measuring
                          ? AppColors.accentRed
                          : AppColors.ecg,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _statusText(EcgStatus s) {
    switch (s) {
      case EcgStatus.idle:
        return 'Ready';
      case EcgStatus.measuring:
        return 'Measuring';
      case EcgStatus.completed:
        return 'Done';
      case EcgStatus.error:
        return 'Error';
    }
  }

  Color _statusColor(EcgStatus s) {
    switch (s) {
      case EcgStatus.idle:
        return AppColors.textMuted;
      case EcgStatus.measuring:
        return AppColors.accentGreen;
      case EcgStatus.completed:
        return AppColors.accent;
      case EcgStatus.error:
        return AppColors.accentRed;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EcgWaveformPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _EcgWaveformPainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    final dx = size.width / (data.length - 1).clamp(1, data.length);
    final midY = size.height / 2;

    // Normalize data to fit in view
    final maxVal = data
        .fold<double>(0, (m, v) => v.abs() > m ? v.abs() : m)
        .clamp(1.0, double.infinity);
    final scale = size.height * 0.4 / maxVal;

    for (int i = 0; i < data.length; i++) {
      final x = i * dx;
      final y = midY - data[i] * scale;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Draw grid lines
    final gridPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 0.5;

    for (int i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EcgWaveformPainter old) => true;
}
