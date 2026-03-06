import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

import '../../../device/data/datasources/ble_data_source.dart';
import '../../domain/repositories/ecg_repository.dart';

part 'ecg_event.dart';
part 'ecg_state.dart';

class EcgBloc extends Bloc<EcgEvent, EcgState> {
  final BleDataSource _bleDataSource;
  final EcgRepository _ecgRepository;
  StreamSubscription<List<int>>? _filteredSub;
  StreamSubscription<Map<dynamic, dynamic>>? _rawSub;
  StreamSubscription<void>? _endSub;
  Timer? _timer;

  EcgBloc({
    required BleDataSource bleDataSource,
    required EcgRepository ecgRepository,
  })  : _bleDataSource = bleDataSource,
        _ecgRepository = ecgRepository,
        super(const EcgState()) {
    on<StartEcgMeasurement>(_onStart);
    on<StopEcgMeasurement>(_onStop);
    on<EcgDataReceived>(_onDataReceived);
    on<EcgCompleted>(_onCompleted);
    on<_EcgTimerTick>(_onTimerTick);
  }

  Future<void> _onStart(
    StartEcgMeasurement event,
    Emitter<EcgState> emit,
  ) async {
    emit(const EcgState(status: EcgStatus.measuring));

    try {
      final result = await _ecgRepository.startEcg();
      result.fold(
        (failure) {
          emit(EcgState(
            status: EcgStatus.error,
            errorMessage: failure.message,
          ));
        },
        (_) {
          // Listen for filtered ECG waveform data from repository stream
          _filteredSub?.cancel();
          _filteredSub =
              _ecgRepository.streamEcgFilteredData().listen((samples) {
            // Convert int samples to double for the waveform
            final doubleData = samples.map((s) => s.toDouble()).toList();
            add(EcgDataReceived({'ecgSamples': doubleData}));
          });

          // Listen for HR and HRV from raw event stream
          _rawSub?.cancel();
          _rawSub = _bleDataSource.eventStream
              .where((e) =>
                  e.containsKey(NativeEventType.deviceRealECGAlgorithmHRV) ||
                  e.containsKey(NativeEventType.deviceRealECGAlgorithmRR) ||
                  e.containsKey(NativeEventType.deviceRealECGData))
              .listen((event) {
            add(EcgDataReceived(event));
          });

          // Listen for ECG end signal
          _endSub?.cancel();
          _endSub = _ecgRepository.onEcgEnd().listen((_) {
            add(EcgCompleted());
          });

          // Timer to track elapsed time
          _timer?.cancel();
          _timer = Timer.periodic(const Duration(seconds: 1), (_) {
            add(_EcgTimerTick());
          });
        },
      );
    } catch (e) {
      emit(EcgState(
        status: EcgStatus.error,
        errorMessage: 'Failed to start ECG: $e',
      ));
    }
  }

  Future<void> _onStop(
    StopEcgMeasurement event,
    Emitter<EcgState> emit,
  ) async {
    _cancelSubscriptions();
    await _ecgRepository.stopEcg();
    emit(state.copyWith(status: EcgStatus.idle));
  }

  void _onTimerTick(
    _EcgTimerTick event,
    Emitter<EcgState> emit,
  ) {
    if (state.status == EcgStatus.measuring) {
      emit(state.copyWith(elapsedSeconds: state.elapsedSeconds + 1));
    }
  }

  void _onDataReceived(
    EcgDataReceived event,
    Emitter<EcgState> emit,
  ) {
    final data = event.rawData;

    // Filtered ECG waveform samples (from streamEcgFilteredData)
    if (data.containsKey('ecgSamples')) {
      final samples = data['ecgSamples'] as List<double>;
      final updated = List<double>.from(state.waveformData)..addAll(samples);
      // Keep last 500 points for smooth scrolling display
      if (updated.length > 500) {
        updated.removeRange(0, updated.length - 500);
      }
      emit(state.copyWith(waveformData: updated));
    }

    // Raw ECG data — may contain heartRate in the map
    if (data.containsKey(NativeEventType.deviceRealECGData)) {
      final d = data[NativeEventType.deviceRealECGData];
      if (d is Map) {
        final hr = d['heartRate'];
        if (hr is int && hr > 0) {
          emit(state.copyWith(heartRate: hr));
        }
      }
    }

    // HRV algorithm data
    if (data.containsKey(NativeEventType.deviceRealECGAlgorithmHRV)) {
      final d = data[NativeEventType.deviceRealECGAlgorithmHRV];
      if (d is Map) {
        final hrv = d['hrvNorm'];
        if (hrv is num) {
          emit(state.copyWith(hrvNorm: hrv.toDouble()));
        }
        final hr = d['heartRate'] ?? d['hearRate'];
        if (hr is int && hr > 0) {
          emit(state.copyWith(heartRate: hr));
        }
      }
    }

    // RR algorithm data (may also carry HR)
    if (data.containsKey(NativeEventType.deviceRealECGAlgorithmRR)) {
      final d = data[NativeEventType.deviceRealECGAlgorithmRR];
      if (d is Map) {
        final hr = d['heartRate'] ?? d['hearRate'];
        if (hr is int && hr > 0) {
          emit(state.copyWith(heartRate: hr));
        }
      }
    }
  }

  Future<void> _onCompleted(
    EcgCompleted event,
    Emitter<EcgState> emit,
  ) async {
    _cancelSubscriptions();

    final result = await _ecgRepository.getEcgResult();
    result.fold(
      (_) => emit(state.copyWith(status: EcgStatus.completed)),
      (ecgResult) => emit(state.copyWith(
        status: EcgStatus.completed,
        heartRate: ecgResult.heartRate,
        hrvNorm: ecgResult.hrvNorm,
        respiratoryRate: ecgResult.respiratoryRate,
        afFlag: ecgResult.afFlag,
      )),
    );
  }

  void _cancelSubscriptions() {
    _filteredSub?.cancel();
    _rawSub?.cancel();
    _endSub?.cancel();
    _timer?.cancel();
  }

  @override
  Future<void> close() {
    _cancelSubscriptions();
    return super.close();
  }
}
