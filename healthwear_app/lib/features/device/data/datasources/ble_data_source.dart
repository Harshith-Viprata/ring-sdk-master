import 'dart:async';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import '../../../../core/ble/ble_manager.dart';
import '../../../../core/ble/ble_event_handler.dart';

/// Data-source adapter that delegates all BLE operations to [BleManager].
///
/// This ensures the app uses a **single** [YcProductPlugin] instance
/// and benefits from [BleManager]'s proven connection flow (timeout,
/// auto-reconnect persistence, post-connection setup).
class BleDataSource {
  final BleManager _mgr;

  /// Broadcast controller driven by [BleManager.onEvent].
  final _eventController = StreamController<Map<dynamic, dynamic>>.broadcast();

  /// Whether the SDK listener has been wired.
  bool _listening = false;

  /// Whether init() has already completed — prevents destructive re-init.
  bool _initialized = false;

  BleDataSource({BleManager? manager}) : _mgr = manager ?? BleManager.instance;

  // ─── Lifecycle ──────────────────────────────────────────────────────────

  /// Initialise the plugin and start the native event stream.
  /// **Idempotent**: skips if already initialized to prevent autoConnect
  /// from killing active BLE measurements.
  Future<void> init({bool reconnect = true, bool log = false}) async {
    if (_initialized) {
      print('[BleDataSource] Already initialized — skipping');
      return;
    }
    await _mgr.init();
    _startListening();
    // Attempt auto-reconnect to previously paired device
    await _mgr.autoConnect();
    _initialized = true;
  }

  void _startListening() {
    if (_listening) return;
    _listening = true;
    _mgr.onEvent((event) {
      if (event is Map) {
        final mapped = Map<dynamic, dynamic>.from(event);
        print('[BleDataSource#${hashCode}] eventStream emit: ${mapped.keys}');
        _eventController.add(mapped);

        // Route ALL events to BleEventHandler for measurement & real-time UI.
        // This bypasses the potentially dead DeviceBloc subscription.
        BleEventHandler.instance.handleEvent(mapped);
      }
    });
  }

  /// Raw broadcast event stream (same shape as [onListening] callback).
  Stream<Map<dynamic, dynamic>> get eventStream => _eventController.stream;

  /// Dispose resources.
  void dispose() {
    _mgr.cancelEvents();
    _eventController.close();
  }

  // ─── Scanning ───────────────────────────────────────────────────────────

  Future<List<BluetoothDevice>> scanDevice({int seconds = 6}) async {
    final result = await _mgr.scan(seconds: seconds);
    return result;
  }

  Future<void> stopScan() => _mgr.stopScan();

  Future<void> exitScan() => _mgr.stopScan();

  // ─── Connection ─────────────────────────────────────────────────────────

  /// Connect to [device] using BleManager's proven flow (15 s timeout,
  /// post-connection getDeviceFeature + realTimeDataUpload + syncPhoneTime,
  /// and saving device MAC for auto-reconnect).
  Future<bool> connect(BluetoothDevice device) => _mgr.connect(device);

  Future<void> disconnect() async {
    await _mgr.disconnect();
  }

  Future<int?> getBluetoothState() => _mgr.getBluetoothState();

  // ─── Device Info ────────────────────────────────────────────────────────

  Future<DeviceFeature?> getDeviceFeature({BluetoothDevice? device}) =>
      _mgr.getDeviceFeature();

  Future<String?> queryMacAddress() => _mgr.getDeviceMacAddress();

  Future<String?> queryDeviceModel({BluetoothDevice? device}) =>
      _mgr.getDeviceModel();

  Future<DeviceBasicInfo?> queryBasicInfo() => _mgr.getDeviceBasicInfo();

  // ─── Settings ───────────────────────────────────────────────────────────

  Future<bool> syncPhoneTime() => _mgr.syncPhoneTime();

  Future<bool> setStepGoal(int steps) => _mgr.setStepGoal(steps);

  Future<bool> setUserInfo(int h, int w, int age, DeviceUserGender g) =>
      _mgr.setUserInfo(height: h, weight: w, age: age, gender: g);

  Future<bool> setHeartRateAlarm({
    bool enable = true,
    int max = 120,
    int min = 40,
  }) =>
      _mgr.setHeartRateAlarm(enable: enable, max: max, min: min);

  Future<bool> setBloodOxygenAlarm({bool enable = true, int min = 90}) =>
      _mgr.setBloodOxygenAlarm(enable: enable, min: min);

  Future<bool> setWristWake(bool enable) => _mgr.setWristWake(enable);

  Future<bool> setHealthMonitoring({
    bool enable = true,
    int interval = 60,
  }) =>
      _mgr.setHealthMonitoring(enable: enable, intervalMinutes: interval);

  Future<bool> findDevice() => _mgr.findDevice();

  Future<bool> setUnits({
    DeviceDistanceUnit distance = DeviceDistanceUnit.km,
    DeviceWeightUnit weight = DeviceWeightUnit.kg,
    DeviceTemperatureUnit temperature = DeviceTemperatureUnit.celsius,
    DeviceTimeFormat timeFormat = DeviceTimeFormat.h24,
  }) =>
      _mgr.setUnits(
        distance: distance,
        weight: weight,
        temperature: temperature,
        timeFormat: timeFormat,
      );

  // ─── Health Data Queries ────────────────────────────────────────────────

  Future<List?> queryHealthData(int type) => _mgr.queryHealthHistory(type);

  // ─── Real-Time Data ─────────────────────────────────────────────────────

  Future<void> setRealTimeUpload(bool enable,
          {DeviceRealTimeDataType type = DeviceRealTimeDataType.step}) =>
      _mgr.setRealTimeUpload(enable, type);

  // ─── On-Demand Measurement ──────────────────────────────────────────────

  Future<bool> startMeasurement(DeviceAppControlMeasureHealthDataType type) =>
      _mgr.startMeasure(type);

  Future<bool> stopMeasurement(DeviceAppControlMeasureHealthDataType type) =>
      _mgr.stopMeasure(type);

  // ─── ECG ────────────────────────────────────────────────────────────────

  Future<bool> startEcg() => _mgr.startECG();

  Future<bool> stopEcg() => _mgr.stopECG();

  Future<DeviceECGResult?> getEcgResult() => _mgr.getECGResult();
}
