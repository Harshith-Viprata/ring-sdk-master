import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

import '../../../../core/error/failures.dart';
import '../../../device/data/datasources/ble_data_source.dart';
import '../../../dashboard/domain/entities/health_data.dart';
import '../../domain/repositories/ecg_repository.dart';

class EcgRepositoryImpl implements EcgRepository {
  final BleDataSource bleDataSource;

  EcgRepositoryImpl({required this.bleDataSource});

  @override
  Future<Either<Failure, bool>> startEcg() async {
    try {
      final ok = await bleDataSource.startEcg();
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> stopEcg() async {
    try {
      final ok = await bleDataSource.stopEcg();
      return Right(ok);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, EcgResult>> getEcgResult() async {
    try {
      final result = await bleDataSource.getEcgResult();
      if (result == null) {
        return const Left(ServerFailure('ECG result unavailable'));
      }
      return Right(EcgResult(
        heartRate: result.hearRate,
        hrvNorm: result.hrvNorm,
        respiratoryRate: result.respiratoryRate,
        qrsType: result.qrsType,
        afFlag: result.afFlag,
      ));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<List<int>> streamEcgFilteredData() {
    return bleDataSource.eventStream
        .where((e) => e.containsKey(NativeEventType.deviceRealECGFilteredData))
        .map((e) {
      final data = e[NativeEventType.deviceRealECGFilteredData];
      if (data is List) return data.cast<int>();
      return <int>[];
    });
  }

  @override
  Stream<void> onEcgEnd() {
    return bleDataSource.eventStream
        .where((e) => e.containsKey(NativeEventType.deviceEndECG))
        .map((_) {});
  }
}
