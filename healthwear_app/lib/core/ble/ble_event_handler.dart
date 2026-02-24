import 'package:flutter/foundation.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import '../models/health_models.dart';

/// Maps raw native events from onListening() to typed health data objects.
class BleEventHandler {
  BleEventHandler._();
  static final BleEventHandler instance = BleEventHandler._();

  // --- Reactive UI States ---
  final ValueNotifier<int?> heartRateNotifier = ValueNotifier<int?>(null);

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
      final hrData = RealTimeHeartRate.fromMap(map);
      
      // Update global reactive hook for UI
      if (hrData.bpm > 0) {
        heartRateNotifier.value = hrData.bpm;
      }
      
      onHeartRate?.call(hrData);
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
      final map = event[NativeEventType.deviceHealthDataMeasureStateChange] as Map;
      final int state = map['state'] as int? ?? -1;
      final int healthDataType = map['healthDataType'] as int? ?? -1;
      final List<dynamic>? values = map['values'] as List<dynamic>?;
      
      debugPrint("BleEventHandler: MeasureStateChange type=$healthDataType state=$state values=$values");
      
      // state: 0 = success, 1 = fail, 2 = measuring
      if (state == 0 && values != null && values.isNotEmpty) {
         // Map the final measurement value to the respective real-time callback
         // healthDataType values: 0x00 HR, 0x01 BP, 0x02 SpO2, 0x04 Temp, 0x05 Glucose
         if (healthDataType == 0x00) {
            onHeartRate?.call(RealTimeHeartRate.fromMap({'value': values[0] as int}));
         } else if (healthDataType == 0x01 && values.length >= 2) {
            onBloodPressure?.call(RealTimeBloodPressure.fromMap({'systolicBloodPressure': values[0], 'diastolicBloodPressure': values[1]}));
         } else if (healthDataType == 0x02) {
            onBloodOxygen?.call(RealTimeBloodOxygen.fromMap({'bloodOxygenValue': values[0] as int}));
         } else if (healthDataType == 0x04 && values.length >= 2) {
            onTemperature?.call(RealTimeTemperature.fromMap({'value': "${values[0]}.${values[1]}"}));
         } else if (healthDataType == 0x05) {
            // Blood glucose is typically represented as a single integer (e.g. 56 -> 5.6 mmol/L)
            onBloodGlucose?.call(RealTimeBloodGlucose.fromMap({'value': "${(values[0] as int) / 10}.${(values[0] as int) % 10}"}));
         }
      }
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
