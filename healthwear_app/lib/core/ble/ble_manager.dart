import 'package:shared_preferences/shared_preferences.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

/// Singleton BLE manager wrapping YcProductPlugin.
/// All device communication goes through this class.
class BleManager {
  BleManager._();
  static final BleManager instance = BleManager._();

  final _plugin = YcProductPlugin();

  // ─── Initialisation ──────────────────────────────────────────────────────

  /// Call once in main() before runApp.
  Future<void> init() async {
    await _plugin.initPlugin(isReconnectEnable: true, isLogEnable: false);
  }

  /// Register a listener that receives all native BLE events.
  /// Use NativeEventType constants to filter events.
  void onEvent(void Function(dynamic event) handler) {
    _plugin.onListening(handler);
  }

  void cancelEvents() => _plugin.cancelListening();

  // ─── Bluetooth State ─────────────────────────────────────────────────────

  Future<int> getBluetoothState() async =>
      (await _plugin.getBluetoothState()) ?? BluetoothState.off;

  // ─── Scan ────────────────────────────────────────────────────────────────

  /// Scan for nearby YC ring/watch devices.
  /// Returns devices sorted by signal strength (strongest first).
  Future<List<BluetoothDevice>> scan({int seconds = 6}) async {
    final devices = await _plugin.scanDevice(time: seconds) ?? [];
    devices.sort((a, b) => b.rssiValue - a.rssiValue);
    return devices;
  }

  Future<void> stopScan() => _plugin.stopScanDevice();

  // ─── Connection ──────────────────────────────────────────────────────────
  static const String _prefKeyDeviceMac = 'yc_connected_device_mac';
  static const String _prefKeyDeviceName = 'yc_connected_device_name';

