import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

import '../../data/datasources/ble_data_source.dart';

part 'device_event.dart';
part 'device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final BleDataSource _bleDataSource;
  StreamSubscription<Map<dynamic, dynamic>>? _eventSub;

  DeviceBloc({required BleDataSource bleDataSource})
      : _bleDataSource = bleDataSource,
        super(const DeviceState()) {
    on<StartScan>(_onStartScan);
    on<StopScan>(_onStopScan);
    on<ConnectToDevice>(_onConnect);
    on<DisconnectDevice>(_onDisconnect);
    on<DeviceSdkEvent>(_onSdkEvent);

    // Listen to SDK events
    _eventSub = _bleDataSource.eventStream.listen((event) {
      add(DeviceSdkEvent(event));
    });
  }

  Future<void> _onStartScan(
    StartScan event,
    Emitter<DeviceState> emit,
  ) async {
    emit(state.copyWith(
      status: DeviceConnectionStatus.scanning,
      discoveredDevices: [],
      errorMessage: null,
    ));
    try {
      final devices = await _bleDataSource.scanDevice(seconds: event.seconds);
      emit(state.copyWith(
        status: DeviceConnectionStatus.disconnected,
        discoveredDevices: devices,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: DeviceConnectionStatus.disconnected,
        errorMessage: 'Scan failed: $e',
      ));
    }
  }

  Future<void> _onStopScan(
    StopScan event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      await _bleDataSource.stopScan();
    } catch (_) {}
    emit(state.copyWith(status: DeviceConnectionStatus.disconnected));
  }

  Future<void> _onConnect(
    ConnectToDevice event,
    Emitter<DeviceState> emit,
  ) async {
    final device = event.device as BluetoothDevice;
    emit(state.copyWith(
      status: DeviceConnectionStatus.connecting,
      errorMessage: null,
    ));
    try {
      final ok = await _bleDataSource.connect(device);
      if (ok) {
        emit(state.copyWith(
          status: DeviceConnectionStatus.connected,
          connectedDevice: device,
          deviceName: device.name,
          macAddress: device.macAddress,
        ));
        // Fetch additional device info in background
        _queryDeviceInfo();
      } else {
        emit(state.copyWith(
          status: DeviceConnectionStatus.disconnected,
          errorMessage: 'Connection failed — please try again',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: DeviceConnectionStatus.disconnected,
        errorMessage: 'Connection failed: $e',
      ));
    }
  }

  Future<void> _onDisconnect(
    DisconnectDevice event,
    Emitter<DeviceState> emit,
  ) async {
    try {
      await _bleDataSource.disconnect();
    } catch (_) {}
    emit(const DeviceState());
  }

  void _onSdkEvent(
    DeviceSdkEvent event,
    Emitter<DeviceState> emit,
  ) {
    final payload = event.payload;

    // ── Bluetooth state change ──
    if (payload.containsKey(NativeEventType.bluetoothStateChange)) {
      final connectState = payload[NativeEventType.bluetoothStateChange] as int;
      if (connectState == BluetoothState.connected) {
        emit(state.copyWith(
          status: DeviceConnectionStatus.connected,
        ));
        // Query device info now that we're connected
        _queryDeviceInfo();
      } else if (connectState == BluetoothState.disconnected ||
          connectState == BluetoothState.connectFailed) {
        emit(state.copyWith(
          status: DeviceConnectionStatus.disconnected,
          connectedDevice: null,
        ));
      }
    }

    // ── Device info (name, mac, etc.) ──
    if (payload.containsKey(NativeEventType.deviceInfo)) {
      final info = payload[NativeEventType.deviceInfo];
      if (info is Map) {
        emit(state.copyWith(
          deviceName: info['name']?.toString(),
          macAddress: info['mac']?.toString(),
        ));
      }
    }
  }

  /// Fetch battery and device details after connection
  Future<void> _queryDeviceInfo() async {
    try {
      final mac = await _bleDataSource.queryMacAddress();
      final model = await _bleDataSource.queryDeviceModel();
      if (!isClosed) {
        add(DeviceSdkEvent({
          NativeEventType.deviceInfo: {
            'mac': mac,
            'name': model,
          }
        }));
      }
    } catch (_) {}
  }

  @override
  Future<void> close() {
    _eventSub?.cancel();
    return super.close();
  }
}
