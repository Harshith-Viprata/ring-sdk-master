part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

/// Load all health history data from the device.
class LoadHealthData extends DashboardEvent {}

/// Enable real-time health monitoring.
class StartRealTimeMonitoring extends DashboardEvent {}

/// Refresh a specific metric type.
class RefreshMetric extends DashboardEvent {
  final String metricType; // 'heartRate', 'steps', 'sleep', etc.
  const RefreshMetric(this.metricType);
  @override
  List<Object?> get props => [metricType];
}

/// SDK pushed a real-time health update.
class RealTimeHealthUpdate extends DashboardEvent {
  final Map<dynamic, dynamic> data;
  const RealTimeHealthUpdate(this.data);
  @override
  List<Object?> get props => [data];
}

/// Foreground service completed a background sync — reload data from Hive.
class BackgroundSyncComplete extends DashboardEvent {}
