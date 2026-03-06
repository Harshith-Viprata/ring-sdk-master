import 'package:equatable/equatable.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart' show DeviceFeature;

/// Domain entity representing a connected wearable device.
class ConnectedDeviceEntity extends Equatable {
  final String name;
  final String mac;
  final String? model;
  final int? firmwareVersion;
  final DeviceFeature? feature;
  final int? batteryPower;

  const ConnectedDeviceEntity({
    required this.name,
    required this.mac,
    this.model,
    this.firmwareVersion,
    this.feature,
    this.batteryPower,
  });

  ConnectedDeviceEntity copyWith({
    String? name,
    String? mac,
    String? model,
    int? firmwareVersion,
    DeviceFeature? feature,
    int? batteryPower,
  }) =>
      ConnectedDeviceEntity(
        name: name ?? this.name,
        mac: mac ?? this.mac,
        model: model ?? this.model,
        firmwareVersion: firmwareVersion ?? this.firmwareVersion,
        feature: feature ?? this.feature,
        batteryPower: batteryPower ?? this.batteryPower,
      );

  @override
  List<Object?> get props =>
      [name, mac, model, firmwareVersion, feature, batteryPower];
}
