import 'package:dartz/dartz.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart' show BluetoothDevice;

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/device_entity.dart';
import '../repositories/device_repository.dart';

/// Scan nearby BLE devices.
class ScanDevicesUseCase implements UseCase<List<BluetoothDevice>, int> {
  final DeviceRepository repository;
  ScanDevicesUseCase(this.repository);

  @override
  Future<Either<Failure, List<BluetoothDevice>>> call(int seconds) =>
      repository.scanDevices(seconds: seconds);
}

/// Connect to a specific BLE device.
class ConnectDeviceUseCase
    implements UseCase<ConnectedDeviceEntity, BluetoothDevice> {
  final DeviceRepository repository;
  ConnectDeviceUseCase(this.repository);

  @override
  Future<Either<Failure, ConnectedDeviceEntity>> call(BluetoothDevice device) =>
      repository.connectDevice(device);
}

/// Disconnect the current device.
class DisconnectDeviceUseCase implements UseCase<bool, NoParams> {
  final DeviceRepository repository;
  DisconnectDeviceUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) =>
      repository.disconnectDevice();
}

/// Sync phone time to device.
class SyncPhoneTimeUseCase implements UseCase<bool, NoParams> {
  final DeviceRepository repository;
  SyncPhoneTimeUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) =>
      repository.syncPhoneTime();
}
