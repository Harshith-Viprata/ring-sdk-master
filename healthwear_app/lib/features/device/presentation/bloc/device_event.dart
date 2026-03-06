part of 'device_bloc.dart';

/// Events for the DeviceBloc.
abstract class DeviceEvent extends Equatable {
  const DeviceEvent();
  @override
  List<Object?> get props => [];
}

/// Start scanning for BLE devices.
class StartScan extends DeviceEvent {
  final int seconds;
  const StartScan({this.seconds = 6});
  @override
  List<Object?> get props => [seconds];
}

/// Stop the active scan.
class StopScan extends DeviceEvent {}

/// Connect to a discovered device.
class ConnectToDevice extends DeviceEvent {
  final dynamic device; // BluetoothDevice from SDK
  const ConnectToDevice(this.device);
  @override
  List<Object?> get props => [device];
}

/// Disconnect from the current device.
class DisconnectDevice extends DeviceEvent {}

/// Internal: SDK event received.
class DeviceSdkEvent extends DeviceEvent {
  final Map<dynamic, dynamic> payload;
  const DeviceSdkEvent(this.payload);
  @override
  List<Object?> get props => [payload];
}
