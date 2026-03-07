import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'config/routes/app_router.dart';
import 'core/di/injection_container.dart';
import 'core/services/health_background_service.dart';
import 'core/services/health_hive_service.dart';
import 'features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'features/device/presentation/bloc/device_bloc.dart';
import 'features/ecg/presentation/bloc/ecg_bloc.dart';
import 'shared/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await initDependencies();

  // Initialize local storage (Hive boxes for health history persistence)
  await HealthHiveService.init();

  // Initialize the foreground service configuration (15-min interval)
  HealthBackgroundService.init();

  runApp(const HealthWearApp());
}

class HealthWearApp extends StatelessWidget {
  const HealthWearApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DeviceBloc>(create: (_) => sl<DeviceBloc>()),
        BlocProvider<DashboardBloc>(create: (_) => sl<DashboardBloc>()),
        BlocProvider<EcgBloc>(create: (_) => sl<EcgBloc>()),
      ],
      child: MaterialApp.router(
        title: 'HealthWear',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        routerConfig: appRouter,
        builder: EasyLoading.init(
          builder: (context, child) => child!,
        ),
      ),
    );
  }
}
