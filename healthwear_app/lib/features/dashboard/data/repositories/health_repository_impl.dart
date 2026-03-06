import 'package:dartz/dartz.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

import '../../../../core/error/failures.dart';
import '../../../device/data/datasources/ble_data_source.dart';
import '../../domain/entities/health_data.dart';
import '../../domain/repositories/health_repository.dart';

class HealthRepositoryImpl implements HealthRepository {
  final BleDataSource bleDataSource;
  HealthRepositoryImpl({required this.bleDataSource});

  // ─── Real-Time Stream ──────────────────────────────────────────────────

  @override
  Stream<HealthReading> streamRealTimeHealth() {
    // Filter raw SDK events for any health metric using NativeEventType constants
    return bleDataSource.eventStream
        .where((e) =>
            e.containsKey(NativeEventType.deviceRealHeartRate) ||
            e.containsKey(NativeEventType.deviceRealBloodOxygen) ||
            e.containsKey(NativeEventType.deviceRealBloodPressure) ||
            e.containsKey(NativeEventType.deviceRealTemperature) ||
            e.containsKey(NativeEventType.deviceRealStep) ||
            e.containsKey(NativeEventType.deviceRealPressure) ||
            e.containsKey(NativeEventType.deviceRealBloodGlucose))
        .map((raw) {
      print('[HealthRepo] streamRealTimeHealth received event: ${raw.keys}');
      // Parse each metric type from the native event
      int? heartRate;
      int? spo2;
      int? systolic;
      int? diastolic;
      double? temperature;
      int? steps;
      int? calories;
      double? distanceKm;
      int? stressLevel;
      double? bloodGlucose;

      if (raw.containsKey(NativeEventType.deviceRealHeartRate)) {
        final d = raw[NativeEventType.deviceRealHeartRate];
        final map = d is Map ? d : {'value': d};
        final v = map['heartRate'] ?? map['value'] ?? 0;
        heartRate = v is num ? v.toInt() : int.tryParse(v.toString());
      }

      if (raw.containsKey(NativeEventType.deviceRealBloodOxygen)) {
        final d = raw[NativeEventType.deviceRealBloodOxygen];
        final map = d is Map ? d : {'value': d};
        final v = map['bloodOxygen'] ?? map['value'] ?? 0;
        spo2 = v is num ? v.toInt() : int.tryParse(v.toString());
      }

      if (raw.containsKey(NativeEventType.deviceRealBloodPressure)) {
        final d = raw[NativeEventType.deviceRealBloodPressure];
        if (d is Map) {
          systolic = ((d['systolicBloodPressure'] ?? d['systolic'] ?? 0) as num)
              .toInt();
          diastolic =
              ((d['diastolicBloodPressure'] ?? d['diastolic'] ?? 0) as num)
                  .toInt();
        }
      }

      if (raw.containsKey(NativeEventType.deviceRealTemperature)) {
        final d = raw[NativeEventType.deviceRealTemperature];
        final map = d is Map ? d : {'value': d};
        final v = map['temperature'] ?? map['value'] ?? 0;
        temperature = v is num ? v.toDouble() : double.tryParse(v.toString());
      }

      if (raw.containsKey(NativeEventType.deviceRealStep)) {
        final d = raw[NativeEventType.deviceRealStep];
        final map = d is Map ? d : {'value': d};
        steps = ((map['sportStep'] ??
                map['step'] ??
                map['steps'] ??
                map['value'] ??
                0) as num)
            .toInt();
        calories =
            ((map['sportCalorie'] ?? map['calories'] ?? 0) as num).toInt();
        final dist = (map['sportDistance'] ?? map['distance'] ?? 0) as num;
        distanceKm = dist.toDouble();
      }

      if (raw.containsKey(NativeEventType.deviceRealPressure)) {
        final d = raw[NativeEventType.deviceRealPressure];
        final map = d is Map ? d : {'value': d};
        final v = map['pressure'] ?? map['value'] ?? 0;
        stressLevel = v is num ? v.toInt() : int.tryParse(v.toString());
      }

      if (raw.containsKey(NativeEventType.deviceRealBloodGlucose)) {
        final d = raw[NativeEventType.deviceRealBloodGlucose];
        final map = d is Map ? d : {'value': d};
        final v = map['bloodGlucose'] ?? map['value'] ?? 0;
        bloodGlucose = v is num ? v.toDouble() : double.tryParse(v.toString());
      }

      return HealthReading(
        heartRate: heartRate,
        spo2: spo2,
        systolic: systolic,
        diastolic: diastolic,
        temperature: temperature,
        steps: steps,
        calories: calories,
        distanceKm: distanceKm,
        stressLevel: stressLevel,
        bloodGlucose: bloodGlucose,
        timestamp: DateTime.now(),
      );
    });
  }

