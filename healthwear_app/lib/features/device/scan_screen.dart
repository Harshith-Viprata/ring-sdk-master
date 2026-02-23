import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import '../../core/ble/ble_manager.dart';
import '../../core/models/health_models.dart';
import '../../core/providers/ble_provider.dart';
import '../../shared/theme/app_theme.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _requestPermissions());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt >= 31) {
      // Android 12+ — need BLUETOOTH_SCAN + BLUETOOTH_CONNECT
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      return statuses.values.every((s) => s.isGranted);
    } else {
      // Android < 12 — need location for BLE scan
      final status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    }
  }

  Future<void> _startScan() async {
    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      EasyLoading.showError('Bluetooth/Location permission required');
      return;
    }

    ref.read(isScanningProvider.notifier).state = true;
    ref.read(scannedDevicesProvider.notifier).state = [];
    EasyLoading.show(status: 'Scanning for devices...', maskType: EasyLoadingMaskType.black);

    try {
      final devices = await BleManager.instance.scan(seconds: 6);
      ref.read(scannedDevicesProvider.notifier).state = devices;
      if (devices.isEmpty) {
        EasyLoading.showInfo('No devices found. Ensure your ring is nearby.');
      } else {
        EasyLoading.dismiss();
      }
    } catch (e) {
      EasyLoading.showError('Scan failed: $e');
    } finally {
      ref.read(isScanningProvider.notifier).state = false;
    }
  }

  Future<void> _connectDevice(BluetoothDevice device) async {
    ref.read(isConnectingProvider.notifier).state = true;
    EasyLoading.show(
      status: 'Connecting to ${device.name}...',
      maskType: EasyLoadingMaskType.black,
    );

    try {
      final ok = await BleManager.instance.connect(device);
      if (ok) {
        // Immediately mark as connected so Dashboard shows metric grid
        ref.read(bleStateProvider.notifier).state = BluetoothState.connected;

        // Populate connected device info
        final mac = await BleManager.instance.getDeviceMacAddress();
        final model = await BleManager.instance.getDeviceModel();
        final feature = await BleManager.instance.getDeviceFeature();
        final basicInfo = await BleManager.instance.getDeviceBasicInfo();
        ref.read(connectedDeviceProvider.notifier).state = ConnectedDeviceInfo(
          name: device.name,
          mac: mac ?? device.macAddress,
          model: model,
          firmwareVersion: device.firmwareVersion,
          feature: feature,
          batteryPower: basicInfo?.batteryPower,
        );
        EasyLoading.dismiss();
        EasyLoading.showSuccess('Connected to ${device.name}!');
        if (mounted) Navigator.of(context).pop();
      } else {
        EasyLoading.showError('Failed to connect. Try again.');
      }
    } catch (e) {
      EasyLoading.showError('Error: $e');
    } finally {
      ref.read(isConnectingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(scannedDevicesProvider);
    final isScanning = ref.watch(isScanningProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Find Device'),
        actions: [
          IconButton(
            onPressed: isScanning ? null : _startScan,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isScanning
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, key: ValueKey('refresh')),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scan animation area
          if (devices.isEmpty)
            Expanded(
              flex: 2,
              child: Center(
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (_, __) => Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 3; i >= 1; i--)
                        Container(
                          width: 80.0 * i * _pulseAnimation.value,
                          height: 80.0 * i * _pulseAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent
                                .withOpacity(0.05 * (4 - i) * _pulseAnimation.value),
                            border: Border.all(
                              color: AppColors.accent.withOpacity(
                                  0.1 * (4 - i) * _pulseAnimation.value),
                              width: 1,
                            ),
                          ),
                        ),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.gradientAccent,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.bluetooth_searching_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (devices.isEmpty)
            Column(
              children: [
                Text(
                  isScanning ? 'Scanning...' : 'No devices found',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isScanning
                      ? 'Looking for nearby YC ring/watch'
                      : 'Tap the refresh icon to scan',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: ElevatedButton.icon(
                    onPressed: isScanning ? null : _startScan,
                    icon: const Icon(Icons.bluetooth_searching_rounded),
                    label: Text(isScanning ? 'Scanning...' : 'Start Scan'),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          // Device list
          if (devices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${devices.length} device${devices.length == 1 ? '' : 's'} found',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (devices.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: devices.length,
                itemBuilder: (ctx, i) => _DeviceTile(
                  device: devices[i],
                  onTap: () => _connectDevice(devices[i]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  final BluetoothDevice device;
  final VoidCallback onTap;

  const _DeviceTile({required this.device, required this.onTap});

  int get _rssiStrength {
    final rssi = device.rssiValue.abs();
    if (rssi < 60) return 4;
    if (rssi < 70) return 3;
    if (rssi < 80) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceLight),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.watch_rounded, color: AppColors.accent, size: 24),
        ),
        title: Text(
          device.name.isNotEmpty ? device.name : 'Unknown Device',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          device.macAddress,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SignalBars(strength: _rssiStrength),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, Color(0xFF0066FF)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Connect',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _SignalBars extends StatelessWidget {
  final int strength; // 1-4

  const _SignalBars({required this.strength});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(4, (i) {
        final active = i < strength;
        return Container(
          width: 4,
          height: 6.0 + (i * 4),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: active ? AppColors.accentGreen : AppColors.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
