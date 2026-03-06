import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../dashboard/domain/entities/health_data.dart';

/// Domain-layer contract for ECG operations.
abstract class EcgRepository {
  /// Start ECG measurement on the device.
  Future<Either<Failure, bool>> startEcg();

  /// Stop ECG measurement.
  Future<Either<Failure, bool>> stopEcg();

  /// Get ECG result after measurement completes.
  Future<Either<Failure, EcgResult>> getEcgResult();

  /// Stream of filtered ECG waveform data points.
  Stream<List<int>> streamEcgFilteredData();

  /// Stream that emits when the device signals ECG has ended.
  Stream<void> onEcgEnd();
}
