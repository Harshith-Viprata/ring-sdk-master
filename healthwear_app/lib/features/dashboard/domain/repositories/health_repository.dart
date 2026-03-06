import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/health_data.dart';

/// Enum for on-demand measurement types.
enum MeasurementType {
  heartRate,
  bloodPressure,
  bloodOxygen,
  bodyTemperature,
  bloodGlucose
}

/// Domain-layer contract for health data operations.
abstract class HealthRepository {
  /// Returns a broadcast stream of real-time health data from the device.
  Stream<HealthReading> streamRealTimeHealth();

  /// Enable or disable real-time data upload on the device.
  Future<Either<Failure, void>> setRealTimeUpload(bool enable);

  /// Enable continuous health monitoring on the device sensors.
  Future<Either<Failure, void>> enableHealthMonitoring({int interval = 5});

  /// Enable continuous temperature monitoring.
  Future<Either<Failure, void>> enableTemperatureMonitoring({int interval = 5});

  // ─── History Queries ─────────────────────────────────────────────────

  Future<Either<Failure, List<HeartRateRecord>>> getHeartRateHistory();
  Future<Either<Failure, List<StepRecord>>> getStepHistory();
  Future<Either<Failure, List<SleepRecord>>> getSleepHistory();
  Future<Either<Failure, List<BloodOxygenRecord>>> getBloodOxygenHistory();
  Future<Either<Failure, List<BloodPressureRecord>>> getBloodPressureHistory();
  Future<Either<Failure, List<TemperatureRecord>>> getTemperatureHistory();

  // ─── On-Demand Measurement ───────────────────────────────────────────

  Future<Either<Failure, bool>> startMeasurement(MeasurementType type);
  Future<Either<Failure, bool>> stopMeasurement(MeasurementType type);
}
