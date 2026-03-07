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
  /// Wait for dependencies registered by main() — they run in the same isolate.
  Future<bool> _waitForDeps({int maxWaitSec = 10}) async {
    for (int i = 0; i < maxWaitSec * 10; i++) {
      if (sl.isRegistered<HealthRepository>()) return true;
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return false;
  }

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('[BGService] onStart — starter: $starter');

    // Wait for main() to register dependencies (same isolate).
    if (!sl.isRegistered<HealthRepository>()) {
      print('[BGService] Waiting for main() to register dependencies...');
      final ok = await _waitForDeps();
      if (!ok) {
        print('[BGService] Dependencies not available after 10s — skipping');
        return;
      }
    }
    print('[BGService] Dependencies OK');

    // Initialize Hive (idempotent — safe to call multiple times)
    await HealthHiveService.init();

    print('[BGService] Foreground service started at $timestamp');
  }

  /// Called every N minutes (interval set in HealthBackgroundService.init).
  @override
  void onRepeatEvent(DateTime timestamp) async {
    print('[BGService] onRepeatEvent triggered at $timestamp');

    try {
      if (!sl.isRegistered<HealthRepository>()) {
        print('[BGService] Dependencies not available — skipping sync');
        return;
      }

      final healthRepo = sl<HealthRepository>();

      // ── Phase 1: Query non-combinedData histories ──
      final results = await Future.wait([
        healthRepo.getHeartRateHistory(),
        healthRepo.getStepHistory(),
        healthRepo.getSleepHistory(),
        healthRepo.getBloodPressureHistory(),
      ]);

      // ── Phase 2: Query combinedData (temp, glucose, spo2, steps) ──
      // Small delay for SDK stability between BLE command batches
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

      FlutterForegroundTask.updateService(
        notificationTitle: 'HealthWear Active',
        notificationText:
            'Last sync: ${timestamp.hour.toString().padLeft(2, '0')}'
            ':${timestamp.minute.toString().padLeft(2, '0')} '
            '• HR:$hrCount Steps:$stepCount',
      );

      // Notify the UI to reload from Hive
      print('[BGService] Sending sync_complete to main isolate...');
      FlutterForegroundTask.sendDataToMain({
        'type': 'sync_complete',
        'timestamp': timestamp.toIso8601String(),
      });
      print('[BGService] sync_complete sent');
    } catch (e) {
      print('[BGService] Sync error: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    print('[BGService] onDestroy — stopped');
  }

  @override
  void onReceiveData(Object data) {
    print('[BGService] Received data from main: $data');
  }

  @override
  void onNotificationPressed() {
    print('[BGService] Notification pressed');
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
          15 * 60 * 1000, // 15 minutes in ms
        ),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
    print('[BGService] Initialized with 15-minute interval');
  }

  /// Start the foreground service. Call when BLE device connects.
  static Future<void> start() async {
    final notifPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notifPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (await FlutterForegroundTask.isRunningService) {
      print('[BGService] Service already running — restarting...');
      await FlutterForegroundTask.stopService();
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

  /// Stop the foreground service. Call when BLE device disconnects.
  static Future<void> stop() async {
    final result = await FlutterForegroundTask.stopService();
    print('[BGService] stopService result: $result');
  }

  static Future<bool> get isRunning => FlutterForegroundTask.isRunningService;
}
