import 'package:equatable/equatable.dart';

/// Domain entity representing a snapshot of all real-time health data
/// received from the wearable device.
///
/// Fields are nullable — only non-null fields indicate a fresh reading.
class HealthReading extends Equatable {
  final int? heartRate;
  final int? spo2;
  final int? systolic;
  final int? diastolic;
  final double? temperature;
  final int? steps;
  final int? calories;
  final double? distanceKm;
  final int? stressLevel;
  final double? bloodGlucose;
  final DateTime timestamp;

  const HealthReading({
    this.heartRate,
    this.spo2,
    this.systolic,
    this.diastolic,
    this.temperature,
    this.steps,
    this.calories,
    this.distanceKm,
    this.stressLevel,
    this.bloodGlucose,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        heartRate,
        spo2,
        systolic,
        diastolic,
        temperature,
        steps,
        calories,
        distanceKm,
        stressLevel,
        bloodGlucose,
        timestamp,
      ];
}

/// Domain entity for a single historical heart rate record.
class HeartRateRecord extends Equatable {
  final int bpm;
  final int minBpm;
  final int maxBpm;
  final DateTime time;

  const HeartRateRecord({
    required this.bpm,
    required this.minBpm,
    required this.maxBpm,
    required this.time,
  });

  @override
  List<Object?> get props => [bpm, minBpm, maxBpm, time];
}

/// Domain entity for a single historical step record.
class StepRecord extends Equatable {
  final int steps;
  final int calories;
  final double distanceKm;
  final DateTime date;

  const StepRecord({
    required this.steps,
    required this.calories,
    required this.distanceKm,
    required this.date,
  });

  @override
  List<Object?> get props => [steps, calories, distanceKm, date];

  /// Estimate calories from step count (approx 0.04 kcal/step for average person)
  static int estimateCalories(int steps) => (steps * 0.04).round();

  /// Estimate distance in km from step count (avg stride ~0.762m)
  static double estimateDistanceKm(int steps) => (steps * 0.762) / 1000.0;
}

/// Domain entity for blood glucose history.
class BloodGlucoseRecord extends Equatable {
  final double glucoseMmol;
  final DateTime time;

  const BloodGlucoseRecord({required this.glucoseMmol, required this.time});

  @override
  List<Object?> get props => [glucoseMmol, time];
}

/// Domain entity for a single historical sleep record.
class SleepRecord extends Equatable {
  final int deepMinutes;
  final int lightMinutes;
  final int remMinutes;
  final int awakeMinutes;
  final DateTime startTime;
  final DateTime endTime;

  const SleepRecord({
    required this.deepMinutes,
    required this.lightMinutes,
    required this.remMinutes,
    required this.awakeMinutes,
    required this.startTime,
    required this.endTime,
  });

  int get totalMinutes => deepMinutes + lightMinutes + remMinutes;

  @override
  List<Object?> get props =>
      [deepMinutes, lightMinutes, remMinutes, awakeMinutes, startTime, endTime];
}

/// Domain entity for blood oxygen history.
class BloodOxygenRecord extends Equatable {
  final int spo2;
  final DateTime time;

  const BloodOxygenRecord({required this.spo2, required this.time});

  @override
  List<Object?> get props => [spo2, time];
}

/// Domain entity for blood pressure history.
class BloodPressureRecord extends Equatable {
  final int systolic;
  final int diastolic;
  final DateTime time;

  const BloodPressureRecord({
    required this.systolic,
    required this.diastolic,
    required this.time,
  });

  @override
  List<Object?> get props => [systolic, diastolic, time];
}

/// Domain entity for temperature history.
class TemperatureRecord extends Equatable {
  final double celsius;
  final DateTime time;

  const TemperatureRecord({required this.celsius, required this.time});

  @override
  List<Object?> get props => [celsius, time];
}

/// ECG waveform single point.
class EcgPoint extends Equatable {
  final double value;
  final double filteredValue;
  final int index;

  const EcgPoint({
    required this.value,
    required this.filteredValue,
    required this.index,
  });

  @override
  List<Object?> get props => [value, filteredValue, index];
}

/// ECG measurement result.
class EcgResult extends Equatable {
  final int heartRate;
  final double? hrvNorm;
  final int? respiratoryRate;
  final int qrsType;
  final bool afFlag;

  const EcgResult({
    required this.heartRate,
    this.hrvNorm,
    this.respiratoryRate,
    required this.qrsType,
    required this.afFlag,
  });

  @override
  List<Object?> get props =>
      [heartRate, hrvNorm, respiratoryRate, qrsType, afFlag];
}
