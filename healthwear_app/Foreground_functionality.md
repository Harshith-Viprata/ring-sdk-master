# Foreground Service + Hive Persistence — Implementation Guide

This guide documents how to add background health data sync using a foreground service and local Hive persistence to the HealthWear app. **Apply these changes to a branch where measurement functionality is fully working.**

> [!CAUTION]
> **Critical**: The foreground service MUST NOT re-initialize BLE or call `autoConnect()` when the ring is already connected. Doing so kills active measurements. Read the "Known Pitfalls" section carefully.

---

## Table of Contents

1. [Dependencies](#1-dependencies)
2. [New Files to Create](#2-new-files-to-create)
3. [Files to Modify](#3-files-to-modify)
4. [Known Pitfalls & Solutions](#4-known-pitfalls--solutions)
5. [Testing Checklist](#5-testing-checklist)

---

## 1. Dependencies

### pubspec.yaml

Add `hive` under dependencies:

```yaml
dependencies:
  # ... existing deps ...
  hive: ^2.2.3
```

Then run `flutter pub get`.

> `path_provider` should already be present. It is required by Hive.

---

## 2. New Files to Create

### 2.1 `lib/core/services/health_hive_service.dart`

Local storage service with 7 Hive boxes (one per health data type). Uses JSON map serialization with timestamp-based deduplication.

```dart
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/dashboard/domain/entities/health_data.dart';

/// Local storage service using Hive for persisting health records.
/// Each health data type has its own box. Records are stored as JSON maps
/// and deduplicated by timestamp to avoid storing duplicate entries.
class HealthHiveService {
  static const _heartRateBox = 'heartRateRecords';
  static const _stepBox = 'stepRecords';
  static const _sleepBox = 'sleepRecords';
  static const _bloodOxygenBox = 'bloodOxygenRecords';
  static const _bloodPressureBox = 'bloodPressureRecords';
  static const _temperatureBox = 'temperatureRecords';
  static const _bloodGlucoseBox = 'bloodGlucoseRecords';

  /// Initialize Hive and open all boxes. Safe to call multiple times.
  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);

    await Future.wait([
      Hive.openBox<Map>(_heartRateBox),
      Hive.openBox<Map>(_stepBox),
      Hive.openBox<Map>(_sleepBox),
      Hive.openBox<Map>(_bloodOxygenBox),
      Hive.openBox<Map>(_bloodPressureBox),
      Hive.openBox<Map>(_temperatureBox),
      Hive.openBox<Map>(_bloodGlucoseBox),
    ]);

    print('[HiveService] All 7 health boxes opened');
  }

  // ─── Heart Rate ──────────────────────────────────────────────────────

  static Future<void> saveHeartRateRecords(
      List<HeartRateRecord> records) async {
    final box = Hive.box<Map>(_heartRateBox);
    for (final r in records) {
      final key = r.time.millisecondsSinceEpoch.toString();
      if (!box.containsKey(key)) {
        await box.put(key, {
          'bpm': r.bpm,
          'minBpm': r.minBpm,
          'maxBpm': r.maxBpm,
          'time': r.time.toIso8601String(),
        });
      }
    }
  }

  static List<HeartRateRecord> getHeartRateRecords() {
    final box = Hive.box<Map>(_heartRateBox);
    final records = box.values.map((m) {
      final map = Map<String, dynamic>.from(m);
      return HeartRateRecord(
        bpm: map['bpm'] as int,
        minBpm: map['minBpm'] as int,
        maxBpm: map['maxBpm'] as int,
        time: DateTime.parse(map['time'] as String),
      );
    }).toList();
    records.sort((a, b) => a.time.compareTo(b.time));
    return records;
  }

  // ─── Steps ───────────────────────────────────────────────────────────

  static Future<void> saveStepRecords(List<StepRecord> records) async {
    final box = Hive.box<Map>(_stepBox);
    for (final r in records) {
      final key = '${r.date.year}-${r.date.month}-${r.date.day}';
      // Always overwrite steps for the same day (accumulative)
      await box.put(key, {
        'steps': r.steps,
        'calories': r.calories,
        'distanceKm': r.distanceKm,
        'date': r.date.toIso8601String(),
      });
    }
  }

  static List<StepRecord> getStepRecords() {
    final box = Hive.box<Map>(_stepBox);
    final records = box.values.map((m) {
      final map = Map<String, dynamic>.from(m);
      return StepRecord(
        steps: map['steps'] as int,
        calories: map['calories'] as int,
        distanceKm: (map['distanceKm'] as num).toDouble(),
        date: DateTime.parse(map['date'] as String),
      );
    }).toList();
    records.sort((a, b) => a.date.compareTo(b.date));
    return records;
  }

  // ─── Sleep ───────────────────────────────────────────────────────────

  static Future<void> saveSleepRecords(List<SleepRecord> records) async {
    final box = Hive.box<Map>(_sleepBox);
    for (final r in records) {
      final key = r.startTime.millisecondsSinceEpoch.toString();
      if (!box.containsKey(key)) {
        await box.put(key, {
          'deepMinutes': r.deepMinutes,
          'lightMinutes': r.lightMinutes,
          'remMinutes': r.remMinutes,
          'awakeMinutes': r.awakeMinutes,
          'startTime': r.startTime.toIso8601String(),
          'endTime': r.endTime.toIso8601String(),
        });
      }
    }
  }

  static List<SleepRecord> getSleepRecords() {
    final box = Hive.box<Map>(_sleepBox);
    final records = box.values.map((m) {
      final map = Map<String, dynamic>.from(m);
      return SleepRecord(
        deepMinutes: map['deepMinutes'] as int,
        lightMinutes: map['lightMinutes'] as int,
        remMinutes: map['remMinutes'] as int,
        awakeMinutes: map['awakeMinutes'] as int,
        startTime: DateTime.parse(map['startTime'] as String),
        endTime: DateTime.parse(map['endTime'] as String),
      );
    }).toList();
    records.sort((a, b) => a.startTime.compareTo(b.startTime));
    return records;
  }

  // ─── Blood Oxygen ────────────────────────────────────────────────────

  static Future<void> saveBloodOxygenRecords(
      List<BloodOxygenRecord> records) async {
    final box = Hive.box<Map>(_bloodOxygenBox);
    for (final r in records) {
      final key = r.time.millisecondsSinceEpoch.toString();
      if (!box.containsKey(key)) {
        await box.put(key, {
          'spo2': r.spo2,
          'time': r.time.toIso8601String(),
        });
      }
    }
  }

  static List<BloodOxygenRecord> getBloodOxygenRecords() {
    final box = Hive.box<Map>(_bloodOxygenBox);
    final records = box.values.map((m) {
      final map = Map<String, dynamic>.from(m);
      return BloodOxygenRecord(
        spo2: map['spo2'] as int,
        time: DateTime.parse(map['time'] as String),
      );
    }).toList();
    records.sort((a, b) => a.time.compareTo(b.time));
    return records;
  }

  // ─── Blood Pressure ──────────────────────────────────────────────────

  static Future<void> saveBloodPressureRecords(
      List<BloodPressureRecord> records) async {
    final box = Hive.box<Map>(_bloodPressureBox);
    for (final r in records) {
      final key = r.time.millisecondsSinceEpoch.toString();
      if (!box.containsKey(key)) {
        await box.put(key, {
          'systolic': r.systolic,
          'diastolic': r.diastolic,
          'time': r.time.toIso8601String(),
        });
      }
    }
  }

  static List<BloodPressureRecord> getBloodPressureRecords() {
    final box = Hive.box<Map>(_bloodPressureBox);
    final records = box.values.map((m) {
      final map = Map<String, dynamic>.from(m);
      return BloodPressureRecord(
        systolic: map['systolic'] as int,
        diastolic: map['diastolic'] as int,
        time: DateTime.parse(map['time'] as String),
      );
    }).toList();
    records.sort((a, b) => a.time.compareTo(b.time));
    return records;
  }

  // ─── Temperature ─────────────────────────────────────────────────────

  static Future<void> saveTemperatureRecords(
      List<TemperatureRecord> records) async {
    final box = Hive.box<Map>(_temperatureBox);
    for (final r in records) {
      final key = r.time.millisecondsSinceEpoch.toString();
      if (!box.containsKey(key)) {
        await box.put(key, {
          'celsius': r.celsius,
          'time': r.time.toIso8601String(),
        });
      }
    }
  }

  static List<TemperatureRecord> getTemperatureRecords() {
    final box = Hive.box<Map>(_temperatureBox);
    final records = box.values.map((m) {
      final map = Map<String, dynamic>.from(m);
      return TemperatureRecord(
        celsius: (map['celsius'] as num).toDouble(),
        time: DateTime.parse(map['time'] as String),
      );
    }).toList();
    records.sort((a, b) => a.time.compareTo(b.time));
    return records;
  }

  // ─── Blood Glucose ───────────────────────────────────────────────────

  static Future<void> saveBloodGlucoseRecords(
      List<BloodGlucoseRecord> records) async {
    final box = Hive.box<Map>(_bloodGlucoseBox);
    for (final r in records) {
      final key = r.time.millisecondsSinceEpoch.toString();
      if (!box.containsKey(key)) {
        await box.put(key, {
          'glucoseMmol': r.glucoseMmol,
          'time': r.time.toIso8601String(),
        });
      }
    }
  }

  static List<BloodGlucoseRecord> getBloodGlucoseRecords() {
    final box = Hive.box<Map>(_bloodGlucoseBox);
    final records = box.values.map((m) {
      final map = Map<String, dynamic>.from(m);
      return BloodGlucoseRecord(
        glucoseMmol: (map['glucoseMmol'] as num).toDouble(),
        time: DateTime.parse(map['time'] as String),
      );
    }).toList();
    records.sort((a, b) => a.time.compareTo(b.time));
    return records;
  }

  // ─── Real-time measurement save helpers ─────────────────────────────

  static Future<void> saveRealtimeHeartRate(int bpm) async {
    if (bpm <= 0) return;
    final now = DateTime.now();
    await saveHeartRateRecords([
      HeartRateRecord(bpm: bpm, minBpm: bpm, maxBpm: bpm, time: now),
    ]);
  }

  static Future<void> saveRealtimeSpO2(int spo2) async {
    if (spo2 <= 0) return;
    await saveBloodOxygenRecords([
      BloodOxygenRecord(spo2: spo2, time: DateTime.now()),
    ]);
  }

  static Future<void> saveRealtimeBP(int systolic, int diastolic) async {
    if (systolic <= 0 || diastolic <= 0) return;
    await saveBloodPressureRecords([
      BloodPressureRecord(
        systolic: systolic,
        diastolic: diastolic,
        time: DateTime.now(),
      ),
    ]);
  }

  static Future<void> saveRealtimeTemperature(double celsius) async {
    if (celsius <= 0) return;
    await saveTemperatureRecords([
      TemperatureRecord(celsius: celsius, time: DateTime.now()),
    ]);
  }

  static Future<void> saveRealtimeGlucose(double glucoseMmol) async {
    if (glucoseMmol <= 0) return;
    await saveBloodGlucoseRecords([
      BloodGlucoseRecord(glucoseMmol: glucoseMmol, time: DateTime.now()),
    ]);
  }

  /// Clear all health data boxes.
  static Future<void> clearAll() async {
    await Hive.box<Map>(_heartRateBox).clear();
    await Hive.box<Map>(_stepBox).clear();
    await Hive.box<Map>(_sleepBox).clear();
    await Hive.box<Map>(_bloodOxygenBox).clear();
    await Hive.box<Map>(_bloodPressureBox).clear();
    await Hive.box<Map>(_temperatureBox).clear();
    await Hive.box<Map>(_bloodGlucoseBox).clear();
    print('[HiveService] All health data cleared');
  }
}
```

---

### 2.2 `lib/core/services/health_background_service.dart`

Foreground service that queries ring data every N minutes and stores to Hive.

```dart
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

    // On Android v9 runs in the SAME isolate — reuse existing deps.
    // Only init if truly missing (app killed while service persisted).
    if (!sl.isRegistered<HealthRepository>()) {
      print('[BGService] Dependencies missing — initializing...');
      await initDependencies();
      print('[BGService] Dependencies initialized OK');
    } else {
      print('[BGService] Dependencies already available — reusing');
    }

    // Initialize Hive (safe to call multiple times)
    await HealthHiveService.init();

    print('[BGService] Foreground service started at $timestamp');
  }

  /// Called every N minutes (interval set in HealthBackgroundService.init).
  @override
  void onRepeatEvent(DateTime timestamp) async {
    print('[BGService] onRepeatEvent triggered at $timestamp');

    try {
      if (!sl.isRegistered<HealthRepository>()) {
        print('[BGService] Dependencies not found — initializing...');
        await initDependencies();
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
    print('[BGService] onDestroy — stopped (isTimeout: $isTimeout)');
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
          15 * 60 * 1000, // 15 minutes (use 2 * 60 * 1000 for 2-min testing)
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
      print('[BGService] Stopping stale service before restarting...');
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
```

---

## 3. Files to Modify

### 3.1 `main.dart`

Add Hive init and foreground service init calls:

```diff
+import 'core/services/health_background_service.dart';
+import 'core/services/health_hive_service.dart';

 void main() async {
   WidgetsFlutterBinding.ensureInitialized();
   // ... existing setup ...

   await initDependencies();

+  // Initialize local storage (Hive boxes for health history)
+  await HealthHiveService.init();
+
+  // Initialize the foreground service configuration
+  HealthBackgroundService.init();

   runApp(const HealthWearApp());
 }
```

---

### 3.2 `ble_data_source.dart`

> [!IMPORTANT]
> Route ALL BLE events to `BleEventHandler` directly from the data source. Do NOT rely on DeviceBloc's eventStream subscription — it may be dead due to BlocProvider lifecycle.

```diff
+import '../../../../core/ble/ble_event_handler.dart';

  void _startListening() {
    if (_listening) return;
    _listening = true;
    _mgr.onEvent((event) {
      if (event is Map) {
        final mapped = Map<dynamic, dynamic>.from(event);
        print('[BleDataSource] eventStream emit: ${mapped.keys}');
        _eventController.add(mapped);

+       // Route ALL events to BleEventHandler for measurement & real-time UI
+       BleEventHandler.instance.handleEvent(mapped);
      }
    });
  }
```

Also make `init()` **idempotent** to prevent the background service from re-init disrupting BLE:

```diff
+ bool _initialized = false;

  Future<void> init({bool reconnect = true, bool log = false}) async {
+   if (_initialized) {
+     print('[BleDataSource] Already initialized — skipping');
+     return;
+   }
    await _mgr.init();
    _startListening();
    await _mgr.autoConnect();
+   _initialized = true;
  }
```

---

### 3.3 `dashboard_event.dart`

Add a new event for background sync notification:

```diff
+/// Foreground service completed a background sync — reload data from Hive.
+class BackgroundSyncComplete extends DashboardEvent {}
```

---

### 3.4 `dashboard_bloc.dart`

Three changes:

**A) Import HealthHiveService and register new event handler:**

```diff
+import '../../../../core/services/health_hive_service.dart';

 // In constructor:
+   on<BackgroundSyncComplete>(_onBackgroundSyncComplete);
```

**B) Load from Hive first in `_onLoadHealthData` (Phase 0):**

At the top of `_onLoadHealthData`, before any ring queries:

```dart
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
```

After the ring data is loaded and emitted to state, save it back to Hive:

```dart
// Save fresh ring data to Hive for offline access
hrResult.fold((_) {}, (d) => HealthHiveService.saveHeartRateRecords(d as List<HeartRateRecord>));
HealthHiveService.saveStepRecords(finalSteps);
sleepResult.fold((_) {}, (d) => HealthHiveService.saveSleepRecords(d as List<SleepRecord>));
HealthHiveService.saveBloodOxygenRecords(finalSpo2);
bpResult.fold((_) {}, (d) => HealthHiveService.saveBloodPressureRecords(d as List<BloodPressureRecord>));
HealthHiveService.saveTemperatureRecords(finalTemps);
HealthHiveService.saveBloodGlucoseRecords(finalGlucose);
print('[DashboardBloc] Ring data saved to Hive');
```

**C) Save real-time readings to Hive in `_onRealTimeUpdate`:**

At the end of the method, after the `emit(state.copyWith(...))`:

```dart
// Save real-time readings to Hive for history
if (d['heartRate'] is num && (d['heartRate'] as num).toInt() > 0) {
  HealthHiveService.saveRealtimeHeartRate((d['heartRate'] as num).toInt());
}
if (d['spo2'] is num && (d['spo2'] as num).toInt() > 0) {
  HealthHiveService.saveRealtimeSpO2((d['spo2'] as num).toInt());
}
if (d['systolic'] is num && (d['systolic'] as num).toInt() > 0 &&
    d['diastolic'] is num && (d['diastolic'] as num).toInt() > 0) {
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
```

**D) Add the `_onBackgroundSyncComplete` handler:**

```dart
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
```

---

### 3.5 `dashboard_page.dart`

Convert to `StatefulWidget` and listen for sync_complete from foreground service:

```diff
+import 'package:flutter_foreground_task/flutter_foreground_task.dart';

-class DashboardPage extends StatelessWidget {
+class DashboardPage extends StatefulWidget {
   const DashboardPage({super.key});

+  @override
+  State<DashboardPage> createState() => _DashboardPageState();
+}
+
+class _DashboardPageState extends State<DashboardPage> {
+  @override
+  void initState() {
+    super.initState();
+    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
+  }
+
+  void _onReceiveTaskData(Object data) {
+    if (data is Map && data['type'] == 'sync_complete') {
+      print('[DashboardPage] Received sync_complete from BG service');
+      if (mounted) {
+        context.read<DashboardBloc>().add(BackgroundSyncComplete());
+      }
+    }
+  }
+
+  @override
+  void dispose() {
+    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
+    super.dispose();
+  }

   @override
   Widget build(BuildContext context) {
     // ... existing BlocListener + BlocBuilder unchanged ...
```

In the `BlocListener` for device connection, start the foreground service:

```dart
listener: (context, deviceState) {
  final dashBloc = context.read<DashboardBloc>();
  dashBloc.add(LoadHealthData());
  dashBloc.add(StartRealTimeMonitoring());

  // Start the foreground service for background monitoring
  HealthBackgroundService.start();
},
```

---

## 4. Known Pitfalls & Solutions

### ⚠️ Pitfall 1: `autoConnect()` kills active measurements

**Problem**: When `initDependencies()` is called by the background service, it calls `BleDataSource.init()` → `autoConnect()` → forces GATT disconnect/reconnect. This cancels any active HR/SpO2/BP measurement (ring light stops blinking).

**Solution**: Make `BleDataSource.init()` idempotent with an `_initialized` flag (see Section 3.2).

### ⚠️ Pitfall 2: DeviceBloc eventStream subscription is dead

**Problem**: `DeviceBloc` subscribes to `BleDataSource.eventStream` in its constructor, but by the time measurement events fire, the subscription callback never executes. The `BleEventHandler.handleEvent()` was only called from inside `_onSdkEvent`, which never fires.

**Solution**: Call `BleEventHandler.instance.handleEvent(mapped)` directly in `BleDataSource._startListening()` (see Section 3.2). Do NOT rely on DeviceBloc routing.

### ⚠️ Pitfall 3: `receivePort` is internal API in v9

**Problem**: `FlutterForegroundTask.receivePort` is marked as internal in v9 and shows a lint warning.

**Solution**: Use `FlutterForegroundTask.addTaskDataCallback()` / `removeTaskDataCallback()` instead.

### ⚠️ Pitfall 4: Type cast errors in `fold()` callbacks

**Problem**: When saving ring data to Hive after loading, the `fold()` callbacks return `List<Equatable>` instead of specific types.

**Solution**: Explicitly cast: `(d as List<HeartRateRecord>)`.

---

## 5. Testing Checklist

- [ ] `flutter clean` + `flutter pub get` + `flutter run`
- [ ] Connect ring → verify `[DashboardBloc] Phase 0: Loaded cached data from Hive`
- [ ] Start HR measurement → ring light blinks continuously → HR value shows on screen
- [ ] Wait for background sync → verify `[BGService] Data stored in Hive`
- [ ] Disconnect ring → restart app → verify history persists from Hive
- [ ] Start HR measurement during BG sync → measurement should NOT be interrupted
- [ ] Check `[DashboardPage] Received sync_complete from BG service` in logs

> **Testing tip**: Change the interval to `2 * 60 * 1000` (2 minutes) for faster testing.
