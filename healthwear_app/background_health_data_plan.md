# Background Health Data Collection — Detailed Plan

> **Current status:** ❌ **Foreground-only** — data collection stops when the app is closed  
> **Goal:** Keep collecting health data every 5 minutes even when the app is in the background or killed

---

## Current Setup Analysis

### What Happens Now

```
App Open (Foreground):
  ✅ DashboardBloc._refreshTimer = Timer.periodic(60s)
  ✅ _healthSub = streamRealTimeHealth() (continuous BLE stream)
  ✅ Ring sends real-time events → BleDataSource.eventStream → BLoC → UI

App Minimized (Background):
  ⚠️ Timer keeps running briefly (Android may kill after 1-5 minutes)
  ⚠️ BLE stream may continue (depends on OS battery optimization)
  ⚠️ No persistent notification → OS can kill anytime

App Killed (Swiped away):
  ❌ Timer destroyed
  ❌ BLE stream destroyed
  ❌ BLE connection may persist at OS level but no Dart code runs
  ❌ ALL data collection stops
```

### Current Permissions Already Declared (AndroidManifest.xml)

```xml
✅ FOREGROUND_SERVICE                       ← already declared
✅ FOREGROUND_SERVICE_CONNECTED_DEVICE      ← already declared
✅ WAKE_LOCK                                ← already declared
✅ RECEIVE_BOOT_COMPLETED                   ← already declared
✅ REQUEST_IGNORE_BATTERY_OPTIMIZATIONS     ← already declared
```

> **Good news:** The permissions are already in place. We just need to implement the service.

### What's Missing

```
❌ No <service> declaration in AndroidManifest.xml
❌ No Foreground Service implementation
❌ No background Dart entry point / isolate
❌ No data persistence (Hive boxes not initialized for health data)
❌ No WorkManager / background task scheduler
```

---

## Four Approaches — Compared

| Approach                                       | Complexity    | Reliability     | BLE Support            | Best For                   |
| ---------------------------------------------- | ------------- | --------------- | ---------------------- | -------------------------- |
| **1. Flutter Foreground Service**              | ⭐⭐ Medium   | ⭐⭐⭐⭐⭐ Best | ✅ Full                | **Our app (RECOMMENDED)**  |
| **2. Native Android Foreground Service**       | ⭐⭐⭐⭐ High | ⭐⭐⭐⭐⭐ Best | ✅ Full                | Complex native integration |
| **3. WorkManager (Periodic Tasks)**            | ⭐ Low        | ⭐⭐ Poor       | ❌ Cannot maintain BLE | Simple background sync     |
| **4. Background Isolate + flutter_background** | ⭐⭐ Medium   | ⭐⭐⭐ Okay     | ⚠️ Partial             | Lightweight tasks          |

---

## Approach 1: Flutter Foreground Service ⭐ RECOMMENDED

> **Best approach** for our current app setup. Uses `flutter_foreground_task` package to run Dart code in a foreground service with a persistent notification.

### Why This is Best for HealthWare

1. **Full BLE access** — the Dart isolate runs alongside the main app, so `BleManager` and all SDK calls work
2. **OS won't kill it** — foreground services with a persistent notification are protected from battery optimization
3. **Low complexity** — it's a Flutter package, no native Android code needed
4. **Already have permissions** — `FOREGROUND_SERVICE` and `FOREGROUND_SERVICE_CONNECTED_DEVICE` are already declared
5. **Data persistence built-in** — can write to Hive boxes from the service

### How It Works

```
App Start
    │
    ├── Normal: Flutter UI renders, BLoCs initialize
    │
    └── FlutterForegroundTask.startService()
            │
            ├── Creates persistent notification: "HealthWear — Monitoring health data"
            │
            └── Runs HealthDataTaskHandler (Dart class)
                    │
                    ├── Timer.periodic(5 minutes)
                    │      │
                    │      └── queryHealthHistory() for all types
                    │          └── Save to Hive boxes
                    │
                    └── StreamSubscription on BLE eventStream
                           │
                           └── On each real-time event → save to Hive
```

### Architecture Diagram

```
┌─────────────────────────────────────┐
│         Flutter UI (Main Isolate)    │
│                                      │
│  DashboardBloc ← reads from Hive    │
│  MetricCards update on BlocBuilder   │
│                                      │
│  [ Can be in foreground/background ] │
└────────────┬────────────────────────┘
             │ reads from
             ▼
┌─────────────────────────────────────┐
│       Hive Boxes (Local Storage)     │
│                                      │
│  heartRateBox, stepBox, sleepBox,    │
│  temperatureBox, glucoseBox, etc.    │
└────────────┬────────────────────────┘
             │ writes to
             ▼
┌─────────────────────────────────────┐
│   Foreground Service (Always Alive)  │
│                                      │
│  HealthDataTaskHandler:              │
│    • BLE connection kept alive       │
│    • Timer.periodic(5 min)           │
│    • Queries history → saves to Hive │
│    • Streams real-time → saves       │
│    • Shows persistent notification   │
│                                      │
│  [ Survives app kill, background ]   │
└─────────────────────────────────────┘
             │
             ▼
       YC Smart Ring (BLE)
```

