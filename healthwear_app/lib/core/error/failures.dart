import 'package:equatable/equatable.dart';

/// Base failure class for the Either pattern.
/// All domain-level errors extend this.
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Failure originating from the BLE hardware layer.
class BleFailure extends Failure {
  const BleFailure({required super.message, super.code});
}

/// Failure originating from the local cache (Hive / SharedPreferences).
class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.code});
}

/// Failure when device connection is required but not available.
class ConnectionFailure extends Failure {
  const ConnectionFailure({
    super.message = 'No device connected',
    super.code,
  });
}

/// Failure when a measurement times out or is aborted.
class MeasurementFailure extends Failure {
  const MeasurementFailure({required super.message, super.code});
}

/// Failure from the remote / SDK server layer.
class ServerFailure extends Failure {
  const ServerFailure([String message = 'Server error'])
      : super(message: message);
}

/// Generic unexpected failure.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred',
    super.code,
  });
}
