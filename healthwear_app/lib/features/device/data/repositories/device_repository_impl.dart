import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/device_entity.dart';
import '../../domain/repositories/device_repository.dart';
import '../datasources/ble_data_source.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final BleDataSource bleDataSource;

  DeviceRepositoryImpl({required this.bleDataSource});

  @override
  Future<Either<Failure, List<BluetoothDevice>>> scanDevices(
      {int seconds = 6}) async {
    try {
      final devices = await bleDataSource.scanDevice(seconds: seconds);
      return Right(devices);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> stopScan() => bleDataSource.stopScan();

  @override
  Future<Either<Failure, ConnectedDeviceEntity>> connectDevice(
      BluetoothDevice device) async {
    try {
      await bleDataSource.connect(device);
      // After connecting, query device info
      final feature = await bleDataSource.getDeviceFeature(device: device);
      final model = await bleDataSource.queryDeviceModel(device: device);
      final mac = await bleDataSource.queryMacAddress();

      return Right(ConnectedDeviceEntity(
        name: device.name,
        mac: mac ?? device.macAddress,
        model: model ?? device.deviceModel,
        firmwareVersion: device.firmwareVersion,
        feature: feature,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> disconnectDevice() async {
    try {
      await bleDataSource.disconnect();
      return const Right(true);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> autoConnect() async {
    // The SDK handles auto-reconnect internally when initPlugin is
    // called with isReconnectEnable = true
    return const Right(true);
  }

  @override
  Stream<int> watchBleState() {
    return bleDataSource.eventStream
        .where((e) => e.containsKey(NativeEventType.bluetoothStateChange))
        .map((e) => e[NativeEventType.bluetoothStateChange] as int);
  }

  @override
  Future<Either<Failure, ConnectedDeviceEntity>> getConnectedDevice() async {
    try {
      final feature = await bleDataSource.getDeviceFeature();
      final mac = await bleDataSource.queryMacAddress();
      final model = await bleDataSource.queryDeviceModel();
      final info = await bleDataSource.queryBasicInfo();

      return Right(ConnectedDeviceEntity(
        name: model ?? 'Unknown',
        mac: mac ?? '',
        model: model,
        feature: feature,
        batteryPower: info?.batteryPower,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> findDevice() async {
    try {
      final ok = await bleDataSource.findDevice();
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> syncPhoneTime() async {
    try {
      final ok = await bleDataSource.syncPhoneTime();
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setUserInfo({
    required int height,
    required int weight,
    required int age,
    required int gender,
  }) async {
    try {
      final g = gender == 0 ? DeviceUserGender.male : DeviceUserGender.female;
      final ok = await bleDataSource.setUserInfo(height, weight, age, g);
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setStepGoal(int steps) async {
    try {
      final ok = await bleDataSource.setStepGoal(steps);
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setHeartRateAlarm({
    bool enable = true,
    int max = 120,
    int min = 40,
  }) async {
    try {
      final ok = await bleDataSource.setHeartRateAlarm(
          enable: enable, max: max, min: min);
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setBloodOxygenAlarm({
    bool enable = true,
    int min = 90,
  }) async {
    try {
      final ok =
          await bleDataSource.setBloodOxygenAlarm(enable: enable, min: min);
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setWristWake(bool enable) async {
    try {
      final ok = await bleDataSource.setWristWake(enable);
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setHealthMonitoring({
    bool enable = true,
    int intervalMinutes = 60,
  }) async {
    try {
      final ok = await bleDataSource.setHealthMonitoring(
          enable: enable, interval: intervalMinutes);
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> setUnits({
    int distance = 0,
    int weight = 0,
    int temperature = 0,
    int timeFormat = 0,
  }) async {
    try {
      final ok = await bleDataSource.setUnits(
        distance:
            distance == 0 ? DeviceDistanceUnit.km : DeviceDistanceUnit.mile,
        weight: weight == 0 ? DeviceWeightUnit.kg : DeviceWeightUnit.lb,
        temperature: temperature == 0
            ? DeviceTemperatureUnit.celsius
            : DeviceTemperatureUnit.fahrenheit,
        timeFormat:
            timeFormat == 0 ? DeviceTimeFormat.h24 : DeviceTimeFormat.h12,
      );
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
