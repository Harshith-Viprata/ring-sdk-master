import 'package:flutter/foundation.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import '../models/health_models.dart';

/// Maps raw native events from onListening() to typed health data objects.
class BleEventHandler {
  BleEventHandler._();
  static final BleEventHandler instance = BleEventHandler._();

  // --- Typed callbacks ---
  void Function(int state)? onBluetoothStateChange;
  void Function(Map info)? onDeviceInfo;
  void Function(RealTimeHeartRate data)? onHeartRate;
  void Function(RealTimeBloodOxygen data)? onBloodOxygen;
  void Function(RealTimeBloodPressure data)? onBloodPressure;
  void Function(RealTimeTemperature data)? onTemperature;
  void Function(RealTimeSteps data)? onSteps;
  void Function(RealTimePressure data)? onPressure;
  void Function(RealTimeBloodGlucose data)? onBloodGlucose;
  void Function(List<int> data)? onECGData;
  void Function(List<int> filteredPoints)? onECGFilteredData;

  /// Called when ECG measurement ends on the device side.
  /// The caller should then invoke BleManager.getECGResult() to fetch the result.
  void Function()? onECGEnd;

  void Function(bool isTakingPhoto)? onPhotoState;

  /// The single handler to pass into BleManager.onEvent()
  void handleEvent(dynamic event) {
    if (event == null || event is! Map) return;

    // ── Bluetooth state change ─────────────────────────────────────────────
    if (event.containsKey(NativeEventType.bluetoothStateChange)) {
      final state = event[NativeEventType.bluetoothStateChange] as int;
      onBluetoothStateChange?.call(state);
    }

    // ── Device connected info (auto-reconnect etc.) ────────────────────────
    if (event.containsKey(NativeEventType.deviceInfo)) {
      final info = event[NativeEventType.deviceInfo];
      if (info is Map) {
        onDeviceInfo?.call(info);
      }
    }

    // ── Real-time Heart Rate ───────────────────────────────────────────────
    if (event.containsKey(NativeEventType.deviceRealHeartRate)) {
      final raw = event[NativeEventType.deviceRealHeartRate];
      debugPrint("BleEventHandler: HeartRate raw=$raw");
      final map = raw is Map ? raw : {'value': raw};
      onHeartRate?.call(RealTimeHeartRate.fromMap(map));
    }

    // ── Real-time Blood Oxygen ─────────────────────────────────────────────
    if (event.containsKey(NativeEventType.deviceRealBloodOxygen)) {
      final raw = event[NativeEventType.deviceRealBloodOxygen];
      debugPrint("BleEventHandler: BloodOxygen raw=$raw");
      final map = raw is Map ? raw : {'value': raw};
      onBloodOxygen?.call(RealTimeBloodOxygen.fromMap(map));
    }

    // ── Real-time Blood Pressure ───────────────────────────────────────────
    if (event.containsKey(NativeEventType.deviceRealBloodPressure)) {
      final raw = event[NativeEventType.deviceRealBloodPressure];
      debugPrint("BleEventHandler: BloodPressure raw=$raw");
      if (raw is Map) {
        onBloodPressure?.call(RealTimeBloodPressure.fromMap(raw));
      }
    }

    // ── Real-time Temperature ──────────────────────────────────────────────
    if (event.containsKey(NativeEventType.deviceRealTemperature)) {
      final raw = event[NativeEventType.deviceRealTemperature];
      debugPrint("BleEventHandler: Temperature raw=$raw");
      final map = raw is Map ? raw : {'value': raw};
      onTemperature?.call(RealTimeTemperature.fromMap(map));
    }

    // ── Real-time Steps ───────────────────────────────────────────────────
    if (event.containsKey(NativeEventType.deviceRealStep)) {
      final raw = event[NativeEventType.deviceRealStep];
      debugPrint("BleEventHandler: Steps raw=$raw");
      final map = raw is Map ? raw : {'value': raw};
      onSteps?.call(RealTimeSteps.fromMap(map));
    }

    // ── Real-time Pressure / Stress ───────────────────────────────────────
    if (event.containsKey(NativeEventType.deviceRealPressure)) {
      final raw = event[NativeEventType.deviceRealPressure];
      final map = raw is Map ? raw : {'value': raw};
      onPressure?.call(RealTimePressure.fromMap(map));
    }

    // ── Real-time Blood Glucose ───────────────────────────────────────────
    if (event.containsKey(NativeEventType.deviceRealBloodGlucose)) {
      final raw = event[NativeEventType.deviceRealBloodGlucose];
      debugPrint("BleEventHandler: BloodGlucose raw=$raw");
      final map = raw is Map ? raw : {'value': raw};
      onBloodGlucose?.call(RealTimeBloodGlucose.fromMap(map));
    }

    // ── ECG Raw Data ──────────────────────────────────────────────────────
    if (event.containsKey(NativeEventType.deviceRealECGData)) {
      final raw = event[NativeEventType.deviceRealECGData];
      if (raw is List) {
        onECGData?.call(List<int>.from(raw));
      }
    }

    // ── ECG Filtered Data ─────────────────────────────────────────────────
    if (event.containsKey(NativeEventType.deviceRealECGFilteredData)) {
      final raw = event[NativeEventType.deviceRealECGFilteredData];
      if (raw is List) {
        onECGFilteredData?.call(List<int>.from(raw));
      }
    }

    // ── ECG Measurement End ───────────────────────────────────────────────
    // Device signals ECG is done; caller must call BleManager.getECGResult()
    if (event.containsKey(NativeEventType.deviceEndECG)) {
      onECGEnd?.call();
    }

    // ── Photo Control ─────────────────────────────────────────────────────
    if (event.containsKey(NativeEventType.deviceControlPhotoStateChange)) {
      final isTaking =
          event[NativeEventType.deviceControlPhotoStateChange] as bool? ??
              false;
      onPhotoState?.call(isTaking);
    }

    // -- Measurement State Change --
    if (event.containsKey(NativeEventType.deviceHealthDataMeasureStateChange)) {
      // Log for debugging: {healthDataType: 4, state: 0}
      // state: 0=start, 1=end, 2=success, 3=fail (varies by protocol)
    }

    // -- Debug: Log any unhandled keys --
    final handledKeys = {
      NativeEventType.bluetoothStateChange,
      NativeEventType.deviceInfo,
      NativeEventType.deviceRealHeartRate,
      NativeEventType.deviceRealBloodOxygen,
      NativeEventType.deviceRealBloodPressure,
      NativeEventType.deviceRealTemperature,
      NativeEventType.deviceRealStep,
      NativeEventType.deviceRealPressure,
      NativeEventType.deviceRealBloodGlucose,
      NativeEventType.deviceRealECGData,
      NativeEventType.deviceRealECGFilteredData,
      NativeEventType.deviceEndECG,
      NativeEventType.deviceControlPhotoStateChange,
      NativeEventType.deviceHealthDataMeasureStateChange,
    };

    final unhandled = event.keys.where((k) => !handledKeys.contains(k)).toList();
    if (unhandled.isNotEmpty) {
      // Use internal logger or print in debug
    }
  }
}
