import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../../features/dashboard/domain/entities/health_data.dart';
import '../../features/dashboard/domain/repositories/health_repository.dart';
import '../di/injection_container.dart';
import 'health_hive_service.dart';

// ─── Top-level callback (required by flutter_foreground_task) ────────────────
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(HealthDataTaskHandler());
}

// ─── Task handler — runs in the foreground service ──────────────────────────
class HealthDataTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('[BGService] onStart — starter: $starter');

    // On Android, flutter_foreground_task v9 runs in the SAME isolate.
    // Dependencies are already registered by main(). Only re-init if
    // truly missing (e.g. after app was killed while service persisted).
    if (!sl.isRegistered<HealthRepository>()) {
      print('[BGService] Dependencies missing — initializing...');
      await initDependencies();
      print('[BGService] Dependencies initialized OK');
    } else {
      print('[BGService] Dependencies already available — reusing');
    }

    // Initialize Hive in this context (safe to call multiple times)
    await HealthHiveService.init();

    print('[BGService] Foreground service started at $timestamp');
  }

  /// Called every 15 minutes (interval set in HealthBackgroundService.init).
  @override
  void onRepeatEvent(DateTime timestamp) async {
    print('[BGService] onRepeatEvent triggered at $timestamp');

    try {
      // Safety: ensure dependencies are initialized in this isolate
      if (!sl.isRegistered<HealthRepository>()) {
        print('[BGService] Dependencies not found — initializing...');
        await initDependencies();
        print('[BGService] Dependencies initialized in onRepeatEvent');
      }

      // Access the singleton HealthRepository from GetIt
      final healthRepo = sl<HealthRepository>();

      // ── Phase 1: Query non-combinedData histories ──
      final results = await Future.wait([
        healthRepo.getHeartRateHistory(),
        healthRepo.getStepHistory(),
        healthRepo.getSleepHistory(),
        healthRepo.getBloodPressureHistory(),
      ]);

      // ── Phase 2: Query combinedData (temp, glucose, spo2, steps) ──
      await Future.delayed(const Duration(milliseconds: 500));
      final combinedResult = await healthRepo.getCombinedDataAll();

      // ── Store all synced data into Hive ──
      int hrCount = 0, stepCount = 0, sleepCount = 0, bpCount = 0;
      int tempCount = 0, glucoseCount = 0, spo2Count = 0;

      results[0].fold((_) {}, (d) {
        final list = d as List<HeartRateRecord>;
        hrCount = list.length;
        HealthHiveService.saveHeartRateRecords(list);
      });
      results[1].fold((_) {}, (d) {
        final list = d as List<StepRecord>;
        stepCount = list.length;
        HealthHiveService.saveStepRecords(list);
      });
      results[2].fold((_) {}, (d) {
        final list = d as List<SleepRecord>;
        sleepCount = list.length;
        HealthHiveService.saveSleepRecords(list);
      });
      results[3].fold((_) {}, (d) {
        final list = d as List<BloodPressureRecord>;
        bpCount = list.length;
        HealthHiveService.saveBloodPressureRecords(list);
      });

      // Store combinedData results
      combinedResult.fold((_) {}, (data) {
        HealthHiveService.saveStepRecords(data.steps);
        HealthHiveService.saveTemperatureRecords(data.temps);
        HealthHiveService.saveBloodGlucoseRecords(data.glucose);
        HealthHiveService.saveBloodOxygenRecords(data.spo2);
        tempCount = data.temps.length;
        glucoseCount = data.glucose.length;
        spo2Count = data.spo2.length;
      });

      print('[BGService] Sync complete — HR:$hrCount Steps:$stepCount '
          'Sleep:$sleepCount BP:$bpCount Temp:$tempCount Glu:$glucoseCount '
          'SpO2:$spo2Count');
      print('[BGService] Data stored in Hive');

      // Update the notification with latest info
      FlutterForegroundTask.updateService(
        notificationTitle: 'HealthWear Active',
        notificationText:
            'Last sync: ${timestamp.hour.toString().padLeft(2, '0')}'
            ':${timestamp.minute.toString().padLeft(2, '0')} '
            '• HR:$hrCount Steps:$stepCount',
      );

      // Send data to the UI so the BLoC can update
      FlutterForegroundTask.sendDataToMain({
        'type': 'sync_complete',
        'timestamp': timestamp.toIso8601String(),
      });
    } catch (e) {
      print('[BGService] Sync error: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print(
        '[BGService] onDestroy — foreground service stopped (isTimeout: $isTimeout)');
  }

  @override
  void onReceiveData(Object data) {
    print('[BGService] Received data from main: $data');
  }

  @override
  void onNotificationPressed() {
    print('[BGService] Notification pressed — bringing app to foreground');
  }
}

// ─── Helper class with static methods for managing the service ──────────────
class HealthBackgroundService {
  /// Initialize the foreground task configuration.
  /// Call this once in main() after initDependencies().
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'health_monitoring',
        channelName: 'Health Monitoring',
        channelDescription: 'Monitoring health data from your smart ring',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          // TODO: Change to 15 * 60 * 1000 (15 min) after testing
          2 * 60 * 1000, // 2 minutes for testing
        ),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    print('[BGService] Initialized with 2-minute interval (testing)');
  }

  /// Start the foreground service.
  /// Call this when the BLE device connects.
  static Future<void> start() async {
    // Request notification permission on Android 13+
    final notifPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notifPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    // If service is already running (stale from previous session), restart it
    if (await FlutterForegroundTask.isRunningService) {
      print('[BGService] Stopping stale service before restarting...');
      await FlutterForegroundTask.stopService();
      // Brief delay to let the old service fully stop
      await Future.delayed(const Duration(milliseconds: 500));
    }

    final result = await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'HealthWear Active',
      notificationText: 'Monitoring health data from your ring...',
      callback: startCallback,
    );

    print('[BGService] startService result: $result');
  }

  /// Stop the foreground service.
  /// Call this when the BLE device disconnects.
  static Future<void> stop() async {
    final result = await FlutterForegroundTask.stopService();
    print('[BGService] stopService result: $result');
  }

  /// Check if the service is currently running.
  static Future<bool> get isRunning => FlutterForegroundTask.isRunningService;
}
