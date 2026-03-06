import 'package:dartz/dartz.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart' show BluetoothDevice;

import '../../../../core/error/failures.dart';
import '../entities/device_entity.dart';

/// Domain-layer contract for device (BLE) operations.
abstract class DeviceRepository {
  /// Scan for nearby BLE devices.
  Future<Either<Failure, List<BluetoothDevice>>> scanDevices({int seconds = 6});

  /// Stop an active scan.
  Future<void> stopScan();

  /// Connect to a device and return its info.
  Future<Either<Failure, ConnectedDeviceEntity>> connectDevice(
      BluetoothDevice device);

  /// Disconnect the current device.
  Future<Either<Failure, bool>> disconnectDevice();

  /// Attempt auto-reconnect to the previously saved device.
  Future<Either<Failure, bool>> autoConnect();

  /// Stream of BLE state changes (connected / disconnected / off).
  Stream<int> watchBleState();

  /// Get device feature capabilities.
  Future<Either<Failure, ConnectedDeviceEntity>> getConnectedDevice();

  /// Find the connected device (trigger buzzer/vibrate).
  Future<Either<Failure, bool>> findDevice();

  /// Sync phone time to device.
  Future<Either<Failure, bool>> syncPhoneTime();

  /// Set user profile on the device.
  Future<Either<Failure, bool>> setUserInfo({
    required int height,
    required int weight,
    required int age,
    required int gender, // 0 = male, 1 = female
  });

  /// Set step goal.
  Future<Either<Failure, bool>> setStepGoal(int steps);

  /// Set heart rate alarm.
  Future<Either<Failure, bool>> setHeartRateAlarm({
    bool enable = true,
    int max = 120,
    int min = 40,
  });

  /// Set blood oxygen alarm.
  Future<Either<Failure, bool>> setBloodOxygenAlarm({
    bool enable = true,
    int min = 90,
  });

  /// Set wrist wake.
  Future<Either<Failure, bool>> setWristWake(bool enable);

  /// Set health monitoring mode.
  Future<Either<Failure, bool>> setHealthMonitoring({
    bool enable = true,
    int intervalMinutes = 60,
  });

  /// Set display units on device.
  Future<Either<Failure, bool>> setUnits({
    int distance = 0, // 0 = km, 1 = mile
    int weight = 0, // 0 = kg, 1 = lb
    int temperature = 0, // 0 = celsius, 1 = fahrenheit
    int timeFormat = 0, // 0 = 24h, 1 = 12h
  });
}