### Implementation Steps

#### Step 1: Add Package

```yaml
# pubspec.yaml
dependencies:
  flutter_foreground_task: ^8.x.x
```

#### Step 2: Update AndroidManifest.xml

```xml
<!-- Inside <application> tag -->
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:foregroundServiceType="connectedDevice"
    android:exported="false" />
```

#### Step 3: Create Background Task Handler

```dart
// lib/core/services/health_background_service.dart

class HealthDataTaskHandler extends TaskHandler {
  Timer? _syncTimer;
  StreamSubscription? _bleSub;

  @override
  Future<void> onStart(DateTime timestamp) async {
    // Initialize BLE + Hive in the service context
    await Hive.initFlutter();
    // Open health data boxes
    // Connect to ring (auto-reconnect)

    // Start 5-minute periodic sync
    _syncTimer = Timer.periodic(Duration(minutes: 5), (_) {
      _syncHealthData();
    });

    // Listen to real-time BLE events
    _bleSub = bleDataSource.eventStream.listen((event) {
      _saveRealTimeEvent(event);
    });
  }

  Future<void> _syncHealthData() async {
    // Query all health histories from ring
    // Save to Hive boxes
    // Send notification update with latest values
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    _syncTimer?.cancel();
    _bleSub?.cancel();
  }
}
```

#### Step 4: Start Service from App

```dart
// In main.dart or after device connects
FlutterForegroundTask.init(
  androidNotificationOptions: AndroidNotificationOptions(
    channelId: 'health_monitoring',
    channelName: 'Health Monitoring',
    channelDescription: 'Monitoring health data from your ring',
    channelImportance: NotificationChannelImportance.LOW,
    priority: NotificationPriority.LOW,
    iconData: NotificationIconData(
      resType: ResourceType.mipmap,
      resPrefix: ResourcePrefix.ic,
      name: 'launcher',
    ),
  ),
  foregroundTaskOptions: ForegroundTaskOptions(
    interval: 300000,  // 5 minutes in ms
    isOnceEvent: false,
    autoRunOnBoot: true,
    allowWakeLock: true,
    allowWifiLock: false,
  ),
);

FlutterForegroundTask.startService(
  notificationTitle: 'HealthWear Active',
  notificationText: 'Monitoring health data...',
  callback: startCallback,
);
```

#### Step 5: Update DashboardBloc to Read from Hive

Instead of only reading from BLE queries, the `DashboardBloc` reads from Hive boxes on load:

```dart
// On LoadHealthData:
//   1. Read from Hive (instant display)
//   2. Query from BLE (fresh data)
//   3. Merge and save back to Hive
```

### Estimated Development Time: 2-3 days

---

## Approach 2: Native Android Foreground Service

> Write a native Android Service in Java/Kotlin that directly uses the YC SDK's native layer.

### How It Works

```
Native Android Service
    │
    ├── Starts on boot / app launch
    ├── Maintains BLE GATT connection natively
    ├── Reads health data via YCBTClient directly
    ├── Stores in SQLite / Room database
    │
    └── Flutter reads from native DB via MethodChannel
```

### Pros

- Maximum reliability — native services are more stable than Dart isolate wrappers
- Direct access to `YCBTClient` Java API without going through platform channels
- Best battery efficiency since native code runs more efficiently

### Cons

- **High complexity** — requires writing 200-400 lines of Java/Kotlin
- Duplicate logic (native + Dart)
- Harder to debug and maintain
- Need to create MethodChannel bridge for Flutter to read data

### Estimated Development Time: 4-6 days

---

## Approach 3: WorkManager (Periodic Background Tasks)

> Use `workmanager` Flutter package to schedule periodic tasks.

### How It Works

```
WorkManager schedules callbackDispatcher every 15 minutes (minimum)
    │
    └── Each execution:
        1. Connect to ring via BLE
        2. Query health history
        3. Save to Hive
        4. Disconnect
```

### Why It DOESN'T Work Well for Our Case

| Limitation                           | Impact                                          |
| ------------------------------------ | ----------------------------------------------- |
| **Minimum interval: 15 minutes**     | Cannot do 5-minute intervals                    |
| **No persistent BLE connection**     | Must reconnect every execution (~10-15s wasted) |
| **Execution limited to ~10 minutes** | Tight window for BLE operations                 |
| **No real-time streaming**           | Cannot receive live HR/SpO2/etc events          |
| **OS can defer/batch**               | Actual execution time unpredictable             |
| **No notification**                  | User doesn't know if monitoring is active       |

### When To Use

- Only suitable for infrequent data sync (e.g., sync to cloud every 30 min)
- NOT suitable for continuous health monitoring

### Estimated Development Time: 1 day (but limited functionality)

---

## Approach 4: flutter_background + Isolate

> Use `flutter_background` package to keep the Dart engine alive.

### How It Works

```
flutter_background.enableBackgroundExecution()
    │
    └── Keeps Dart VM running with a minimal notification
        └── Existing Timer.periodic + BLE stream continue working
```

