import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/device/presentation/bloc/device_bloc.dart';
import '../theme/app_theme.dart';

/// Top banner showing BLE connection status with disconnect button.
class BleStatusBar extends StatelessWidget {
  const BleStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceBloc, DeviceState>(
      builder: (context, state) {
        final isConnected = state.status == DeviceConnectionStatus.connected;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isConnected
                ? AppColors.accentGreen.withOpacity(0.12)
                : AppColors.accentRed.withOpacity(0.1),
            border: Border(
              bottom: BorderSide(
                color: isConnected
                    ? AppColors.accentGreen.withOpacity(0.3)
                    : AppColors.accentRed.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              _BleIcon(isConnected: isConnected),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isConnected
                          ? (state.deviceName ?? 'Connected')
                          : _statusLabel(state.status),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isConnected && state.macAddress != null)
                      Text(
                        state.macAddress!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              if (state.batteryPercent > 0)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _batteryIcon(state.batteryPercent),
                        color: AppColors.accentGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${state.batteryPercent}%',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              if (isConnected)
                GestureDetector(
                  onTap: () =>
                      context.read<DeviceBloc>().add(DisconnectDevice()),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.accentRed.withOpacity(0.3),
                      ),
                    ),
                    child: const Text(
                      'Disconnect',
                      style: TextStyle(
                        color: AppColors.accentRed,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _statusLabel(DeviceConnectionStatus s) {
    switch (s) {
      case DeviceConnectionStatus.scanning:
        return 'Scanning…';
      case DeviceConnectionStatus.connecting:
        return 'Connecting…';
      case DeviceConnectionStatus.connected:
        return 'Connected';
      case DeviceConnectionStatus.disconnected:
        return 'Not Connected';
    }
  }

  IconData _batteryIcon(int percent) {
    if (percent > 80) return Icons.battery_full;
    if (percent > 50) return Icons.battery_5_bar;
    if (percent > 20) return Icons.battery_3_bar;
    return Icons.battery_1_bar;
  }
}

class _BleIcon extends StatefulWidget {
  final bool isConnected;
  const _BleIcon({required this.isConnected});

  @override
  State<_BleIcon> createState() => _BleIconState();
}

class _BleIconState extends State<_BleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _pulse = Tween(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isConnected ? AppColors.accentGreen : AppColors.accentRed;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.15 * _pulse.value),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Icon(
          widget.isConnected
              ? Icons.bluetooth_connected
              : Icons.bluetooth_disabled,
          color: color,
          size: 18,
        ),
      ),
    );
  }
}
