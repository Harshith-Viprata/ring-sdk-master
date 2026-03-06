part of 'ecg_bloc.dart';

abstract class EcgEvent extends Equatable {
  const EcgEvent();
  @override
  List<Object?> get props => [];
}

/// Start ECG measurement.
class StartEcgMeasurement extends EcgEvent {}

/// Stop ECG measurement.
class StopEcgMeasurement extends EcgEvent {}

/// New ECG waveform point received.
class EcgDataReceived extends EcgEvent {
  final Map<dynamic, dynamic> rawData;
  const EcgDataReceived(this.rawData);
  @override
  List<Object?> get props => [rawData];
}

/// ECG measurement completed — result available.
class EcgCompleted extends EcgEvent {}
