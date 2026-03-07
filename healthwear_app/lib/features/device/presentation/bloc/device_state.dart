part of 'device_bloc.dart';

/// Connection status for UI.
enum DeviceConnectionStatus {
  disconnected,
  scanning,
  connecting,
  reconnecting,
  connected
}

/// State for the DeviceBloc.
class DeviceState extends Equatable {
  final DeviceConnectionStatus status;
  final List<dynamic> discoveredDevices; // List<BluetoothDevice>
  final dynamic connectedDevice; // BluetoothDevice?
  final String? deviceName;
  final String? macAddress;
  final int batteryPercent;
  final String? errorMessage;

  const DeviceState({
    this.status = DeviceConnectionStatus.disconnected,
    this.discoveredDevices = const [],
    this.connectedDevice,
    this.deviceName,
    this.macAddress,
    this.batteryPercent = 0,
    this.errorMessage,
  });

  DeviceState copyWith({
    DeviceConnectionStatus? status,
    List<dynamic>? discoveredDevices,
    dynamic connectedDevice,
    String? deviceName,
    String? macAddress,
    int? batteryPercent,
    String? errorMessage,
  }) {
    return DeviceState(
      status: status ?? this.status,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      deviceName: deviceName ?? this.deviceName,
      macAddress: macAddress ?? this.macAddress,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        discoveredDevices,
        connectedDevice,
        deviceName,
        macAddress,
        batteryPercent,
        errorMessage,
      ];
}
