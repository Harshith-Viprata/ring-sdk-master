import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/health_data.dart';
import '../repositories/health_repository.dart';

/// Get heart rate history from device.
class GetHeartRateHistoryUseCase
    implements UseCase<List<HeartRateRecord>, NoParams> {
  final HealthRepository repository;
  GetHeartRateHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<HeartRateRecord>>> call(NoParams params) =>
      repository.getHeartRateHistory();
}

/// Get step history from device.
class GetStepHistoryUseCase implements UseCase<List<StepRecord>, NoParams> {
  final HealthRepository repository;
  GetStepHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<StepRecord>>> call(NoParams params) =>
      repository.getStepHistory();
}

/// Get sleep history from device.
class GetSleepHistoryUseCase implements UseCase<List<SleepRecord>, NoParams> {
  final HealthRepository repository;
  GetSleepHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<SleepRecord>>> call(NoParams params) =>
      repository.getSleepHistory();
}

/// Start an on-demand measurement.
class StartMeasurementUseCase implements UseCase<bool, MeasurementType> {
  final HealthRepository repository;
  StartMeasurementUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(MeasurementType type) =>
      repository.startMeasurement(type);
}

/// Stop an on-demand measurement.
class StopMeasurementUseCase implements UseCase<bool, MeasurementType> {
  final HealthRepository repository;
  StopMeasurementUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(MeasurementType type) =>
      repository.stopMeasurement(type);
}
