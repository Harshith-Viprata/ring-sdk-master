import 'package:get_it/get_it.dart';

import '../../features/device/data/datasources/ble_data_source.dart';
import '../../features/device/data/repositories/device_repository_impl.dart';
import '../../features/device/domain/repositories/device_repository.dart';
import '../../features/device/domain/usecases/device_usecases.dart';
import '../../features/device/presentation/bloc/device_bloc.dart';
import '../../features/dashboard/data/repositories/health_repository_impl.dart';
import '../../features/dashboard/domain/repositories/health_repository.dart';
import '../../features/dashboard/domain/usecases/health_usecases.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../features/ecg/data/repositories/ecg_repository_impl.dart';
import '../../features/ecg/domain/repositories/ecg_repository.dart';
import '../../features/ecg/presentation/bloc/ecg_bloc.dart';

final sl = GetIt.instance;

/// Register all dependencies (idempotent — safe to call multiple times).
Future<void> initDependencies() async {
  print('[DI] Registering dependencies...');

  // Guard: skip if already registered (e.g. called from both main() and foreground service)
  if (sl.isRegistered<BleDataSource>()) {
    print('[DI] Dependencies already registered — skipping');
    return;
  }

  // ─── Data Sources ────────────────────────────────────────────────────
  sl.registerLazySingleton<BleDataSource>(() => BleDataSource());

  // Initialize the native BLE SDK — MUST be done before any scan/connect
  await sl<BleDataSource>().init(reconnect: true, log: false);

  // ─── Repositories ────────────────────────────────────────────────────
  sl.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(bleDataSource: sl()),
  );
  sl.registerLazySingleton<HealthRepository>(
    () => HealthRepositoryImpl(bleDataSource: sl()),
  );
  sl.registerLazySingleton<EcgRepository>(
    () => EcgRepositoryImpl(bleDataSource: sl()),
  );

  // ─── Use Cases ───────────────────────────────────────────────────────
  sl.registerLazySingleton(() => ScanDevicesUseCase(sl()));
  sl.registerLazySingleton(() => ConnectDeviceUseCase(sl()));
  sl.registerLazySingleton(() => DisconnectDeviceUseCase(sl()));
  sl.registerLazySingleton(() => SyncPhoneTimeUseCase(sl()));
  sl.registerLazySingleton(() => GetHeartRateHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetStepHistoryUseCase(sl()));
  sl.registerLazySingleton(() => GetSleepHistoryUseCase(sl()));
  sl.registerLazySingleton(() => StartMeasurementUseCase(sl()));
  sl.registerLazySingleton(() => StopMeasurementUseCase(sl()));

  // ─── BLoCs ───────────────────────────────────────────────────────────
  sl.registerFactory(() => DeviceBloc(bleDataSource: sl()));
  sl.registerFactory(
    () => DashboardBloc(healthRepository: sl()),
  );
  sl.registerFactory(
    () => EcgBloc(bleDataSource: sl(), ecgRepository: sl()),
  );

  print('[DI] All dependencies registered');
}
