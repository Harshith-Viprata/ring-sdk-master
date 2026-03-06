# Sleep Data — Complete Functionality Documentation

> **Status:** ✅ Code implemented and ready  
> **Data source:** YC Smart Ring via `HealthDataType.sleep` (type = 1)  
> **SDK class:** `SleepDataInfo` → mapped to `SleepRecord` domain entity

---

## Table of Contents

1. [How Sleep Data Works (End-to-End)](#1-how-sleep-data-works-end-to-end)
2. [Sleep Data Acquisition — Step by Step](#2-sleep-data-acquisition--step-by-step)
3. [SDK Data Structure](#3-sdk-data-structure)
4. [Code Walkthrough — Every Layer](#4-code-walkthrough--every-layer)
5. [Sleep Page UI](#5-sleep-page-ui)
6. [Comparison: Sleep vs Steps (Identical Pattern)](#6-comparison-sleep-vs-steps-identical-pattern)
7. [When Does the Ring Record Sleep?](#7-when-does-the-ring-record-sleep)
8. [Troubleshooting](#8-troubleshooting)
9. [File Reference](#9-file-reference)

---

## 1. How Sleep Data Works (End-to-End)

Sleep data follows the **exact same pattern** as step data. The ring automatically detects when you're sleeping (via motion + heart rate sensors), records sleep stages, and stores the record on-device. The app then queries this historical data over BLE.

### Complete Flow Diagram

```
YC Smart Ring (worn overnight)
    │
    │  Ring detects sleep via:
    │    • Accelerometer (no wrist motion)
    │    • Heart rate variability patterns
    │    • Time of day context
    │
    ▼
Ring stores SleepDataInfo on-device
    │  Fields: deepSleepSeconds, lightSleepSeconds,
    │          remSleepSeconds, startTimeStamp, endTimeStamp
    │          + detail[] (per-stage segments with durations)
    │
    ▼ (BLE query: HealthDataType.sleep = 1)
YcProductPlugin.queryDeviceHealthData(1)
    │
    ▼ (native platform channel)
MethodChannel → Native Android SDK → BLE GATT read
    │
    ▼ (response parsed)
yc_product_plugin_method_channel.dart (line 277-282)
    │  Parses each item as: SleepDataInfo.fromJson(element)
    │
    ▼ (returned to Flutter)
BleDataSource.queryHealthData(HealthDataType.sleep)
    │
    ▼ (called by)
HealthRepositoryImpl.getSleepHistory()
    │  Maps: SleepDataInfo → SleepRecord domain entity
    │    deepMinutes  = deepSleepSeconds / 60
    │    lightMinutes = lightSleepSeconds / 60
    │    remMinutes   = remSleepSeconds / 60
    │    startTime    = DateTime.fromMillisecondsSinceEpoch(startTimeStamp × 1000)
    │    endTime      = DateTime.fromMillisecondsSinceEpoch(endTimeStamp × 1000)
    │
    ▼ (returned as Either<Failure, List<SleepRecord>>)
DashboardBloc._onLoadHealthData()
    │  Phase 1 Future.wait → index 2 = getSleepHistory()
    │  Result stored in state.sleepHistory
    │
    ▼ (BlocBuilder rebuild)
SleepPage reads state.sleepHistory
    │  Shows: summary card, pie chart, stage legend, history list
    │
    ▼
User sees sleep data! 🎉
```

---

## 2. Sleep Data Acquisition — Step by Step

### Step 1: App Starts → Device Connects

```
main() → initDependencies() → BleDataSource.init()
  → BleManager.autoConnect() (reconnects to saved ring)
```

### Step 2: Dashboard Triggers Health Data Load

```
DashboardPage BlocListener detects: connected → fires:
  1. dashBloc.add(LoadHealthData())    ← triggers history queries
  2. dashBloc.add(StartRealTimeMonitoring())
```

### Step 3: Sleep Data Queried in Phase 1

Inside `DashboardBloc._onLoadHealthData()`:

```dart
// Phase 1: parallel non-combinedData queries
final results = await Future.wait([
  _healthRepo.getHeartRateHistory(),    // index 0
  _healthRepo.getStepHistory(),         // index 1
  _healthRepo.getSleepHistory(),        // index 2  ← SLEEP IS HERE
  _healthRepo.getBloodPressureHistory(),// index 3
]);

final sleepResult = results[2];  // ← sleep result
```

### Step 4: Repository Queries SDK

Inside `HealthRepositoryImpl.getSleepHistory()`:

```dart
final response = await bleDataSource.queryHealthData(HealthDataType.sleep);
// HealthDataType.sleep = 1

// SDK internally calls:
//   YcProductPlugin().queryDeviceHealthData(1)
//   → native platform channel → BLE GATT read from ring
//   → returns List<SleepDataInfo>
```

### Step 5: SDK Parses Response

Inside `yc_product_plugin_method_channel.dart` (line 277):

```dart
case HealthDataType.sleep:
  debugPrint("睡眠");  // Chinese debug: "Sleep"
  for (var element in data) {
    SleepDataInfo info = SleepDataInfo.fromJson(element as Map);
    list.add(info);
  }
```

### Step 6: Repository Maps to Domain Entity

```dart
for (final item in items) {
  if (item is SleepDataInfo) {
    records.add(SleepRecord(
      deepMinutes:  (item.deepSleepSeconds / 60).round(),
      lightMinutes: (item.lightSleepSeconds / 60).round(),
      remMinutes:   (item.remSleepSeconds / 60).round(),
      awakeMinutes: 0,  // extracted from detail[] in future
      startTime:    DateTime.fromMillisecondsSinceEpoch(item.startTimeStamp * 1000),
      endTime:      DateTime.fromMillisecondsSinceEpoch(item.endTimeStamp * 1000),
    ));
  }
}
```

### Step 7: State Updated & UI Rebuilds

```dart
emit(state.copyWith(
  sleepHistory: sleepResult.fold(
    (_) => state.sleepHistory,
    (data) => data as List<SleepRecord>,
  ),
));
```

### Step 8: Every 60 Seconds — Auto-Refresh

```dart
_refreshTimer = Timer.periodic(Duration(seconds: 60), (_) {
  add(LoadHealthData());  // re-queries ALL history including sleep
});
```

---

## 3. SDK Data Structure

### `HealthDataType` Constants

```dart
class HealthDataType {
  static const step              = 0;  // Steps, distance, calories
  static const sleep             = 1;  // Sleep records  ← THIS ONE
  static const heartRate         = 2;  // Heart rate readings
  static const bloodPressure     = 3;  // Blood pressure
  static const combinedData      = 4;  // Combined: temp + SpO2 + glucose + steps
  static const invasiveData      = 5;  // Blood lipids + uric acid
  static const sportHistoryData  = 6;  // Sport mode records
  static const bodyIndexData     = 7;  // Body composition
  static const historyWearData   = 8;  // Wear history
}
```

### `SleepType` Constants (Sleep Stage Types)

```dart
class SleepType {
  static const int deepSleep  = 0xF1;  // 241 — Deep sleep stage
  static const int lightSleep = 0xF2;  // 242 — Light sleep stage
  static const int rem        = 0xF3;  // 243 — REM sleep stage
  static const int awake      = 0xF4;  // 244 — Awake period during sleep
}
```

### `SleepDataInfo` — What the SDK Returns

```dart
class SleepDataInfo {
  bool isNewSleepProtocol = false;   // New vs old sleep protocol flag
  int  startTimeStamp     = 0;       // Sleep start time (Unix seconds)
  int  endTimeStamp       = 0;       // Sleep end time (Unix seconds)
  int  deepSleepSeconds   = 0;       // Total deep sleep in SECONDS
  int  lightSleepSeconds  = 0;       // Total light sleep in SECONDS
  int  remSleepSeconds    = 0;       // Total REM sleep in SECONDS
  List<SleepDetailDataInfo> list = [];  // Per-segment detail list
}
```

### `SleepDetailDataInfo` — Per-Segment Detail

Each sleep session contains multiple segments showing transitions between stages:

```dart
class SleepDetailDataInfo {
  int startTimeStamp = 0;   // When this segment started (Unix seconds)
  int duration       = 0;   // Duration of this segment in seconds
  int sleepType      = 0;   // SleepType constant (0xF1/0xF2/0xF3/0xF4)
}
```

**Example detail list for a 6-hour sleep session:**

```
Segment 1: startTime=22:30, duration=2700s (45min), type=0xF2 (Light)
Segment 2: startTime=23:15, duration=5400s (90min), type=0xF1 (Deep)
Segment 3: startTime=00:45, duration=1800s (30min), type=0xF3 (REM)
Segment 4: startTime=01:15, duration=600s  (10min), type=0xF4 (Awake)
Segment 5: startTime=01:25, duration=3600s (60min), type=0xF2 (Light)
... (continues through the night)
```

### `SleepRecord` — Domain Entity (Our App)

```dart
class SleepRecord extends Equatable {
  final int deepMinutes;     // Deep sleep total in minutes
  final int lightMinutes;    // Light sleep total in minutes
  final int remMinutes;      // REM sleep total in minutes
  final int awakeMinutes;    // Awake periods total in minutes
  final DateTime startTime;  // Sleep session start
  final DateTime endTime;    // Sleep session end

  int get totalMinutes => deepMinutes + lightMinutes + remMinutes;
  // Note: awakeMinutes is NOT included in totalMinutes
}
```

---

## 4. Code Walkthrough — Every Layer

### Layer 1: SDK Plugin (`yc_product_plugin/`)

| File                                                   | Role                                                                                                      |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------- |
| `yc_product_plugin_data_type.dart` (line 1134-1296)    | Defines `HealthDataType.sleep = 1`, `SleepType` constants, `SleepDataInfo`, `SleepDetailDataInfo` classes |
| `yc_product_plugin_method_channel.dart` (line 277-282) | Parses raw JSON → `SleepDataInfo.fromJson()` when `healthDataType == sleep`                               |
| `yc_product_plugin.dart`                               | Exposes `queryDeviceHealthData(int type)`                                                                 |

### Layer 2: Core BLE (`core/ble/`)

| File                                                | Role                                                                |
| --------------------------------------------------- | ------------------------------------------------------------------- |
| `ble_manager.dart` → `queryHealthHistory(int type)` | Calls `_plugin.queryDeviceHealthData(type)` and returns raw `List?` |

### Layer 3: Data Source (`features/device/`)

| File                                                 | Role                                               |
| ---------------------------------------------------- | -------------------------------------------------- |
| `ble_data_source.dart` → `queryHealthData(int type)` | Delegates to `BleManager.queryHealthHistory(type)` |

### Layer 4: Repository (`features/dashboard/data/`)

| File                                                | Role                                                                                                               |
| --------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| `health_repository_impl.dart` → `getSleepHistory()` | Queries `HealthDataType.sleep`, maps `SleepDataInfo` → `SleepRecord`, returns `Either<Failure, List<SleepRecord>>` |

### Layer 5: Domain (`features/dashboard/domain/`)

| File                     | Role                                                                                                                                   |
| ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------- |
| `health_repository.dart` | Abstract contract: `Future<Either<Failure, List<SleepRecord>>> getSleepHistory()`                                                      |
| `health_data.dart`       | `SleepRecord` entity with `deepMinutes`, `lightMinutes`, `remMinutes`, `awakeMinutes`, `startTime`, `endTime`, computed `totalMinutes` |

### Layer 6: BLoC (`features/dashboard/presentation/bloc/`)

| File                                          | Role                                                                                              |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `dashboard_bloc.dart` → `_onLoadHealthData()` | Calls `getSleepHistory()` in Phase 1 `Future.wait` index 2, stores result in `state.sleepHistory` |
| `dashboard_state.dart`                        | `List<SleepRecord> sleepHistory` field                                                            |
| `dashboard_bloc.dart` → `_onRefreshMetric()`  | Handles `case 'sleep'` for on-demand refresh                                                      |

### Layer 7: UI (`features/sleep/presentation/pages/`)

| File              | Role                                                                                  |
| ----------------- | ------------------------------------------------------------------------------------- |
| `sleep_page.dart` | Full sleep UI: `_SleepSummaryCard` + `_SleepPieChart` + `_StageLegend` + History list |

---

## 5. Sleep Page UI

### UI Components

The Sleep page (`SleepPage`) is a **tab page** in the bottom navigation (Tab 2) and also accessible via the Dashboard's "Sleep" quick action button.

#### Component 1: Empty State

When `sleepHistory.isEmpty`:

- Shows bedtime icon (dimmed)
- "No sleep data yet"
- "Wear your device to bed to track your sleep patterns"

#### Component 2: `_SleepSummaryCard`

Shows the latest sleep session:

- Total duration in large text: **"6h 30m"**
- Sleep window: **"22:30 → 06:00"**
- Purple gradient background with bedtime icon

#### Component 3: `_SleepPieChart`

Uses `fl_chart` `PieChart` to show stage distribution:

| Stage       | Color                   | Data                                |
| ----------- | ----------------------- | ----------------------------------- |
| Deep Sleep  | `#3949AB` (dark indigo) | `record.deepMinutes`                |
| Light Sleep | `#42A5F5` (light blue)  | `record.lightMinutes`               |
| REM         | `#7E57C2` (purple)      | `record.remMinutes`                 |
| Awake       | `#FF7043` (orange)      | `record.awakeMinutes` (only if > 0) |

Each section shows its percentage of total sleep.

#### Component 4: `_StageLegend`

Color-coded legend showing duration per stage:

```
🟦 Deep Sleep     2h 15m
🟦 Light Sleep    2h 30m
🟪 REM            1h 15m
🟧 Awake          0h 30m
```

#### Component 5: History List

Shows last 7 nights of sleep:

```
06/03    6h 30m
05/03    7h 15m
04/03    5h 45m
...
```

### Navigation to Sleep Page

Sleep can be accessed via:

1. **Bottom navigation bar** → Tab 2 ("Sleep") → route `/sleep`
2. **Dashboard quick action** → "Sleep" button → `context.go(AppRoutes.sleep)`

---

## 6. Comparison: Sleep vs Steps (Identical Pattern)

| Aspect                     | Steps                                          | Sleep                                                      |
| -------------------------- | ---------------------------------------------- | ---------------------------------------------------------- |
| **SDK constant**           | `HealthDataType.step = 0`                      | `HealthDataType.sleep = 1`                                 |
| **SDK return type**        | `StepDataInfo`                                 | `SleepDataInfo`                                            |
| **Fields**                 | `step`, `distance`, `calories`                 | `deepSleepSeconds`, `lightSleepSeconds`, `remSleepSeconds` |
| **Timestamps**             | `startTimeStamp`, `endTimeStamp`               | `startTimeStamp`, `endTimeStamp`                           |
| **Query method**           | `getStepHistory()`                             | `getSleepHistory()`                                        |
| **BLE data type int**      | `0`                                            | `1`                                                        |
| **Plugin parsing**         | `StepDataInfo.fromJson(element)`               | `SleepDataInfo.fromJson(element)`                          |
| **Phase in DashboardBloc** | Phase 1 index 1                                | Phase 1 index 2                                            |
| **Domain entity**          | `StepRecord`                                   | `SleepRecord`                                              |
| **State field**            | `state.stepHistory`                            | `state.sleepHistory`                                       |
| **Computed getter**        | `todaySteps`, `todayCalories`, `todayDistance` | `totalMinutes`                                             |
| **Detail page**            | ActivityPage                                   | SleepPage                                                  |
| **Dashboard card**         | ✅ MetricCard on grid                          | ❌ No card (Quick Action only)                             |
| **Also in combinedData?**  | ✅ Yes (type=4 has steps)                      | ❌ No (sleep is separate query)                            |
| **Real-time stream?**      | ✅ `deviceRealStep` events                     | ❌ No real-time sleep events                               |

> **Key difference:** Steps has real-time streaming (`deviceRealStep` events update `liveSteps`). Sleep does NOT have real-time events — it is **history-only** data, queried from device storage. This is expected because sleep is recorded as a completed session, not a live metric.

---

## 7. When Does the Ring Record Sleep?

### Sleep Detection Mechanism

The YC Smart Ring uses a **combination of sensors** to automatically detect sleep:

1. **Accelerometer** — Detects prolonged lack of wrist/finger motion
2. **Heart rate sensor** — Identifies resting heart rate patterns and HRV changes characteristic of sleep
3. **Time context** — Uses time-of-day heuristics (more likely to classify stillness as sleep at night)

### Sleep Recording Rules

| Rule                  | Detail                                                                          |
| --------------------- | ------------------------------------------------------------------------------- |
| **Automatic**         | Ring records sleep sessions **automatically** — no manual trigger needed        |
| **Minimum duration**  | Ring typically requires ~30 minutes of detected sleep before creating a record  |
| **Segment tracking**  | Ring tracks transitions between Deep → Light → REM → Awake throughout the night |
| **Storage**           | Sleep records are stored on-device until queried/deleted                        |
| **Multiple sessions** | Ring can record multiple sleep sessions (e.g., overnight + nap)                 |
| **Data availability** | Sleep data is available after the session ends (when you wake up)               |

### Important Notes

- **Ring must be worn** — The ring needs to be on your finger during sleep
- **Battery matters** — Ring needs sufficient battery to last through the night
- **Data stays on device** — Until the app queries it via BLE, the data is stored on the ring
- **Data persists** — Even if the app was not connected during sleep, the data is retained on the ring and can be synced later
- **Query timing** — `getSleepHistory()` fetches ALL stored sleep records, not just last night

---

## 8. Troubleshooting

### "No sleep data yet" — Possible Causes

| Cause                          | Solution                                                                         |
| ------------------------------ | -------------------------------------------------------------------------------- |
| Ring not worn overnight        | Wear the ring to bed and check the next morning                                  |
| Ring battery died during night | Charge ring before bed; ensure battery > 40%                                     |
| Device doesn't support sleep   | Check `DeviceFeature.isSupportSleep` flag                                        |
| BLE query failed silently      | Check terminal for `[HealthRepo] getSleepHistory error:`                         |
| SDK returned empty list        | Check terminal for `[HealthRepo] getSleepHistory raw response: 0 items`          |
| Data type mismatch             | Check terminal for `[HealthRepo] Sleep item type:` — should show `SleepDataInfo` |

### Debug Logging (Currently Active)

The following debug prints have been added to trace sleep data:

```
[HealthRepo] getSleepHistory raw response: X items, types: {SleepDataInfo}
[HealthRepo] getSleepHistory extracted: X items
[HealthRepo] Sleep item type: SleepDataInfo, value: ...
[HealthRepo] Sleep record: deep=Xmin, light=Xmin, rem=Xmin, total=Xmin, start=..., end=...
[HealthRepo] getSleepHistory final: X sleep records
[DashboardBloc] Sleep history: X records
[DashboardBloc] Latest sleep: deep=Xmin, light=Xmin, rem=Xmin, total=Xmin, start=..., end=...
```

### What Each Log Tells You

| Log                                             | Meaning                                                            |
| ----------------------------------------------- | ------------------------------------------------------------------ |
| `raw response: null items`                      | BLE query failed or returned null — ring may be disconnected       |
| `raw response: 0 items`                         | Ring returned empty list — no sleep recorded (not worn overnight?) |
| `raw response: X items, types: {}`              | Items returned but not `SleepDataInfo` — SDK parsing issue         |
| `raw response: X items, types: {SleepDataInfo}` | ✅ Success — ring has sleep data                                   |
| `Sleep record: deep=0, light=0, rem=0, total=0` | Something returned but all zeros — firmware/sensor issue           |
| `Sleep history: X records` in DashboardBloc     | ✅ Sleep data reached the BLoC state and will display in UI        |

---

## 9. File Reference

| Layer       | File                                                                   | Lines         | Purpose                                                                     |
| ----------- | ---------------------------------------------------------------------- | ------------- | --------------------------------------------------------------------------- |
| SDK types   | `yc_product_plugin/lib/yc_product_plugin_data_type.dart`               | 1134-1296     | `HealthDataType.sleep`, `SleepType`, `SleepDataInfo`, `SleepDetailDataInfo` |
| SDK channel | `yc_product_plugin/lib/yc_product_plugin_method_channel.dart`          | 277-282       | Parses sleep JSON → `SleepDataInfo`                                         |
| BLE Manager | `lib/core/ble/ble_manager.dart`                                        | 217-225       | `queryHealthHistory(int type)` — generic query                              |
| Data Source | `lib/features/device/data/datasources/ble_data_source.dart`            | 132           | `queryHealthData(int type)` — forwards to BleManager                        |
| Repository  | `lib/features/dashboard/data/repositories/health_repository_impl.dart` | 237-276       | `getSleepHistory()` — `SleepDataInfo` → `SleepRecord` mapping               |
| Interface   | `lib/features/dashboard/domain/repositories/health_repository.dart`    | 33            | `Future<Either<Failure, List<SleepRecord>>> getSleepHistory()`              |
| Entity      | `lib/features/dashboard/domain/entities/health_data.dart`              | 103-126       | `SleepRecord` domain entity                                                 |
| BLoC        | `lib/features/dashboard/presentation/bloc/dashboard_bloc.dart`         | 34-37, 96-97  | Phase 1 query + state emit                                                  |
| State       | `lib/features/dashboard/presentation/bloc/dashboard_state.dart`        | 9, 33, 55, 76 | `sleepHistory` field                                                        |
| UI          | `lib/features/sleep/presentation/pages/sleep_page.dart`                | 1-346         | Complete sleep page with chart                                              |
| Router      | `lib/config/routes/app_router.dart`                                    | 82-86         | `/sleep` route → Tab 2                                                      |
| Dashboard   | `lib/features/dashboard/presentation/pages/dashboard_page.dart`        | 243-249       | Quick Action "Sleep" button                                                 |

---

_End of Sleep Functionality Documentation_
