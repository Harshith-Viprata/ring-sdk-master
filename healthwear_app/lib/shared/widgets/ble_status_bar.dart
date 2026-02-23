import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import '../../core/providers/ble_provider.dart';
import '../../core/ble/ble_manager.dart';
import '../theme/app_theme.dart';

/// Top banner that shows BLE connection status and allows disconnect.
class BleStatusBar extends ConsumerWidget {
  const BleStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bleStateProvider);
    final device = ref.watch(connectedDeviceProvider);
    final isConnected = state == BluetoothState.connected;

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
          _BleIcon(state: state),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isConnected
                      ? (device?.name ?? 'Connected')
                      : _stateLabel(state),
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isConnected && device?.mac != null)
                  Text(
                    device!.mac,
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
              onTap: () async {
                await BleManager.instance.disconnect();
                // Immediately update providers so UI reflects disconnected state
                ref.read(bleStateProvider.notifier).state = BluetoothState.disconnected;
                ref.read(connectedDeviceProvider.notifier).state = null;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
  }

  String _stateLabel(int state) {
    switch (state) {
      case BluetoothState.off: return 'Bluetooth Off';
      case BluetoothState.connected: return 'Connected';
      case BluetoothState.connectFailed: return 'Connection Failed';
      case BluetoothState.disconnected: return 'Not Connected';
      default: return 'Searching...';
    }
  }
}

class _BleIcon extends StatefulWidget {
  final int state;
  const _BleIcon({required this.state});

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
    final isConnected = widget.state == BluetoothState.connected;
    final color = isConnected ? AppColors.accentGreen : AppColors.accentRed;

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
          isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
          color: color,
          size: 18,
        ),
      ),
    );
  }
}
