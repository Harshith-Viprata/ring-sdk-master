import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

import '../../data/datasources/ble_data_source.dart';
import '../../../../core/ble/ble_manager.dart';

part 'device_event.dart';
part 'device_state.dart';

class DeviceBloc extends Bloc<DeviceEvent, DeviceState> {
  final BleDataSource _bleDataSource;
  StreamSubscription<Map<dynamic, dynamic>>? _eventSub;
  Timer? _reconnectTimer;

  DeviceBloc({required BleDataSource bleDataSource})
      : _bleDataSource = bleDataSource,
        super(const DeviceState()) {
    on<StartScan>(_onStartScan);
    on<StopScan>(_onStopScan);
    on<ConnectToDevice>(_onConnect);
    on<DisconnectDevice>(_onDisconnect);
    on<DeviceSdkEvent>(_onSdkEvent);
    on<AutoReconnect>(_onAutoReconnect);

    // Listen to SDK events
    _eventSub = _bleDataSource.eventStream.listen((event) {
      add(DeviceSdkEvent(event));
    });

    // Auto-reconnect to previously paired device on startup
    add(AutoReconnect());
  }

  /// Auto-reconnect with active BLE state polling.
  ///
  /// The broadcast eventStream LOSES the 'connected' event because:
  /// 1. BleDataSource.init() runs during initDependencies() and fires events
  /// 2. DeviceBloc is created LATER by BlocProvider in the widget tree
  /// 3. Events emitted before subscription are lost (broadcast stream)
  ///
  /// So we actively poll getBluetoothState() every 2s instead of waiting.
  Future<void> _onAutoReconnect(
    AutoReconnect event,
    Emitter<DeviceState> emit,
  ) async {
    final savedDevice = await BleManager.getSavedDeviceInfo();
    if (savedDevice == null) {
      print('[DeviceBloc] No saved device — staying disconnected');
      return;
    }

    // SDK events may have already connected while we awaited SharedPreferences.
    if (state.status == DeviceConnectionStatus.connected) {
      print('[DeviceBloc] Already connected — skipping reconnecting state');
      return;
    }

    print(
        '[DeviceBloc] Found saved device: ${savedDevice['name']} (${savedDevice['mac']}) — showing reconnecting');
    emit(state.copyWith(
      status: DeviceConnectionStatus.reconnecting,
      deviceName: savedDevice['name'],
      macAddress: savedDevice['mac'],
    ));

    // Actively poll BLE state every 2s for up to 30s.
    const maxAttempts = 15; // 15 x 2s = 30s
    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 2));

      // If something else changed our state, stop polling
      if (state.status != DeviceConnectionStatus.reconnecting) {
        print(
            '[DeviceBloc] State changed to ${state.status} during poll $i — stopping');
        return;
      }

      // Actively check the BLE state from the SDK
      try {
        final bleState = await YcProductPlugin().getBluetoothState();
        print('[DeviceBloc] Poll $i: BLE state = $bleState');
        if (bleState == BluetoothState.connected) {
          print('[DeviceBloc] Auto-reconnect confirmed via BLE state poll!');
          emit(state.copyWith(status: DeviceConnectionStatus.connected));
          _queryDeviceInfo();
          return;
        }
      } catch (e) {
        print('[DeviceBloc] Poll $i error: $e');
      }
    }

    // Timeout after 30s
    if (state.status == DeviceConnectionStatus.reconnecting) {
      print('[DeviceBloc] Auto-reconnect timed out after 30s');
      emit(state.copyWith(
        status: DeviceConnectionStatus.disconnected,
        errorMessage: 'Could not reconnect to ${savedDevice['name']}',
      ));
    }
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
        _reconnectTimer?.cancel();
        _reconnectTimer = null;
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
    _reconnectTimer?.cancel();
    return super.close();
  }
}
