import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/health_hive_service.dart';
import '../../domain/entities/health_data.dart';
import '../../domain/repositories/health_repository.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final HealthRepository _healthRepo;
  StreamSubscription<HealthReading>? _healthSub;

  DashboardBloc({required HealthRepository healthRepository})
      : _healthRepo = healthRepository,
        super(const DashboardState()) {
    on<LoadHealthData>(_onLoadHealthData);
    on<StartRealTimeMonitoring>(_onStartRealTime);
    on<RealTimeHealthUpdate>(_onRealTimeUpdate);
    on<RefreshMetric>(_onRefreshMetric);
    on<BackgroundSyncComplete>(_onBackgroundSyncComplete);
  }

  Future<void> _onLoadHealthData(
    LoadHealthData event,
    Emitter<DashboardState> emit,
  ) async {
    // Phase 0: Instantly load cached data from Hive (available offline)
    emit(state.copyWith(
      status: DashboardStatus.loading,
      heartRateHistory: HealthHiveService.getHeartRateRecords(),
      stepHistory: HealthHiveService.getStepRecords(),
      sleepHistory: HealthHiveService.getSleepRecords(),
      bloodOxygenHistory: HealthHiveService.getBloodOxygenRecords(),
      bloodPressureHistory: HealthHiveService.getBloodPressureRecords(),
      temperatureHistory: HealthHiveService.getTemperatureRecords(),
      bloodGlucoseHistory: HealthHiveService.getBloodGlucoseRecords(),
    ));
    print('[DashboardBloc] Phase 0: Loaded cached data from Hive');

    // Phase 1: Load non-combinedData histories in parallel
    // (Only queries that DON'T use HealthDataType.combinedData)
    final results = await Future.wait([
      _healthRepo.getHeartRateHistory(), // 0
      _healthRepo.getStepHistory(), // 1 (step-specific type=0 only)
      _healthRepo.getSleepHistory(), // 2
      _healthRepo.getBloodPressureHistory(), // 3
    ]);

    final hrResult = results[0];
    final stepResult = results[1];
    final sleepResult = results[2];
    final bpResult = results[3];

    // Phase 2: Query combinedData ONCE for step-fallback/temp/glucose/spo2
    final combinedResult = await _healthRepo.getCombinedDataAll();

    // Extract step history: prefer step-specific query, fallback to combinedData
    List<StepRecord> finalSteps = stepResult.fold(
      (_) => state.stepHistory,
      (data) => data as List<StepRecord>,
    );

    List<TemperatureRecord> finalTemps = state.temperatureHistory;
    List<BloodGlucoseRecord> finalGlucose = state.bloodGlucoseHistory;
    List<BloodOxygenRecord> finalSpo2 = state.bloodOxygenHistory;

    combinedResult.fold(
      (_) {},
      (combined) {
        // Use combinedData steps if they have a higher count
        // (step-specific query often returns stale/low counts on this device)
        final stepSpecificMax = finalSteps.isEmpty
            ? 0
            : finalSteps.map((s) => s.steps).reduce((a, b) => a > b ? a : b);
        final combinedMax = combined.steps.isEmpty
            ? 0
            : combined.steps
                .map((s) => s.steps)
                .reduce((a, b) => a > b ? a : b);
        if (combinedMax > stepSpecificMax) {
          finalSteps = combined.steps;
          print(
              '[DashboardBloc] Using combinedData steps (max=$combinedMax > step-specific max=$stepSpecificMax)');
        }
        finalTemps = combined.temps;
        finalGlucose = combined.glucose;
        finalSpo2 = combined.spo2;
      },
    );

    print('[DashboardBloc] Step history synced: ${finalSteps.length} records');
    if (finalSteps.isNotEmpty) {
      print(
          '[DashboardBloc] Latest step record: steps=${finalSteps.last.steps}, cal=${finalSteps.last.calories}, dist=${finalSteps.last.distanceKm}');
    }
    print(
        '[DashboardBloc] Blood glucose history: ${finalGlucose.length} records');

    final sleepRecords = sleepResult.fold(
        (_) => state.sleepHistory, (data) => data as List<SleepRecord>);
    print('[DashboardBloc] Sleep history: ${sleepRecords.length} records');
    if (sleepRecords.isNotEmpty) {
      final latest = sleepRecords.last;
      print(
          '[DashboardBloc] Latest sleep: deep=${latest.deepMinutes}min, light=${latest.lightMinutes}min, rem=${latest.remMinutes}min, total=${latest.totalMinutes}min, start=${latest.startTime}, end=${latest.endTime}');
    }

    emit(state.copyWith(
      status: DashboardStatus.loaded,
      heartRateHistory: hrResult.fold((_) => state.heartRateHistory,
          (data) => data as List<HeartRateRecord>),
      stepHistory: finalSteps,
      sleepHistory: sleepResult.fold(
          (_) => state.sleepHistory, (data) => data as List<SleepRecord>),
      bloodOxygenHistory: finalSpo2,
      bloodPressureHistory: bpResult.fold((_) => state.bloodPressureHistory,
          (data) => data as List<BloodPressureRecord>),
      temperatureHistory: finalTemps,
      bloodGlucoseHistory: finalGlucose,
    ));

    // Save fresh ring data to Hive for offline access
    hrResult.fold(
        (_) {},
        (d) =>
            HealthHiveService.saveHeartRateRecords(d as List<HeartRateRecord>));
    HealthHiveService.saveStepRecords(finalSteps);
    sleepResult.fold((_) {},
        (d) => HealthHiveService.saveSleepRecords(d as List<SleepRecord>));
    HealthHiveService.saveBloodOxygenRecords(finalSpo2);
    bpResult.fold(
        (_) {},
        (d) => HealthHiveService.saveBloodPressureRecords(
            d as List<BloodPressureRecord>));
    HealthHiveService.saveTemperatureRecords(finalTemps);
    HealthHiveService.saveBloodGlucoseRecords(finalGlucose);
    print('[DashboardBloc] Ring data saved to Hive');
  }

  Future<void> _onStartRealTime(
    StartRealTimeMonitoring event,
    Emitter<DashboardState> emit,
  ) async {
    // IMPORTANT: Subscribe to the real-time stream FIRST before any SDK
    // await calls that could hang (BLE commands sometimes time out).
    _healthSub?.cancel();
    _healthSub = _healthRepo.streamRealTimeHealth().listen(
      (reading) {
        print(
            '[DashboardBloc] Real-time reading: HR=${reading.heartRate} SpO2=${reading.spo2} Temp=${reading.temperature} BP=${reading.systolic}/${reading.diastolic} Steps=${reading.steps} Glucose=${reading.bloodGlucose}');
        add(RealTimeHealthUpdate({
          'heartRate': reading.heartRate,
          'steps': reading.steps,
          'spo2': reading.spo2,
          'temperature': reading.temperature,
          'systolic': reading.systolic,
          'diastolic': reading.diastolic,
          'stressLevel': reading.stressLevel,
          'bloodGlucose': reading.bloodGlucose,
          'calories': reading.calories,
          'distanceKm': reading.distanceKm,
        }));
      },
      onError: (e) => print('[DashboardBloc] Stream error: $e'),
    );

    // Now enable SDK features non-blocking (connect already enables these,
    // but we re-enable in case the connection was re-established).
    // Repository internally enables BOTH step and combinedData types.
    _healthRepo.setRealTimeUpload(true).then((_) {
      print('[DashboardBloc] setRealTimeUpload OK (step + combinedData)');
    }).catchError((e) {
      print('[DashboardBloc] setRealTimeUpload failed: $e');
    });
    _healthRepo.enableHealthMonitoring().then((_) {
      print('[DashboardBloc] enableHealthMonitoring OK');
    }).catchError((e) {
      print('[DashboardBloc] enableHealthMonitoring failed: $e');
    });

    // Note: periodic refresh removed — foreground service handles 15-min sync
    // Dashboard only loads data on initial connect + real-time BLE stream
  }

  void _onRealTimeUpdate(
    RealTimeHealthUpdate event,
    Emitter<DashboardState> emit,
  ) {
    final d = event.data;

    // Only update a field if the reading is non-null.
    // Use is num to handle both int and double from SDK.
    emit(state.copyWith(
      liveHeartRate:
          d['heartRate'] is num && (d['heartRate'] as num).toInt() > 0
              ? (d['heartRate'] as num).toInt()
              : state.liveHeartRate,
      liveSteps:
          d['steps'] is num ? (d['steps'] as num).toInt() : state.liveSteps,
      liveSpO2: d['spo2'] is num && (d['spo2'] as num).toInt() > 0
          ? (d['spo2'] as num).toInt()
          : state.liveSpO2,
      liveTemperature:
          d['temperature'] is num && (d['temperature'] as num).toDouble() > 0
              ? (d['temperature'] as num).toDouble()
              : state.liveTemperature,
      liveSystolic: d['systolic'] is num && (d['systolic'] as num).toInt() > 0
          ? (d['systolic'] as num).toInt()
          : state.liveSystolic,
      liveDiastolic:
          d['diastolic'] is num && (d['diastolic'] as num).toInt() > 0
              ? (d['diastolic'] as num).toInt()
              : state.liveDiastolic,
      liveStress:
          d['stressLevel'] is num && (d['stressLevel'] as num).toInt() > 0
              ? (d['stressLevel'] as num).toInt()
              : state.liveStress,
      liveBloodGlucose:
          d['bloodGlucose'] is num && (d['bloodGlucose'] as num).toDouble() > 0
              ? (d['bloodGlucose'] as num).toDouble()
              : state.liveBloodGlucose,
      liveCalories: d['calories'] is num
          ? (d['calories'] as num).toInt()
          : state.liveCalories,
      liveDistance: d['distanceKm'] is num
          ? (d['distanceKm'] as num).toDouble()
          : state.liveDistance,
    ));

    // ── Phase 2: Save real-time readings to Hive for history ──
    if (d['heartRate'] is num && (d['heartRate'] as num).toInt() > 0) {
      HealthHiveService.saveRealtimeHeartRate((d['heartRate'] as num).toInt());
    }
    if (d['spo2'] is num && (d['spo2'] as num).toInt() > 0) {
      HealthHiveService.saveRealtimeSpO2((d['spo2'] as num).toInt());
    }
    if (d['systolic'] is num &&
        (d['systolic'] as num).toInt() > 0 &&
        d['diastolic'] is num &&
        (d['diastolic'] as num).toInt() > 0) {
      HealthHiveService.saveRealtimeBP(
        (d['systolic'] as num).toInt(),
        (d['diastolic'] as num).toInt(),
      );
    }
    if (d['temperature'] is num && (d['temperature'] as num).toDouble() > 0) {
      HealthHiveService.saveRealtimeTemperature(
        (d['temperature'] as num).toDouble(),
      );
    }
    if (d['bloodGlucose'] is num && (d['bloodGlucose'] as num).toDouble() > 0) {
      HealthHiveService.saveRealtimeGlucose(
        (d['bloodGlucose'] as num).toDouble(),
      );
    }
  }

  Future<void> _onRefreshMetric(
    RefreshMetric event,
    Emitter<DashboardState> emit,
  ) async {
    switch (event.metricType) {
      case 'heartRate':
        final result = await _healthRepo.getHeartRateHistory();
        result.fold((_) {}, (data) {
          emit(state.copyWith(heartRateHistory: data));
        });
        break;
      case 'steps':
        final result = await _healthRepo.getStepHistory();
        result.fold((_) {}, (data) {
          emit(state.copyWith(stepHistory: data));
        });
        break;
      case 'sleep':
        final result = await _healthRepo.getSleepHistory();
        result.fold((_) {}, (data) {
          emit(state.copyWith(sleepHistory: data));
        });
        break;
    }
  }

  /// Foreground service completed a background sync — reload from Hive.
  void _onBackgroundSyncComplete(
    BackgroundSyncComplete event,
    Emitter<DashboardState> emit,
  ) {
    print('[DashboardBloc] Background sync complete — reloading from Hive');
    emit(state.copyWith(
      heartRateHistory: HealthHiveService.getHeartRateRecords(),
      stepHistory: HealthHiveService.getStepRecords(),
      sleepHistory: HealthHiveService.getSleepRecords(),
      bloodOxygenHistory: HealthHiveService.getBloodOxygenRecords(),
      bloodPressureHistory: HealthHiveService.getBloodPressureRecords(),
      temperatureHistory: HealthHiveService.getTemperatureRecords(),
      bloodGlucoseHistory: HealthHiveService.getBloodGlucoseRecords(),
    ));
  }

  @override
  Future<void> close() {
    _healthSub?.cancel();
    return super.close();
  }
}