### Pros

- **Simplest implementation** — just wrap existing code
- Minimal code changes (3-5 lines)
- Works with current `DashboardBloc` timer and stream

### Cons

- **Less reliable** than a proper foreground service
- Some Android OEMs (Xiaomi, Huawei, Oppo) aggressively kill background apps regardless
- No auto-restart on app kill
- No boot start support
- BLE connection stability in background varies by device

### Estimated Development Time: 0.5 day

---

## Recommendation: Approach 1 (Flutter Foreground Service)

### Why Approach 1 is Best for HealthWare

| Criteria                    | Approach 1 | Approach 2     | Approach 3        | Approach 4 |
| --------------------------- | ---------- | -------------- | ----------------- | ---------- |
| **5-min data sync**         | ✅ Yes     | ✅ Yes         | ❌ 15-min minimum | ✅ Yes     |
| **Real-time BLE stream**    | ✅ Yes     | ✅ Yes         | ❌ No             | ✅ Yes     |
| **Survives app kill**       | ✅ Yes     | ✅ Yes         | ✅ Yes            | ❌ No      |
| **Auto-start on boot**      | ✅ Yes     | ✅ Yes         | ✅ Yes            | ❌ No      |
| **Persistent notification** | ✅ Yes     | ✅ Yes         | ❌ No             | ⚠️ Minimal |
| **Easy to implement**       | ✅ Medium  | ❌ Hard        | ✅ Easy           | ✅ Easy    |
| **Works with YC SDK**       | ✅ Yes     | ✅ Yes         | ⚠️ Partial        | ⚠️ Partial |
| **OEM battery safe**        | ✅ Best    | ✅ Best        | ⚠️ Deferred       | ❌ Killed  |
| **Data persistence**        | ✅ Hive    | ✅ Room/SQLite | ✅ Hive           | ❌ None    |
| **Development time**        | 2-3 days   | 4-6 days       | 1 day             | 0.5 day    |

### What the User Sees (Approach 1)

```
┌─────────────────────────────────────────┐
│  📱 Notification Bar                     │
│                                          │
│  🔵 HealthWear Active                   │
│     Monitoring: HR 72 • SpO2 98% • 36.5°C│
│     Last sync: 2 min ago                 │
│                                          │
│  (persistent while monitoring is active)  │
└─────────────────────────────────────────┘
```

The notification stays visible, preventing Android from killing the service. It shows live health summary data.

---

## Implementation Roadmap (If Approach 1 is Chosen)

### Phase 1: Local Persistence (Day 1)

- [ ] Initialize Hive boxes for each health metric type
- [ ] Create TypeAdapters for `HeartRateRecord`, `StepRecord`, `SleepRecord`, etc.
- [ ] Update `HealthRepositoryImpl` to save data to Hive on each query
- [ ] Update `DashboardBloc` to load from Hive first, then BLE

### Phase 2: Foreground Service (Day 2)

- [ ] Add `flutter_foreground_task` to pubspec.yaml
- [ ] Add `<service>` declaration to AndroidManifest.xml
- [ ] Create `HealthDataTaskHandler` class
- [ ] Implement 5-minute periodic sync in task handler
- [ ] Implement real-time BLE stream listener in task handler
- [ ] Start service after device connects

### Phase 3: Notification & UX (Day 3)

- [ ] Create notification channel with health summary
- [ ] Update notification text with latest values on each sync
- [ ] Add toggle in Settings page: "Background Monitoring" ON/OFF
- [ ] Handle auto-restart on boot
- [ ] Request battery optimization exemption on first launch

### Phase 4: iOS Support (Future)

- [ ] iOS background modes: `bluetooth-central` + `background-processing`
- [ ] `BGTaskScheduler` for periodic sync
- [ ] CoreBluetooth background restoration

---

## FAQ

### Q: Will the ring stay connected when the app is in background?

**A:** With Approach 1 (Foreground Service), **yes**. The BLE GATT connection is maintained at the OS level, and the Dart code keeps running. Without a foreground service, Android will eventually kill the BLE connection.

### Q: What about battery drain?

**A:** A 5-minute interval foreground service with BLE uses approximately 3-5% battery per day. BLE Low Energy is designed for this exact use case. The persistent notification is the "cost" of running background BLE.

### Q: Will it work on Xiaomi / Huawei / Oppo phones?

**A:** Foreground services are the **only** reliable way on these OEMs. They aggressively kill background apps, but they respect foreground services with persistent notifications. Users may need to manually exempt the app from "battery optimization" in phone settings.

### Q: Can I still use the app normally while background monitoring runs?

**A:** Yes. The foreground service runs independently. When you open the app, the `DashboardBloc` reads from Hive (populated by the background service) for instant data display, plus live BLE updates.

### Q: What about iOS?

**A:** iOS supports BLE background mode via `bluetooth-central` in Info.plist. The BLE connection stays alive in background. For periodic sync, use `BGAppRefreshTask`. This is a separate implementation but uses the same Hive storage layer.

---

_End of Background Health Data Collection Plan_