  /// Saves the device to SharedPreferences for auto-reconnect
  Future<void> _saveConnectedDevice(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyDeviceMac, device.macAddress);
    await prefs.setString(_prefKeyDeviceName, device.name);
  }

  /// Clears the saved device from SharedPreferences
  Future<void> _clearConnectedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyDeviceMac);
    await prefs.remove(_prefKeyDeviceName);
  }

  /// Attempts to auto-connect to a previously connected device on startup.
  /// Call this when the app starts. Returns true if auto-connect started successfully.
  Future<bool> autoConnect() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString(_prefKeyDeviceMac);
    final name = prefs.getString(_prefKeyDeviceName);

    if (mac != null && mac.isNotEmpty) {
      final device = BluetoothDevice.formJson({
        "macAddress": mac,
        "deviceIdentifier": mac,
        "name": name ?? "YC Device",
        "rssiValue": 0,
      });
      return connect(device);
    }
    return false;
  }

  /// Connect to a device. Automatically fetches DeviceFeature after success.
  Future<bool> connect(BluetoothDevice device) async {
    bool ok = false;
    try {
      ok = await _plugin.connectDevice(device).timeout(
        const Duration(seconds: 15),
        onTimeout: () => false,
      ) ?? false;
    } catch (e) {
      ok = false;
    }
    
    if (ok) {
      // Fetch feature capabilities immediately so UI can adapt (with timeouts)
      try {
        await _plugin.getDeviceFeature().timeout(const Duration(seconds: 5));
        
        // MANDATORY PATCH: explicitly enable real-time data streaming upon successful connection
        await _plugin.realTimeDataUpload(true, dataType: DeviceRealTimeDataType.combinedData)
            .timeout(const Duration(seconds: 5));
            
        // Sync phone time on connection
        await _plugin.setDeviceSyncPhoneTime().timeout(const Duration(seconds: 5));
        
        // Save device for auto-reconnect
        await _saveConnectedDevice(device);
      } catch (_) {
        // Ignore timeout for secondary commands after connection
      }
    }
    return ok;
  }

  Future<bool> disconnect() async {
    await _clearConnectedDevice();
    return (await _plugin.disconnectDevice()) ?? false;
  }

  Future<void> resetBond() => _plugin.resetBond();

  // ─── Device Info ─────────────────────────────────────────────────────────

  Future<DeviceFeature?> getDeviceFeature() =>
      _plugin.getDeviceFeature();

  Future<DeviceBasicInfo?> getDeviceBasicInfo() async {
    final r = await _plugin.queryDeviceBasicInfo();
    return r?.statusCode == PluginState.succeed ? r!.data : null;
  }

  Future<String?> getDeviceMacAddress() async {
    final r = await _plugin.queryDeviceMacAddress();
    return r?.statusCode == PluginState.succeed ? r!.data : null;
  }

  Future<String?> getDeviceModel() async {
    final r = await _plugin.queryDeviceModel();
    return r?.statusCode == PluginState.succeed ? r!.data : null;
  }

  Future<DeviceMcuPlatform?> getDeviceMCU() async {
    final r = await _plugin.queryDeviceMCU();
    return r?.statusCode == PluginState.succeed ? r!.data : null;
  }

  // ─── Real-time Data ──────────────────────────────────────────────────────

  /// Enable/disable real-time data upload for a specific type.
  Future<void> setRealTimeUpload(
    bool enable,
    DeviceRealTimeDataType type,
  ) async {
    await _plugin.realTimeDataUpload(enable, dataType: type);
  }

  /// Enable/disable continuous hardware health monitoring (turns on the optical sensors)
  Future<void> setDeviceHealthMonitoringMode({required bool enable, int interval = 10}) async {
    await _plugin.setDeviceHealthMonitoringMode(isEnable: enable, interval: interval);
  }

  /// Enable temperature continuous monitoring
  Future<void> setDeviceTemperatureMonitoringMode({required bool enable, int interval = 10}) async {
    await _plugin.setDeviceTemperatureMonitoringMode(isEnable: enable, interval: interval);
  }

  // ─── Historical Health Data ──────────────────────────────────────────────

  /// Fetch historical health data for a given type.
  /// [healthDataType] is a HealthDataType constant.
  Future<List?> queryHealthHistory(int healthDataType) async {
    final r = await _plugin.queryDeviceHealthData(healthDataType);
    if (r?.statusCode == PluginState.succeed) return r!.data;
    return null;
  }

  /// Delete historical health data for a given type.
  Future<bool> deleteHealthHistory(int healthDataType) async {
    final r = await _plugin.deleteDeviceHealthData(healthDataType);
    return r?.statusCode == PluginState.succeed;
  }

  // ─── ECG ─────────────────────────────────────────────────────────────────

  Future<bool> startECG() async {
    final r = await _plugin.startECGMeasurement();
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> stopECG() async {
    final r = await _plugin.stopECGMeasurement();
    return r?.statusCode == PluginState.succeed;
  }

  Future<DeviceECGResult?> getECGResult() async {
    final r = await _plugin.getECGResult();
    return r?.statusCode == PluginState.succeed ? r!.data : null;
  }

  // ─── App-controlled Measurement ──────────────────────────────────────────

  Future<bool> startMeasure(DeviceAppControlMeasureHealthDataType type) async {
    final r = await _plugin.appControlMeasureHealthData(true, type);
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> stopMeasure(DeviceAppControlMeasureHealthDataType type) async {
    final r = await _plugin.appControlMeasureHealthData(false, type);
    return r?.statusCode == PluginState.succeed;
  }

  // ─── Device Settings ──────────────────────────────────────────────────────

  Future<bool> setUserInfo({
    required int height,
    required int weight,
    required int age,
    required DeviceUserGender gender,
  }) async {
    final r = await _plugin.setDeviceUserInfo(height, weight, age, gender);
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> setHeartRateAlarm({
    bool enable = true,
    int max = 120,
    int min = 40,
  }) async {
    final r = await _plugin.setDeviceHeartRateAlarm(
      isEnable: enable,
      maxHeartRate: max,
      minHeartRate: min,
    );
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> setBloodOxygenAlarm({bool enable = true, int min = 90}) async {
    final r = await _plugin.setDeviceBloodOxygenAlarm(
      isEnable: enable,
      minimum: min,
    );
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> setUnits({
    DeviceDistanceUnit distance = DeviceDistanceUnit.km,
    DeviceWeightUnit weight = DeviceWeightUnit.kg,
    DeviceTemperatureUnit temperature = DeviceTemperatureUnit.celsius,
    DeviceTimeFormat timeFormat = DeviceTimeFormat.h24,
  }) async {
    final r = await _plugin.setDeviceUnit(
      distance: distance,
      weight: weight,
      temperature: temperature,
      timeFormat: timeFormat,
    );
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> setDoNotDisturb(
    bool enable,
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) async {
    final r = await _plugin.setDeviceNotDisturb(
      enable,
      startHour,
      startMinute,
      endHour,
      endMinute,
    );
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> setHealthMonitoring({
    bool enable = true,
    int intervalMinutes = 60,
  }) async {
    final r = await _plugin.setDeviceHealthMonitoringMode(
      isEnable: enable,
      interval: intervalMinutes,
    );
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> setStepGoal(int steps) async {
    final r = await _plugin.setDeviceStepGoal(steps);
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> setWristWake(bool enable) async {
    final r = await _plugin.setDeviceWristBrightScreen(enable);
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> findDevice() async {
    final r = await _plugin.findDevice();
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> syncPhoneTime() async {
    final r = await _plugin.setDeviceSyncPhoneTime();
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> setWearingPosition(DeviceWearingPositionType pos) async {
    final r = await _plugin.setDeviceWearingPosition(pos);
    return r?.statusCode == PluginState.succeed;
  }

  Future<bool> setInfoPush(bool enable, Set<DeviceInfoPushType> types) async {
    final r = await _plugin.setDeviceInfoPush(enable, types);
    return r?.statusCode == PluginState.succeed;
  }

  // ─── OTA ─────────────────────────────────────────────────────────────────

  Future<void> startOTA(
    DeviceMcuPlatform platform,
    String firmwarePath,
    OTAProcessCallback callback,
  ) => _plugin.deviceUpgrade(platform, firmwarePath, callback);
}
