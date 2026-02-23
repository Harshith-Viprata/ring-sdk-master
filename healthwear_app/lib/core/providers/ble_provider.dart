import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import '../ble/ble_manager.dart';
import '../ble/ble_event_handler.dart';
import '../models/health_models.dart';

// ─── BLE State ────────────────────────────────────────────────────────────

/// BLE connection state (connected/disconnected/connecting/off)
final bleStateProvider = StateProvider<int>((ref) => BluetoothState.disconnected);

/// Currently scanned nearby devices
final scannedDevicesProvider = StateProvider<List<BluetoothDevice>>((ref) => []);

/// Whether scanning is active
final isScanningProvider = StateProvider<bool>((ref) => false);

/// Whether a connect action is in progress
final isConnectingProvider = StateProvider<bool>((ref) => false);

/// Currently connected device info
final connectedDeviceProvider = StateProvider<ConnectedDeviceInfo?>((ref) => null);

// ─── Real-time Health State ───────────────────────────────────────────────

/// Latest real-time heart rate
final heartRateProvider = StateProvider<RealTimeHeartRate?>((ref) => null);

/// Latest real-time blood oxygen (SpO2)
final bloodOxygenProvider = StateProvider<RealTimeBloodOxygen?>((ref) => null);

/// Latest real-time blood pressure
final bloodPressureProvider = StateProvider<RealTimeBloodPressure?>((ref) => null);

/// Latest real-time temperature
final temperatureProvider = StateProvider<RealTimeTemperature?>((ref) => null);

/// Latest real-time step data
final stepsProvider = StateProvider<RealTimeSteps?>((ref) => null);

/// Latest real-time stress/pressure
final pressureProvider = StateProvider<RealTimePressure?>((ref) => null);

/// Latest real-time blood glucose
final bloodGlucoseProvider = StateProvider<RealTimeBloodGlucose?>((ref) => null);

/// ECG waveform points buffer (rolling window)
final ecgPointsProvider = StateProvider<List<ECGPoint>>((ref) => []);

/// Whether ECG measurement is active
final isECGActiveProvider = StateProvider<bool>((ref) => false);

// ─── BLE Event Listener Initialiser ──────────────────────────────────────

/// Call this once during app init to wire events → providers.
void initBleEventWiring(WidgetRef ref) {
  final handler = BleEventHandler.instance;

  handler.onBluetoothStateChange = (state) {
    ref.read(bleStateProvider.notifier).state = state;
    // Clear device on disconnect
    if (state == BluetoothState.disconnected) {
      ref.read(connectedDeviceProvider.notifier).state = null;
    }
  };

  handler.onDeviceInfo = (info) async {
    final mac = info['macAddress'] as String?;
    final name = info['name'] as String?;
    if (mac != null) {
      // Auto-reconnect happened. Fetch feature capabilities.
      final feature = await BleManager.instance.getDeviceFeature();
      ref.read(connectedDeviceProvider.notifier).state = ConnectedDeviceInfo(
        name: name ?? 'HealthWear Device',
        mac: mac,
        feature: feature,
      );
    }
  };

  handler.onHeartRate = (data) {
    ref.read(heartRateProvider.notifier).state = data;
  };

  handler.onBloodOxygen = (data) {
    ref.read(bloodOxygenProvider.notifier).state = data;
  };

  handler.onBloodPressure = (data) {
    ref.read(bloodPressureProvider.notifier).state = data;
  };

  handler.onTemperature = (data) {
    ref.read(temperatureProvider.notifier).state = data;
  };

  handler.onSteps = (data) {
    ref.read(stepsProvider.notifier).state = data;
  };

  handler.onPressure = (data) {
    ref.read(pressureProvider.notifier).state = data;
  };

  handler.onBloodGlucose = (data) {
    ref.read(bloodGlucoseProvider.notifier).state = data;
  };

  int ecgIndex = 0;
  handler.onECGFilteredData = (points) {
    final current = ref.read(ecgPointsProvider);
    final newPoints = points.map((v) => ECGPoint(
      value: v.toDouble(),
      filteredValue: v.toDouble(),
      index: ecgIndex++,
    )).toList();
    // Keep only last 500 points for performance
    final merged = [...current, ...newPoints];
    ref.read(ecgPointsProvider.notifier).state =
        merged.length > 500 ? merged.sublist(merged.length - 500) : merged;
  };

  handler.onECGEnd = () {
    ref.read(isECGActiveProvider.notifier).state = false;
  };

  BleManager.instance.onEvent(handler.handleEvent);
}

// ─── Async Health Data Providers ─────────────────────────────────────────

/// Historical heart rate data
final heartRateHistoryProvider = FutureProvider<List<HeartRateRecord>>((ref) async {
  final raw = await BleManager.instance.queryHealthHistory(HealthDataType.heartRate);
  if (raw == null) return [];
  return raw
      .whereType<Map>()
      .map((m) => HeartRateRecord.fromMap(m))
      .toList();
});

/// Historical step data
final stepHistoryProvider = FutureProvider<List<StepRecord>>((ref) async {
  final raw = await BleManager.instance.queryHealthHistory(HealthDataType.step);
  if (raw == null) return [];
  return raw
      .whereType<Map>()
      .map((m) => StepRecord.fromMap(m))
      .toList();
});

/// Historical sleep data
final sleepHistoryProvider = FutureProvider<List<SleepRecord>>((ref) async {
  final raw = await BleManager.instance.queryHealthHistory(HealthDataType.sleep);
  if (raw == null) return [];
  return raw
      .whereType<Map>()
      .map((m) => SleepRecord.fromMap(m))
      .toList();
});

/// Historical blood oxygen — comes from combinedData
final bloodOxygenHistoryProvider = FutureProvider<List<BloodOxygenRecord>>((ref) async {
  final raw = await BleManager.instance.queryHealthHistory(HealthDataType.combinedData);
  if (raw == null) return [];
  // Filter entries that actually have spo2 data
  return raw
      .whereType<Map>()
      .where((m) => m.containsKey('spo2') || m.containsKey('bloodOxygen'))
      .map((m) => BloodOxygenRecord.fromMap(m))
      .toList();
});

/// Historical blood pressure
final bloodPressureHistoryProvider = FutureProvider<List<BloodPressureRecord>>((ref) async {
  final raw = await BleManager.instance.queryHealthHistory(HealthDataType.bloodPressure);
  if (raw == null) return [];
  return raw
      .whereType<Map>()
      .map((m) => BloodPressureRecord.fromMap(m))
      .toList();
});

/// Historical temperature — comes from combinedData
final temperatureHistoryProvider = FutureProvider<List<TemperatureRecord>>((ref) async {
  final raw = await BleManager.instance.queryHealthHistory(HealthDataType.combinedData);
  if (raw == null) return [];
  return raw
      .whereType<Map>()
      .where((m) => m.containsKey('temperature') || m.containsKey('celsius'))
      .map((m) => TemperatureRecord.fromMap(m))
      .toList();
});
