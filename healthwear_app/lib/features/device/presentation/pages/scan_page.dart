import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';
import '../bloc/device_bloc.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  @override
  void initState() {
    super.initState();
    // Start scanning automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DeviceBloc>().add(const StartScan());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Connect Device'),
      ),
      body: BlocConsumer<DeviceBloc, DeviceState>(
        listener: (context, state) {
          if (state.status == DeviceConnectionStatus.connected) {
            // Pop back to dashboard on successful connection
            if (context.canPop()) context.pop();
          }
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: AppColors.accentRed,
              ),
            );
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Scan status header
              _ScanHeader(state: state),
              // Device list
              Expanded(
                child: state.status == DeviceConnectionStatus.scanning
                    ? _ScanningView()
                    : state.discoveredDevices.isEmpty
                        ? _EmptyScanView(
                            onRescan: () => context
                                .read<DeviceBloc>()
                                .add(const StartScan()),
                          )
                        : _DeviceListView(
                            devices: state.discoveredDevices,
                            onConnect: (device) => context
                                .read<DeviceBloc>()
                                .add(ConnectToDevice(device)),
                            onRescan: () => context
                                .read<DeviceBloc>()
                                .add(const StartScan()),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ScanHeader extends StatelessWidget {
  final DeviceState state;
  const _ScanHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    final isScanning = state.status == DeviceConnectionStatus.scanning;
    final isConnecting = state.status == DeviceConnectionStatus.connecting;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          if (isScanning || isConnecting)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          if (isScanning || isConnecting) const SizedBox(width: 12),
          Text(
            isScanning
                ? 'Scanning for devices…'
                : isConnecting
                    ? 'Connecting…'
                    : '${state.discoveredDevices.length} device(s) found',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanningView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation(
                AppColors.accent.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Searching nearby devices…',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

class _EmptyScanView extends StatelessWidget {
  final VoidCallback onRescan;
  const _EmptyScanView({required this.onRescan});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.bluetooth_searching_rounded,
            color: AppColors.textMuted,
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No devices found',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Make sure your device is nearby\nand Bluetooth is enabled',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRescan,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Scan Again'),
          ),
        ],
      ),
    );
  }
}

class _DeviceListView extends StatelessWidget {
  final List<dynamic> devices;
  final void Function(dynamic device) onConnect;
  final VoidCallback onRescan;

  const _DeviceListView({
    required this.devices,
    required this.onConnect,
    required this.onRescan,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: devices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final device = devices[index];
              final name = device.name ?? 'Unknown Device';
              final mac = device.macAddress ?? '';
              final rssi = device.rssiValue ?? 0;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.surfaceLight,
                  ),
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.watch_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    mac,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _rssiIcon(rssi),
                        color: _rssiColor(rssi),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                  onTap: () => onConnect(device),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onRescan,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: BorderSide(color: AppColors.accent.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _rssiIcon(int rssi) {
    final abs = rssi.abs();
    if (abs < 60) return Icons.signal_cellular_alt;
    if (abs < 80) return Icons.signal_cellular_alt_2_bar;
    return Icons.signal_cellular_alt_1_bar;
  }

  Color _rssiColor(int rssi) {
    final abs = rssi.abs();
    if (abs < 60) return AppColors.accentGreen;
    if (abs < 80) return AppColors.accentOrange;
    return AppColors.accentRed;
  }
}
