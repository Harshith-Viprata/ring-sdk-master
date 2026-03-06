part of 'dashboard_bloc.dart';

enum DashboardStatus { initial, loading, loaded, error }

class DashboardState extends Equatable {
  final DashboardStatus status;
  final List<HeartRateRecord> heartRateHistory;
  final List<StepRecord> stepHistory;
  final List<SleepRecord> sleepHistory;
  final List<BloodOxygenRecord> bloodOxygenHistory;
  final List<BloodPressureRecord> bloodPressureHistory;
  final List<TemperatureRecord> temperatureHistory;

  // Live real-time values
  final int? liveHeartRate;
  final int? liveSteps;
  final int? liveSpO2;
  final double? liveTemperature;
  final int? liveSystolic;
  final int? liveDiastolic;
  final int? liveStress;
  final double? liveBloodGlucose;
  final int? liveCalories;
  final double? liveDistance;

  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.heartRateHistory = const [],
    this.stepHistory = const [],
    this.sleepHistory = const [],
    this.bloodOxygenHistory = const [],
    this.bloodPressureHistory = const [],
    this.temperatureHistory = const [],
    this.liveHeartRate,
    this.liveSteps,
    this.liveSpO2,
    this.liveTemperature,
    this.liveSystolic,
    this.liveDiastolic,
    this.liveStress,
    this.liveBloodGlucose,
    this.liveCalories,
    this.liveDistance,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardStatus? status,
    List<HeartRateRecord>? heartRateHistory,
    List<StepRecord>? stepHistory,
    List<SleepRecord>? sleepHistory,
    List<BloodOxygenRecord>? bloodOxygenHistory,
    List<BloodPressureRecord>? bloodPressureHistory,
    List<TemperatureRecord>? temperatureHistory,
    int? liveHeartRate,
    int? liveSteps,
    int? liveSpO2,
    double? liveTemperature,
    int? liveSystolic,
    int? liveDiastolic,
    int? liveStress,
    double? liveBloodGlucose,
    int? liveCalories,
    double? liveDistance,
    String? errorMessage,
  }) {
    return DashboardState(
      status: status ?? this.status,
      heartRateHistory: heartRateHistory ?? this.heartRateHistory,
      stepHistory: stepHistory ?? this.stepHistory,
      sleepHistory: sleepHistory ?? this.sleepHistory,
      bloodOxygenHistory: bloodOxygenHistory ?? this.bloodOxygenHistory,
      bloodPressureHistory: bloodPressureHistory ?? this.bloodPressureHistory,
      temperatureHistory: temperatureHistory ?? this.temperatureHistory,
      liveHeartRate: liveHeartRate ?? this.liveHeartRate,
      liveSteps: liveSteps ?? this.liveSteps,
      liveSpO2: liveSpO2 ?? this.liveSpO2,
      liveTemperature: liveTemperature ?? this.liveTemperature,
      liveSystolic: liveSystolic ?? this.liveSystolic,
      liveDiastolic: liveDiastolic ?? this.liveDiastolic,
      liveStress: liveStress ?? this.liveStress,
      liveBloodGlucose: liveBloodGlucose ?? this.liveBloodGlucose,
      liveCalories: liveCalories ?? this.liveCalories,
      liveDistance: liveDistance ?? this.liveDistance,
      errorMessage: errorMessage,
    );
  }

  /// Today's total steps from history.
  int get todaySteps {
    final now = DateTime.now();
    int sum = 0;
    for (final r in stepHistory) {
      if (r.date.year == now.year &&
          r.date.month == now.month &&
          r.date.day == now.day) {
        sum += r.steps;
      }
    }
    return liveSteps != null && liveSteps! > sum ? liveSteps! : sum;
  }

  /// Today's calories (live or from history).
  int get todayCalories {
    if (liveCalories != null && liveCalories! > 0) return liveCalories!;
    final now = DateTime.now();
    for (final r in stepHistory.reversed) {
      if (r.date.year == now.year &&
          r.date.month == now.month &&
          r.date.day == now.day) {
        return r.calories;
      }
    }
    return 0;
  }

  /// Today's distance (live or from history).
  double get todayDistance {
    if (liveDistance != null && liveDistance! > 0) return liveDistance!;
    final now = DateTime.now();
    for (final r in stepHistory.reversed) {
      if (r.date.year == now.year &&
          r.date.month == now.month &&
          r.date.day == now.day) {
        return r.distanceKm;
      }
    }
    return 0;
  }

  /// Latest heart rate value.
  int? get latestHeartRate {
    if (liveHeartRate != null && liveHeartRate! > 0) return liveHeartRate;
    if (heartRateHistory.isNotEmpty) return heartRateHistory.last.bpm;
    return null;
  }

  @override
  List<Object?> get props => [
        status,
        heartRateHistory,
        stepHistory,
        sleepHistory,
        bloodOxygenHistory,
        bloodPressureHistory,
        temperatureHistory,
        liveHeartRate,
        liveSteps,
        liveSpO2,
        liveTemperature,
        liveSystolic,
        liveDiastolic,
        liveStress,
        liveBloodGlucose,
        liveCalories,
        liveDistance,
        errorMessage,
      ];
}
