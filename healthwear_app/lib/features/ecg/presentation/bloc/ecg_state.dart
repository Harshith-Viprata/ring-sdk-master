part of 'ecg_bloc.dart';

enum EcgStatus { idle, measuring, completed, error }

class EcgState extends Equatable {
  final EcgStatus status;
  final List<double> waveformData;
  final int? heartRate;
  final double? hrvNorm;
  final int? respiratoryRate;
  final bool? afFlag;
  final String? errorMessage;
  final int elapsedSeconds;

  const EcgState({
    this.status = EcgStatus.idle,
    this.waveformData = const [],
    this.heartRate,
    this.hrvNorm,
    this.respiratoryRate,
    this.afFlag,
    this.errorMessage,
    this.elapsedSeconds = 0,
  });

  EcgState copyWith({
    EcgStatus? status,
    List<double>? waveformData,
    int? heartRate,
    double? hrvNorm,
    int? respiratoryRate,
    bool? afFlag,
    String? errorMessage,
    int? elapsedSeconds,
  }) {
    return EcgState(
      status: status ?? this.status,
      waveformData: waveformData ?? this.waveformData,
      heartRate: heartRate ?? this.heartRate,
      hrvNorm: hrvNorm ?? this.hrvNorm,
      respiratoryRate: respiratoryRate ?? this.respiratoryRate,
      afFlag: afFlag ?? this.afFlag,
      errorMessage: errorMessage,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        waveformData,
        heartRate,
        hrvNorm,
        respiratoryRate,
        afFlag,
        errorMessage,
        elapsedSeconds
      ];
}