  // ─── Device Controls ───────────────────────────────────────────────────

  @override
  Future<Either<Failure, void>> setRealTimeUpload(bool enable) async {
    try {
      // Enable BOTH step and combinedData types — SDK accepts one per call
      // Delay between calls to prevent BLE command queue blockage
      await bleDataSource.setRealTimeUpload(
        enable,
        type: DeviceRealTimeDataType.step,
      );
      print('[HealthRepo] setRealTimeUpload(step) OK');
      await Future.delayed(const Duration(milliseconds: 500));
      await bleDataSource.setRealTimeUpload(
        enable,
        type: DeviceRealTimeDataType.combinedData,
      );
      print('[HealthRepo] setRealTimeUpload(combinedData) OK');
      return const Right(null);
    } catch (e) {
      print('[HealthRepo] setRealTimeUpload failed: $e');
      return Left(BleFailure(message: 'setRealTimeUpload failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> enableHealthMonitoring({
    int interval = 5,
  }) async {
    try {
      await bleDataSource.setHealthMonitoring(
        enable: true,
        interval: interval,
      );
      return const Right(null);
    } catch (e) {
      return Left(BleFailure(message: 'enableHealthMonitoring failed: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> enableTemperatureMonitoring({
    int interval = 5,
  }) async {
    try {
      // Temperature monitoring uses the same health monitoring mechanism
      await bleDataSource.setHealthMonitoring(
        enable: true,
        interval: interval,
      );
      return const Right(null);
    } catch (e) {
      return Left(
        BleFailure(message: 'enableTemperatureMonitoring failed: $e'),
      );
    }
  }

  // ─── Heart Rate History ────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<HeartRateRecord>>> getHeartRateHistory() async {
    try {
      final response =
          await bleDataSource.queryHealthData(HealthDataType.heartRate);
      final items = _extractList(response);
      final records = <HeartRateRecord>[];
      for (final item in items) {
        if (item is HeartRateDataInfo) {
          records.add(HeartRateRecord(
            bpm: item.heartRate,
            minBpm: item.heartRate,
            maxBpm: item.heartRate,
            time: DateTime.fromMillisecondsSinceEpoch(
              item.startTimeStamp * 1000,
            ),
          ));
        }
      }
      return Right(records);
    } catch (e) {
      return Left(BleFailure(message: 'getHeartRateHistory failed: $e'));
    }
  }

  // ─── Step History ──────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<StepRecord>>> getStepHistory() async {
    try {
      // Only query step-specific data (type=0).
      // If this returns 0, combinedData fallback is handled by getCombinedDataAll() in DashboardBloc.
      final response = await bleDataSource.queryHealthData(HealthDataType.step);
      print(
          '[HealthRepo] getStepHistory raw response length: ${response?.length}');
      final items = _extractList(response);
      final records = <StepRecord>[];
      for (final item in items) {
        if (item is StepDataInfo) {
          records.add(StepRecord(
            steps: item.step,
            calories: item.calories,
            distanceKm: item.distance / 1000.0,
            date: DateTime.fromMillisecondsSinceEpoch(
              item.startTimeStamp * 1000,
            ),
          ));
        }
      }
      return Right(records);
    } catch (e) {
      print('[HealthRepo] getStepHistory error: $e');
      return Left(BleFailure(message: 'getStepHistory failed: $e'));
    }
  }

  // ─── Sleep History ─────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<SleepRecord>>> getSleepHistory() async {
    try {
      final response =
          await bleDataSource.queryHealthData(HealthDataType.sleep);
      final items = _extractList(response);
      final records = <SleepRecord>[];
      for (final item in items) {
        if (item is SleepDataInfo) {
          records.add(SleepRecord(
            deepMinutes: (item.deepSleepSeconds / 60).round(),
            lightMinutes: (item.lightSleepSeconds / 60).round(),
            remMinutes: (item.remSleepSeconds / 60).round(),
            awakeMinutes: 0, // SDK does not provide separate awake field
            startTime: DateTime.fromMillisecondsSinceEpoch(
              item.startTimeStamp * 1000,
            ),
            endTime: DateTime.fromMillisecondsSinceEpoch(
              item.endTimeStamp * 1000,
            ),
          ));
        }
      }
      return Right(records);
    } catch (e) {
      return Left(BleFailure(message: 'getSleepHistory failed: $e'));
    }
  }

  // ─── Blood Oxygen History ──────────────────────────────────────────────

  @override
  Future<Either<Failure, List<BloodOxygenRecord>>>
      getBloodOxygenHistory() async {
    try {
      final response =
          await bleDataSource.queryHealthData(HealthDataType.combinedData);
      final items = _extractList(response);
      final records = <BloodOxygenRecord>[];
      for (final item in items) {
        if (item is CombinedDataDataInfo && item.bloodOxygen > 0) {
          records.add(BloodOxygenRecord(
            spo2: item.bloodOxygen,
            time: DateTime.fromMillisecondsSinceEpoch(
              item.startTimeStamp * 1000,
            ),
          ));
        }
      }
      return Right(records);
    } catch (e) {
      return Left(BleFailure(message: 'getBloodOxygenHistory failed: $e'));
    }
  }

  // ─── Blood Pressure History ────────────────────────────────────────────

  @override
  Future<Either<Failure, List<BloodPressureRecord>>>
      getBloodPressureHistory() async {
    try {
      final response =
          await bleDataSource.queryHealthData(HealthDataType.bloodPressure);
      final items = _extractList(response);
      final records = <BloodPressureRecord>[];
      for (final item in items) {
        if (item is BloodPressureDataInfo) {
          records.add(BloodPressureRecord(
            systolic: item.systolicBloodPressure,
            diastolic: item.diastolicBloodPressure,
            time: DateTime.fromMillisecondsSinceEpoch(
              item.startTimeStamp * 1000,
            ),
          ));
        }
      }
      return Right(records);
    } catch (e) {
      return Left(BleFailure(message: 'getBloodPressureHistory failed: $e'));
    }
  }

  // ─── Temperature History ───────────────────────────────────────────────

  @override
  Future<Either<Failure, List<TemperatureRecord>>>
      getTemperatureHistory() async {
    try {
      final response =
          await bleDataSource.queryHealthData(HealthDataType.combinedData);
      final items = _extractList(response);
      final records = <TemperatureRecord>[];
      for (final item in items) {
        if (item is CombinedDataDataInfo && item.temperature > 0) {
          records.add(TemperatureRecord(
            celsius: item.temperature,
            time: DateTime.fromMillisecondsSinceEpoch(
              item.startTimeStamp * 1000,
            ),
          ));
        }
      }
      return Right(records);
    } catch (e) {
      return Left(BleFailure(message: 'getTemperatureHistory failed: $e'));
    }
  }

  // ─── Blood Glucose History ──────────────────────────────────────────────

  @override
  Future<Either<Failure, List<BloodGlucoseRecord>>>
      getBloodGlucoseHistory() async {
    try {
      final response =
          await bleDataSource.queryHealthData(HealthDataType.combinedData);
      final items = _extractList(response);
      final records = <BloodGlucoseRecord>[];
      for (final item in items) {
        if (item is CombinedDataDataInfo && item.bloodGlucose > 0) {
          records.add(BloodGlucoseRecord(
            glucoseMmol: item.bloodGlucose,
            time: DateTime.fromMillisecondsSinceEpoch(
              item.startTimeStamp * 1000,
            ),
          ));
        }
      }
      print('[HealthRepo] getBloodGlucoseHistory: ${records.length} records');
      return Right(records);
    } catch (e) {
      return Left(BleFailure(message: 'getBloodGlucoseHistory failed: $e'));
    }
  }
  // ─── Combined Data (single query) ──────────────────────────────────────

  @override
  Future<
      Either<
          Failure,
          ({
            List<StepRecord> steps,
            List<TemperatureRecord> temps,
            List<BloodGlucoseRecord> glucose,
            List<BloodOxygenRecord> spo2
          })>> getCombinedDataAll() async {
    try {
      final response =
          await bleDataSource.queryHealthData(HealthDataType.combinedData);
      final items = _extractList(response);
      print(
          '[HealthRepo] getCombinedDataAll: ${items.length} combinedData items');

      final stepDayMap = <String, StepRecord>{};
      final temps = <TemperatureRecord>[];
      final glucose = <BloodGlucoseRecord>[];
      final spo2 = <BloodOxygenRecord>[];

      for (final item in items) {
        if (item is CombinedDataDataInfo) {
          final date =
              DateTime.fromMillisecondsSinceEpoch(item.startTimeStamp * 1000);

          // Steps: aggregate per-day, keep highest cumulative count
          if (item.step > 0) {
            final dayKey = '${date.year}-${date.month}-${date.day}';
            final existing = stepDayMap[dayKey];
            if (existing == null || item.step > existing.steps) {
              stepDayMap[dayKey] = StepRecord(
                steps: item.step,
                calories: StepRecord.estimateCalories(item.step),
                distanceKm: StepRecord.estimateDistanceKm(item.step),
                date: date,
              );
            }
          }

          // Temperature: filter out bogus 0.15 readings
          if (item.temperature > 30.0) {
            temps.add(TemperatureRecord(celsius: item.temperature, time: date));
          }

          // Blood glucose
          if (item.bloodGlucose > 0) {
            glucose.add(
                BloodGlucoseRecord(glucoseMmol: item.bloodGlucose, time: date));
          }

          // Blood oxygen (SpO2)
          if (item.bloodOxygen > 0) {
            spo2.add(BloodOxygenRecord(spo2: item.bloodOxygen, time: date));
          }
        }
      }

      final steps = stepDayMap.values.toList();
      print(
          '[HealthRepo] getCombinedDataAll results: ${steps.length} step days, ${temps.length} temps, ${glucose.length} glucose, ${spo2.length} spo2');
      return Right((steps: steps, temps: temps, glucose: glucose, spo2: spo2));
    } catch (e) {
      print('[HealthRepo] getCombinedDataAll error: $e');
      return Left(BleFailure(message: 'getCombinedDataAll failed: $e'));
    }
  }

  // ─── On-Demand Measurement ─────────────────────────────────────────────

  @override
  Future<Either<Failure, bool>> startMeasurement(MeasurementType type) async {
    try {
      final sdkType = _toSdkMeasurementType(type);
      await bleDataSource.startMeasurement(sdkType);
      return const Right(true);
    } catch (e) {
      return Left(BleFailure(message: 'startMeasurement failed: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> stopMeasurement(MeasurementType type) async {
    try {
      final sdkType = _toSdkMeasurementType(type);
      await bleDataSource.stopMeasurement(sdkType);
      return const Right(true);
    } catch (e) {
      return Left(BleFailure(message: 'stopMeasurement failed: $e'));
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  /// Extract items from a raw health-data response.
  /// Now receives `List?` directly from BleManager.queryHealthHistory.
  List _extractList(List? data) {
    if (data == null) return [];
    return data;
  }

  DeviceAppControlMeasureHealthDataType _toSdkMeasurementType(
    MeasurementType type,
  ) {
    switch (type) {
      case MeasurementType.heartRate:
        return DeviceAppControlMeasureHealthDataType.heartRate;
      case MeasurementType.bloodPressure:
        return DeviceAppControlMeasureHealthDataType.bloodPressure;
      case MeasurementType.bloodOxygen:
        return DeviceAppControlMeasureHealthDataType.bloodOxygen;
      case MeasurementType.bodyTemperature:
        return DeviceAppControlMeasureHealthDataType.bodyTemperature;
      case MeasurementType.bloodGlucose:
        return DeviceAppControlMeasureHealthDataType.bloodGlucose;
    }
  }
}
