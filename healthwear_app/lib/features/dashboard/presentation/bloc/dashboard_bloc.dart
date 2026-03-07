import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/health_data.dart';
import '../../domain/repositories/health_repository.dart';
import '../../../../core/services/health_hive_service.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final HealthRepository _healthRepo;
  StreamSubscription<HealthReading>? _healthSub;
  DateTime? _lastHiveSave;

  DashboardBloc({required HealthRepository healthRepository})
      : _healthRepo = healthRepository,
        super(const DashboardState()) {
    on<LoadHealthData>(_onLoadHealthData);
    on<StartRealTimeMonitoring>(_onStartRealTime);
    on<RealTimeHealthUpdate>(_onRealTimeUpdate);
    on<RefreshMetric>(_onRefreshMetric);
    on<BackgroundSyncComplete>(_onBackgroundSyncComplete);
    on<RefreshData>(_onRefreshData);
  }

  Future<void> _onLoadHealthData(
    LoadHealthData event,
    Emitter<DashboardState> emit,
  ) async {
    // Phase 0: Instant Hive load — show cached data immediately
    final hiveHr = HealthHiveService.getHeartRateRecords();
    final hiveSteps = HealthHiveService.getStepRecords();
    final hiveSleep = HealthHiveService.getSleepRecords();
    final hiveSpo2 = HealthHiveService.getBloodOxygenRecords();
    final hiveBp = HealthHiveService.getBloodPressureRecords();
    final hiveTemp = HealthHiveService.getTemperatureRecords();
    final hiveGlu = HealthHiveService.getBloodGlucoseRecords();

    final hasHiveData = hiveHr.isNotEmpty || hiveSteps.isNotEmpty;
    if (hasHiveData) {
      emit(state.copyWith(
        status: DashboardStatus.loaded,
        heartRateHistory: hiveHr,
        stepHistory: hiveSteps,
        sleepHistory: hiveSleep,
        bloodOxygenHistory: hiveSpo2,
        bloodPressureHistory: hiveBp,
        temperatureHistory: hiveTemp,
        bloodGlucoseHistory: hiveGlu,
      ));
      print(
          '[DashboardBloc] Phase 0: Loaded ${hiveHr.length} HR, ${hiveSteps.length} steps from Hive');
    } else {
      emit(state.copyWith(status: DashboardStatus.loading));
    }

    // Phase 1: Fresh ring sync (runs in background)
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

    // Persist the freshly-synced data to Hive for offline access
    _saveAllToHive(state);
  }

  /// Persist current state's health records to Hive.
  void _saveAllToHive(DashboardState s) {
    HealthHiveService.saveHeartRateRecords(s.heartRateHistory);
    HealthHiveService.saveStepRecords(s.stepHistory);
    HealthHiveService.saveSleepRecords(s.sleepHistory);
    HealthHiveService.saveBloodOxygenRecords(s.bloodOxygenHistory);
    HealthHiveService.saveBloodPressureRecords(s.bloodPressureHistory);
    HealthHiveService.saveTemperatureRecords(s.temperatureHistory);
    HealthHiveService.saveBloodGlucoseRecords(s.bloodGlucoseHistory);
    print('[DashboardBloc] Synced data saved to Hive');
  }

  Future<void> _onStartRealTime(
    StartRealTimeMonitoring event,
    Emitter<DashboardState> emit,
  ) async {
    print('[DashboardBloc] _onStartRealTime entered');
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

    // No periodic timer — foreground service handles background syncs
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

    // Throttle: save real-time readings to Hive at most once per 60 seconds
    final now = DateTime.now();
    if (_lastHiveSave != null &&
        now.difference(_lastHiveSave!) < const Duration(seconds: 60)) {
      return; // Skip this save cycle
    }
    _lastHiveSave = now;

    if (d['heartRate'] is num && (d['heartRate'] as num).toInt() > 0) {
      HealthHiveService.saveRealtimeHeartRate((d['heartRate'] as num).toInt());
    }
    if (d['spo2'] is num && (d['spo2'] as num).toInt() > 0) {
      HealthHiveService.saveRealtimeSpO2((d['spo2'] as num).toInt());
    }
    if (d['temperature'] is num && (d['temperature'] as num).toDouble() > 0) {
      HealthHiveService.saveRealtimeTemperature(
          (d['temperature'] as num).toDouble());
    }
    if (d['systolic'] is num && (d['systolic'] as num).toInt() > 0) {
      HealthHiveService.saveRealtimeBP(
        (d['systolic'] as num).toInt(),
        (d['diastolic'] as num).toInt(),
      );
    }
    if (d['bloodGlucose'] is num && (d['bloodGlucose'] as num).toDouble() > 0) {
      HealthHiveService.saveRealtimeGlucose(
          (d['bloodGlucose'] as num).toDouble());
    }
    print('[DashboardBloc] Real-time data saved to Hive (throttled)');
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

  /// Reload all data from Hive after a background service sync.
  Future<void> _onBackgroundSyncComplete(
    BackgroundSyncComplete event,
    Emitter<DashboardState> emit,
  ) async {
    print('[DashboardBloc] BackgroundSyncComplete — reloading from Hive');
    final hrRecords = HealthHiveService.getHeartRateRecords();
    final stepRecords = HealthHiveService.getStepRecords();
    final sleepRecords = HealthHiveService.getSleepRecords();
    final spo2Records = HealthHiveService.getBloodOxygenRecords();
    final bpRecords = HealthHiveService.getBloodPressureRecords();
    final tempRecords = HealthHiveService.getTemperatureRecords();
    final glucoseRecords = HealthHiveService.getBloodGlucoseRecords();

    // Debug: print last 5 HR record timestamps to see interval pattern
    if (hrRecords.isNotEmpty) {
      final last5 = hrRecords.length > 5
          ? hrRecords.sublist(hrRecords.length - 5)
          : hrRecords;
      for (final r in last5) {
        print('[DashboardBloc] HR record: ${r.bpm} bpm at ${r.time}');
      }
    }
    if (tempRecords.isNotEmpty) {
      final latest = tempRecords.last;
      print('[DashboardBloc] Latest Temp: ${latest.celsius} at ${latest.time}');
    }
    if (spo2Records.isNotEmpty) {
      final latest = spo2Records.last;
      print('[DashboardBloc] Latest SpO2: ${latest.spo2}% at ${latest.time}');
    }
    print(
        '[DashboardBloc] Record counts — HR:${hrRecords.length} Steps:${stepRecords.length} Temp:${tempRecords.length} SpO2:${spo2Records.length} BP:${bpRecords.length} Glu:${glucoseRecords.length}');

    emit(state.copyWith(
      status: DashboardStatus.loaded,
      heartRateHistory: hrRecords,
      stepHistory: stepRecords,
      sleepHistory: sleepRecords,
      bloodOxygenHistory: spo2Records,
      bloodPressureHistory: bpRecords,
      temperatureHistory: tempRecords,
      bloodGlucoseHistory: glucoseRecords,
    ));
    print('[DashboardBloc] All Hive data reloaded into state');
  }

  /// Pull-to-refresh: instantly reload latest data from Hive.
  /// Heavy BLE queries are done by the foreground service (every 2 min).
  Future<void> _onRefreshData(
    RefreshData event,
    Emitter<DashboardState> emit,
  ) async {
    print('[DashboardBloc] RefreshData — reloading from Hive...');
    emit(state.copyWith(
      status: DashboardStatus.loaded,
      heartRateHistory: HealthHiveService.getHeartRateRecords(),
      stepHistory: HealthHiveService.getStepRecords(),
      sleepHistory: HealthHiveService.getSleepRecords(),
      bloodOxygenHistory: HealthHiveService.getBloodOxygenRecords(),
      bloodPressureHistory: HealthHiveService.getBloodPressureRecords(),
      temperatureHistory: HealthHiveService.getTemperatureRecords(),
      bloodGlucoseHistory: HealthHiveService.getBloodGlucoseRecords(),
    ));
    print('[DashboardBloc] RefreshData complete — instant Hive reload');
  }

  @override
  Future<void> close() {
    _healthSub?.cancel();
    return super.close();
  }
}
