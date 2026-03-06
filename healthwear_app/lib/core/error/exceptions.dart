/// Exception thrown by BLE data sources when a hardware operation fails.
class BleException implements Exception {
  final String message;
  final int? code;

  const BleException({required this.message, this.code});

  @override
  String toString() => 'BleException: $message (code: $code)';
}

/// Exception thrown by local data sources (Hive / SharedPreferences).
class CacheException implements Exception {
  final String message;

  const CacheException({required this.message});

  @override
  String toString() => 'CacheException: $message';
}

/// General server / SDK exception.
class ServerException implements Exception {
  final String message;
  final int? code;

  const ServerException([this.message = 'Server error', this.code]);

  @override
  String toString() => 'ServerException: $message (code: $code)';
}

/// Exception thrown when a device is not connected.
class DeviceNotConnectedException implements Exception {
  final String message;

  const DeviceNotConnectedException({
    this.message = 'No device is connected',
  });

  @override
  String toString() => 'DeviceNotConnectedException: $message';
}
