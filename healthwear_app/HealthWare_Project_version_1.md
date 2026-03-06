# HealthWare App — Complete Project Documentation (v1)

> **Last updated:** March 2026  
> **Platform status:** Android (active testing) · iOS (SDK-ready, needs native setup)  
> **SDK:** YuCheng YC Smart Ring SDK via `yc_product_plugin` Flutter plugin

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture & Code Structure](#2-architecture--code-structure)
3. [BLE Communication Layer](#3-ble-communication-layer)
4. [Real-Time Health Data Acquisition](#4-real-time-health-data-acquisition)
5. [Historical Health Data Queries](#5-historical-health-data-queries)
6. [Health Data Points — Complete Reference](#6-health-data-points--complete-reference)
7. [Dashboard & Refresh Mechanism](#7-dashboard--refresh-mechanism)
8. [ECG Subsystem](#8-ecg-subsystem)
9. [Device Management](#9-device-management)
10. [iOS Setup Guide](#10-ios-setup-guide)
11. [Present / Past / Future Data Handling](#11-present--past--future-data-handling)
12. [Key Learnings & Known Quirks](#12-key-learnings--known-quirks)
13. [Future Roadmap](#13-future-roadmap)

---

## 1. Project Overview

HealthWare is a Flutter wearable companion app that connects to a **YuCheng (YC) Smart Ring/Watch** over BLE. The app acquires 10+ health metrics in real time, displays them on a premium dark-themed dashboard, stores historical data from the device, and provides dedicated detail pages for each metric.

### Key Capabilities

| Capability                            | Status                            |
| ------------------------------------- | --------------------------------- |
| BLE scanning & connection             | ✅ Working                        |
| Auto-reconnect on app launch          | ✅ Working                        |
| Real-time heart rate                  | ✅ Working                        |
| Real-time SpO2                        | ✅ Working                        |
| Real-time blood pressure              | ✅ Working                        |
| Real-time body temperature            | ✅ Working                        |
| Real-time steps + calories + distance | ✅ Working                        |
| Real-time blood glucose               | ✅ Working                        |
| Real-time stress level                | ✅ Working                        |
| ECG waveform + HRV + AF detection     | ✅ Working                        |
| Sleep history (deep/light/REM)        | ✅ Working                        |
| On-demand measurements                | ✅ Working                        |
| Dashboard 60-second auto-refresh      | ✅ Working                        |
| iOS support                           | ⏳ SDK-ready, needs native config |
| Local data persistence (Hive)         | ⏳ Not yet implemented            |
| Cloud sync / API upload               | ⏳ Not yet implemented            |

---

## 2. Architecture & Code Structure

The project follows **Clean Architecture** with **BLoC** for state management.

### Folder Structure

```
healthwear_app/
├── lib/
│   ├── main.dart                           # App entry point
│   ├── config/
│   │   └── routes/
│   │       └── app_router.dart             # GoRouter with StatefulShellRoute
│   ├── core/
│   │   ├── ble/
│   │   │   ├── ble_manager.dart            # Singleton BLE wrapper (377 lines)
│   │   │   └── ble_event_handler.dart      # Native event → typed callbacks
│   │   ├── di/
│   │   │   └── injection_container.dart    # GetIt dependency injection
│   │   ├── error/
│   │   │   └── failures.dart               # Failure types (BleFailure, etc.)
│   │   ├── models/
│   │   │   └── health_models.dart          # Real-time + historical data models
│   │   └── usecases/
│   │       └── usecase.dart                # Base UseCase interface
│   ├── features/
│   │   ├── dashboard/                      # Main dashboard feature
│   │   │   ├── data/repositories/
│   │   │   │   └── health_repository_impl.dart  # SDK → domain mapping (491 lines)
│   │   │   ├── domain/
│   │   │   │   ├── entities/health_data.dart    # Domain entities (HealthReading, records)
│   │   │   │   ├── repositories/health_repository.dart  # Abstract contract
│   │   │   │   └── usecases/health_usecases.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── dashboard_bloc.dart      # 2-phase load + 60s refresh
│   │   │       │   ├── dashboard_event.dart
│   │   │       │   └── dashboard_state.dart     # 10 live fields + 7 history lists
│   │   │       └── pages/dashboard_page.dart
│   │   ├── device/                         # BLE device scan & connect
│   │   │   ├── data/
│   │   │   │   ├── datasources/ble_data_source.dart  # Adapter over BleManager
│   │   │   │   └── repositories/device_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── repositories/device_repository.dart
│   │   │   │   └── usecases/device_usecases.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/device_bloc.dart
│   │   │       └── pages/scan_page.dart
│   │   ├── ecg/                            # ECG measurement feature
│   │   │   ├── data/repositories/ecg_repository_impl.dart
│   │   │   ├── domain/repositories/ecg_repository.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/ecg_bloc.dart
│   │   │       └── pages/ecg_page.dart
│   │   ├── heart_rate/                     # Heart rate detail page
│   │   ├── blood_oxygen/                   # SpO2 detail page
│   │   ├── blood_pressure/                 # Blood pressure detail page
│   │   ├── blood_glucose/                  # Blood glucose detail page
│   │   ├── temperature/                    # Temperature detail page
│   │   ├── stress/                         # Stress level detail page
│   │   ├── activity/                       # Activity tab page
│   │   ├── sleep/                          # Sleep tab page
│   │   ├── metrics/                        # All metrics overview
│   │   ├── health_metrics/                 # Health metrics sub-feature
│   │   └── settings/                       # Settings tab page
│   └── shared/
│       ├── theme/
│       │   └── app_theme.dart              # Dark theme, Outfit font, AppColors
│       └── widgets/
│           ├── metric_card.dart            # Glassmorphism health card
│           └── ble_status_bar.dart         # BLE connection status banner
```

### Layer Responsibilities

```
┌──────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                   │
│  BLoC / Cubit ←→ Pages / Widgets                     │
│  (dashboard_bloc.dart, device_bloc.dart, ecg_bloc)   │
├──────────────────────────────────────────────────────┤
│  DOMAIN LAYER                                         │
│  Entities (HealthReading, StepRecord, etc.)           │
│  Repository interfaces (abstract contracts)           │
│  Use Cases (GetHeartRateHistoryUseCase, etc.)         │
├──────────────────────────────────────────────────────┤
│  DATA LAYER                                           │
│  Repository implementations                           │
│  Data Sources (BleDataSource)                         │
├──────────────────────────────────────────────────────┤
│  CORE / INFRASTRUCTURE                                │
│  BleManager (singleton SDK wrapper)                   │
│  BleEventHandler (native event parser)                │
│  Dependency Injection (GetIt)                         │
│  Health Models (fromMap factories)                    │
└──────────────────────────────────────────────────────┘
```

### Dependency Injection (GetIt)

Registered in `injection_container.dart` at app startup:

```
initDependencies() flow:
  1. Register BleDataSource (lazy singleton)
  2. Initialize native BLE SDK: await BleDataSource.init(reconnect: true)
  3. Register Repositories (DeviceRepository, HealthRepository, EcgRepository)
  4. Register Use Cases (Scan, Connect, Disconnect, SyncTime, History queries, Measurements)
  5. Register BLoCs (DeviceBloc, DashboardBloc, EcgBloc) as factories
```

### Navigation (GoRouter)

```
StatefulShellRoute (bottom navigation):
  ├── Tab 0: Home → DashboardPage (/)
  ├── Tab 1: Activity → ActivityPage (/activity)
  ├── Tab 2: Sleep → SleepPage (/sleep)
  └── Tab 3: Settings → SettingsPage (/settings)

Full-screen routes (pushed above shell):
  ├── /scan          → ScanPage (BLE device scanner)
  ├── /heart-rate    → HeartRatePage
  ├── /ecg           → EcgPage
  ├── /metrics       → MetricsPage (all metrics overview)
  ├── /blood-oxygen  → BloodOxygenPage
  ├── /blood-pressure→ BloodPressurePage
  ├── /temperature   → TemperaturePage
  ├── /blood-glucose → BloodGlucosePage
  └── /stress        → StressPage
```

---

## 3. BLE Communication Layer

### Architecture Overview

```
┌──────────────┐     ┌─────────────────┐     ┌──────────────────┐
│   Flutter     │     │   BleDataSource  │     │   BleManager     │
│   BLoCs       │────▶│   (adapter)      │────▶│   (singleton)    │
│               │     │                  │     │                  │
│ DeviceBloc    │     │ eventStream      │     │ YcProductPlugin  │
│ DashboardBloc │◀────│ (broadcast)      │◀────│ onListening()    │
│ EcgBloc       │     │                  │     │                  │
└──────────────┘     └─────────────────┘     └──────────────────┘
                                                       │
                                                       ▼
                                              ┌──────────────────┐
                                              │ Native Android   │
                                              │ (YC SDK .aar)    │
                                              │                  │
                                              │ BLE GATT ←→ Ring │
                                              └──────────────────┘
```

### Key Classes

#### `BleManager` (core/ble/ble_manager.dart)

The **single** entry point to the YC SDK. All BLE operations go through this class.

| Method                                            | Purpose                                                                |
| ------------------------------------------------- | ---------------------------------------------------------------------- |
| `init()`                                          | Initializes the native YcProductPlugin. Called once before `runApp()`. |
| `scan({seconds: 6})`                              | Scans for nearby YC devices, returns sorted by signal strength.        |
| `connect(device)`                                 | 15-second timeout connection with automatic post-connection setup.     |
| `autoConnect()`                                   | Reads saved MAC from SharedPreferences and reconnects if found.        |
| `disconnect()`                                    | Disconnects and clears saved device.                                   |
| `onEvent(handler)`                                | Registers a listener for ALL native BLE events.                        |
| `setRealTimeUpload(enable, type)`                 | Enables per-type real-time data upload.                                |
| `setDeviceHealthMonitoringMode(enable, interval)` | Turns on optical sensors for continuous monitoring.                    |
| `queryHealthHistory(healthDataType)`              | Fetches stored data from device by type.                               |
| `startECG() / stopECG() / getECGResult()`         | ECG measurement lifecycle.                                             |
| `startMeasure(type) / stopMeasure(type)`          | On-demand single-metric measurement.                                   |

**Post-Connection Setup** (happens automatically in `connect()`):

```
1. getDeviceFeature()             — 5s timeout
2. realTimeDataUpload(step)       — fire-and-forget, 1s delay
3. realTimeDataUpload(combinedData) — fire-and-forget, 500ms delay
4. setDeviceUserInfo(170, 70, 30, male) — 5s timeout
5. setDeviceSyncPhoneTime()       — 5s timeout
6. _saveConnectedDevice(device)   — SharedPreferences for auto-reconnect
```

#### `BleDataSource` (features/device/data/datasources/ble_data_source.dart)

A Clean Architecture **adapter** that delegates to `BleManager` and provides:

- `eventStream` — a `broadcast StreamController<Map>` driven by `BleManager.onEvent()`
- All SDK commands forwarded as simple method calls

#### `BleEventHandler` (core/ble/ble_event_handler.dart)

Parses raw native events into typed health data objects using callback-style API:

| Callback                 | Triggered By                                         | Data Type                      |
| ------------------------ | ---------------------------------------------------- | ------------------------------ |
| `onBluetoothStateChange` | `NativeEventType.bluetoothStateChange`               | `int` (connected/disconnected) |
| `onHeartRate`            | `NativeEventType.deviceRealHeartRate`                | `RealTimeHeartRate`            |
| `onBloodOxygen`          | `NativeEventType.deviceRealBloodOxygen`              | `RealTimeBloodOxygen`          |
| `onBloodPressure`        | `NativeEventType.deviceRealBloodPressure`            | `RealTimeBloodPressure`        |
| `onTemperature`          | `NativeEventType.deviceRealTemperature`              | `RealTimeTemperature`          |
| `onSteps`                | `NativeEventType.deviceRealStep`                     | `RealTimeSteps`                |
| `onPressure`             | `NativeEventType.deviceRealPressure`                 | `RealTimePressure` (stress)    |
| `onBloodGlucose`         | `NativeEventType.deviceRealBloodGlucose`             | `RealTimeBloodGlucose`         |
| `onECGData`              | `NativeEventType.deviceRealECGData`                  | `List<int>`                    |
| `onECGFilteredData`      | `NativeEventType.deviceRealECGFilteredData`          | `List<int>`                    |
| `onECGEnd`               | `NativeEventType.deviceEndECG`                       | `void`                         |
| `onPhotoState`           | `NativeEventType.deviceControlPhotoStateChange`      | `bool`                         |
| (measurement result)     | `NativeEventType.deviceHealthDataMeasureStateChange` | varies                         |

---

## 4. Real-Time Health Data Acquisition

### How Real-Time Data Flows

```
YC Ring/Watch Sensors
    │
    ▼ (BLE GATT notifications)
Native Android SDK (YcProductPlugin)
    │
    ▼ (EventChannel → onListening callback)
BleManager.onEvent(handler)
    │
    ▼ (forwards raw Map events)
BleDataSource._eventController
    │
    ▼ (broadcast StreamController)
Two parallel consumers:
    ├── DeviceBloc._onSdkEvent()    → connection state, device info
    └── HealthRepositoryImpl.streamRealTimeHealth()
            │
            ▼ (filters health-related events, maps to HealthReading)
        DashboardBloc._onStartRealTime() listens to stream
            │
            ▼ (emits RealTimeHealthUpdate events)
        _onRealTimeUpdate() → updates DashboardState live* fields
            │
            ▼ (BlocBuilder rebuild)
        Dashboard UI (MetricCard widgets update)
```

### Real-Time Event Types & Their Frequencies

| Metric              | NativeEventType           | Emission Frequency   | Notes                                   |
| ------------------- | ------------------------- | -------------------- | --------------------------------------- |
| Heart Rate          | `deviceRealHeartRate`     | ~Every 5-10 seconds  | When health monitoring is enabled       |
| Blood Oxygen (SpO2) | `deviceRealBloodOxygen`   | ~Every 10-30 seconds | Requires optical sensors on             |
| Blood Pressure      | `deviceRealBloodPressure` | ~Every 15-30 seconds | Systolic + diastolic values             |
| Temperature         | `deviceRealTemperature`   | ~Every 30-60 seconds | Body surface temperature in °C          |
| Steps               | `deviceRealStep`          | ~Every 1-5 minutes   | Includes step count, calories, distance |
| Stress (Pressure)   | `deviceRealPressure`      | ~Every 30-60 seconds | 0-100 scale                             |
| Blood Glucose       | `deviceRealBloodGlucose`  | ~Every 5-15 minutes  | In mmol/L value                         |

> **Note:** Frequencies vary based on device model, firmware, and the `interval` parameter set in `setDeviceHealthMonitoringMode()`. The current app uses interval = 5 minutes for periodic monitoring.

### `streamRealTimeHealth()` — How Events Become HealthReading Objects

The `HealthRepositoryImpl.streamRealTimeHealth()` method:

1. **Filters** `BleDataSource.eventStream` for any health-related `NativeEventType`
2. **Parses** each event type using careful null-safe map access patterns:
   ```
   heartRate:     raw['heartRate'] ?? raw['value'] ?? 0
   spo2:          raw['bloodOxygen'] ?? raw['value'] ?? 0
   temperature:   raw['temperature'] ?? raw['value'] ?? 0
   steps:         raw['sportStep'] ?? raw['step'] ?? raw['steps'] ?? raw['value'] ?? 0
   calories:      raw['sportCalorie'] ?? raw['calories'] ?? 0
   distanceKm:    raw['sportDistance'] ?? raw['distance'] ?? 0
   stressLevel:   raw['pressure'] ?? raw['value'] ?? 0
   bloodGlucose:  raw['bloodGlucose'] ?? raw['value'] ?? 0
   ```
3. **Returns** a `HealthReading` domain entity with all non-null fields set

### Enabling Real-Time Data

Two prerequisites must be enabled for real-time data:

```dart
// 1. Enable real-time data upload (BOTH step and combinedData types)
_healthRepo.setRealTimeUpload(true);
  // internally calls:
  //   bleDataSource.setRealTimeUpload(true, type: DeviceRealTimeDataType.step)
  //   await 500ms delay
  //   bleDataSource.setRealTimeUpload(true, type: DeviceRealTimeDataType.combinedData)

// 2. Enable hardware health monitoring (turns on optical sensors)
_healthRepo.enableHealthMonitoring(interval: 5);
  // internally calls:
  //   bleDataSource.setHealthMonitoring(enable: true, interval: 5)
```

Both are called in `DashboardBloc._onStartRealTime()` as **non-blocking** fire-and-forget operations.

---

## 5. Historical Health Data Queries

### SDK Health Data Types

The `yc_product_plugin` SDK defines these `HealthDataType` constants:

| Constant                       | Value      | Data Returns                                             |
| ------------------------------ | ---------- | -------------------------------------------------------- |
| `HealthDataType.step`          | `0`        | Step count per period                                    |
| `HealthDataType.heartRate`     | `1`        | Heart rate readings                                      |
| `HealthDataType.sleep`         | `2`        | Sleep sessions (deep/light/REM)                          |
| `HealthDataType.bloodPressure` | `3`        | Systolic/diastolic readings                              |
| `HealthDataType.combinedData`  | `4`        | **Multiplex**: step + temp + glucose + SpO2 in one query |
| `HealthDataType.bloodOxygen`   | (separate) | SpO2 percentage readings                                 |

### 2-Phase Query Strategy

The `DashboardBloc._onLoadHealthData()` uses a **2-phase query** to avoid concurrent BLE command corruption:

```
Phase 1 — Parallel (non-combinedData queries):
  ├── getHeartRateHistory()     → HealthDataType.heartRate (type=1)
  ├── getStepHistory()          → HealthDataType.step (type=0)
  ├── getSleepHistory()         → HealthDataType.sleep (type=2)
  └── getBloodPressureHistory() → HealthDataType.bloodPressure (type=3)

Phase 2 — Serial (single combinedData query):
  └── getCombinedDataAll()      → HealthDataType.combinedData (type=4)
      Extracts:
        ├── steps (aggregated per-day, highest count wins)
        ├── temperature (filtered: > 30°C, bogus 0.15 excluded)
        ├── blood glucose (> 0 mmol/L)
        └── SpO2 (> 0%)
```

**Why 2-phase?** The BLE protocol can only process one `queryDeviceHealthData()` call at a time on `combinedData`. Running multiple queries concurrently results in corrupted/mixed responses.

### Step Count Priority Logic

```
1. Phase 1 queries step-specific data (HealthDataType.step = type 0)
2. Phase 2 queries combinedData (HealthDataType.combinedData = type 4)
3. Compare: max step count from each source
4. Use whichever source has the HIGHER count

This handles the case where:
  - step-specific query returns stale/low counts (e.g., 64)
  - combinedData has the correct cumulative count (e.g., 3101)
```

### Historical Record Models

All records have a `fromMap` factory that handles multiple SDK key formats:

| Record Type           | Fields                                                                              | SDK Type                                 |
| --------------------- | ----------------------------------------------------------------------------------- | ---------------------------------------- |
| `HeartRateRecord`     | `bpm`, `minBpm`, `maxBpm`, `time`                                                   | `HeartRateDataInfo`                      |
| `StepRecord`          | `steps`, `calories`, `distanceKm`, `date`                                           | `StepDataInfo` or `CombinedDataDataInfo` |
| `SleepRecord`         | `deepMinutes`, `lightMinutes`, `remMinutes`, `awakeMinutes`, `startTime`, `endTime` | `SleepDataInfo`                          |
| `BloodOxygenRecord`   | `spo2`, `time`                                                                      | `CombinedDataDataInfo`                   |
| `BloodPressureRecord` | `systolic`, `diastolic`, `time`                                                     | `BloodPressureDataInfo`                  |
| `TemperatureRecord`   | `celsius`, `time`                                                                   | `CombinedDataDataInfo`                   |
| `BloodGlucoseRecord`  | `glucoseMmol`, `time`                                                               | `CombinedDataDataInfo`                   |

---

## 6. Health Data Points — Complete Reference

### Real-Time Data Models

| Class                   | Fields                                              | Map Keys                                                                          |
| ----------------------- | --------------------------------------------------- | --------------------------------------------------------------------------------- |
| `RealTimeHeartRate`     | `bpm: int`                                          | `heartRate`, `value`                                                              |
| `RealTimeBloodOxygen`   | `spo2: int`                                         | `bloodOxygen`, `value`                                                            |
| `RealTimeBloodPressure` | `systolic: int`, `diastolic: int`                   | `systolicBloodPressure`, `diastolicBloodPressure`                                 |
| `RealTimeTemperature`   | `celsius: double`                                   | `temperature`, `value`                                                            |
| `RealTimeSteps`         | `steps: int`, `calories: int`, `distanceKm: double` | `sportStep`/`step`/`steps`, `sportCalorie`/`calories`, `sportDistance`/`distance` |
| `RealTimePressure`      | `stressLevel: int` (0-100)                          | `pressure`, `value`                                                               |
| `RealTimeBloodGlucose`  | `mmolL: double`                                     | `bloodGlucose`, `value`                                                           |

### Domain Entities (health_data.dart)

| Entity          | Fields                                                                                                                                                             | Computed Properties                                                                              |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| `HealthReading` | All nullable: `heartRate?`, `spo2?`, `systolic?`, `diastolic?`, `temperature?`, `steps?`, `calories?`, `distanceKm?`, `stressLevel?`, `bloodGlucose?`, `timestamp` | —                                                                                                |
| `StepRecord`    | `steps`, `calories`, `distanceKm`, `date`                                                                                                                          | `estimateCalories(steps)` → `steps × 0.04`, `estimateDistanceKm(steps)` → `steps × 0.762 / 1000` |
| `SleepRecord`   | `deepMinutes`, `lightMinutes`, `remMinutes`, `awakeMinutes`, `startTime`, `endTime`                                                                                | `totalMinutes` → deep + light + REM                                                              |
| `EcgResult`     | `heartRate`, `hrvNorm?`, `respiratoryRate?`, `qrsType`, `afFlag`                                                                                                   | —                                                                                                |

### DashboardState — Live Values

| State Field        | Type      | Source           |
| ------------------ | --------- | ---------------- |
| `liveHeartRate`    | `int?`    | Real-time stream |
| `liveSteps`        | `int?`    | Real-time stream |
| `liveSpO2`         | `int?`    | Real-time stream |
| `liveTemperature`  | `double?` | Real-time stream |
| `liveSystolic`     | `int?`    | Real-time stream |
| `liveDiastolic`    | `int?`    | Real-time stream |
| `liveStress`       | `int?`    | Real-time stream |
| `liveBloodGlucose` | `double?` | Real-time stream |
| `liveCalories`     | `int?`    | Real-time stream |
| `liveDistance`     | `double?` | Real-time stream |

### DashboardState — Computed Getters

| Getter               | Logic                                                                  |
| -------------------- | ---------------------------------------------------------------------- |
| `todaySteps`         | Sum of step records for today's date; returns `max(sum, liveSteps)`    |
| `todayCalories`      | `liveCalories` if > 0, else latest today's record calories             |
| `todayDistance`      | `liveDistance` if > 0, else latest today's record distance             |
| `latestHeartRate`    | `liveHeartRate` if > 0, else `heartRateHistory.last.bpm`               |
| `latestBloodGlucose` | `liveBloodGlucose` if > 0, else `bloodGlucoseHistory.last.glucoseMmol` |

---

## 7. Dashboard & Refresh Mechanism

### How the Dashboard Updates

The dashboard uses a **dual-update system**:

#### 1. Real-Time Updates (continuous)

```
DashboardBloc._onStartRealTime():
  1. Subscribe to healthRepo.streamRealTimeHealth()
  2. Each HealthReading → RealTimeHealthUpdate event
  3. _onRealTimeUpdate() updates live* state fields
  4. BlocBuilder triggers UI rebuild on state change
```

#### 2. Periodic Historical Refresh (every 60 seconds)

```
DashboardBloc._onStartRealTime():
  _refreshTimer = Timer.periodic(Duration(seconds: 60), (_) {
    add(LoadHealthData());  // triggers full 2-phase history reload
  });
```

**What happens every 60 seconds:**

```
Timer fires → LoadHealthData event
  → Phase 1 parallel queries (HR, Steps, Sleep, BP)
  → Phase 2 serial query (combinedData: step+temp+glucose+spo2)
  → state.copyWith(all 7 history lists updated)
  → UI rebuilds with latest historical data
```

### Dashboard State Lifecycle

```
App Start
    │
    ▼
DashboardState(status: initial)
    │
    ▼ LoadHealthData event
DashboardState(status: loading)
    │
    ▼ 2-phase query completes
DashboardState(status: loaded, histories populated)
    │
    ▼ StartRealTimeMonitoring event
Stream subscription active + 60s timer started
    │
    ▼ Every stream event
DashboardState(live* fields update in real time)
    │
    ▼ Every 60 seconds
DashboardState(histories re-synced from device)
```

### Dashboard UI Cards

Each health metric is shown in a `MetricCard` widget with:

- Glassmorphism styling (blur + gradient)
- Metric-specific color from `AppColors`
- Icon, value, unit display
- Tap → navigates to detail page
- Loading shimmer state

---

## 8. ECG Subsystem

### ECG Data Flow

```
User taps "Start ECG"
    │
    ▼
EcgBloc._onStart()
    ├── ecgRepository.startEcg() → BleManager.startECG()
    ├── Subscribe to ecgRepository.streamEcgFilteredData() → waveform points
    ├── Subscribe to BleDataSource.eventStream (HRV, RR, ECG data)
    ├── Subscribe to ecgRepository.onEcgEnd() → completion signal
    └── Start 1-second timer for elapsed time display
    │
    ▼ (during measurement ~30-60 seconds)
Filtered ECG samples arrive → add to waveformData (max 500 points)
HRV / HR data arrives → update state.heartRate, state.hrvNorm
    │
    ▼ (device signals ECG end)
EcgCompleted event
    ├── Cancel all subscriptions
    └── ecgRepository.getEcgResult() → BleManager.getECGResult()
        Returns: EcgResult(heartRate, hrvNorm, respiratoryRate, qrsType, afFlag)
```

### ECG State Fields

| Field             | Type           | Description                           |
| ----------------- | -------------- | ------------------------------------- |
| `status`          | `EcgStatus`    | idle / measuring / completed / error  |
| `waveformData`    | `List<double>` | Last 500 filtered ECG waveform points |
| `heartRate`       | `int?`         | Real-time HR from ECG algorithm       |
| `hrvNorm`         | `double?`      | Heart rate variability (normalized)   |
| `respiratoryRate` | `int?`         | Estimated respiratory rate            |
| `afFlag`          | `bool`         | Atrial fibrillation detected          |
| `elapsedSeconds`  | `int`          | Seconds since measurement started     |

---

## 9. Device Management

### BLE Connection Lifecycle

```
ScanPage
    │
    ▼ User taps "Scan"
DeviceBloc.add(StartScan(seconds: 6))
    │
    ▼ bleDataSource.scanDevice(seconds: 6)
Discovered devices list → UI shows results
    │
    ▼ User taps a device
DeviceBloc.add(ConnectToDevice(device))
    │
    ▼ bleDataSource.connect(device)
BleManager.connect():
    1. _plugin.connectDevice(device) — 15s timeout
    2. getDeviceFeature() — 5s timeout
    3. realTimeDataUpload(step) — fire-and-forget
    4. realTimeDataUpload(combinedData) — fire-and-forget
    5. setDeviceUserInfo(170, 70, 30, male) — 5s timeout
    6. setDeviceSyncPhoneTime() — 5s timeout
    7. _saveConnectedDevice(device) — SharedPreferences
    │
    ▼ (success)
DeviceState(status: connected, deviceName, macAddress)
    │
    ▼ DeviceBloc._queryDeviceInfo()
Queries MAC + model in background → updates state
```

### Auto-Reconnect

```
App Start → initDependencies()
    │
    ▼ BleDataSource.init(reconnect: true)
BleManager.init() + autoConnect()
    │
    ▼ Reads saved MAC from SharedPreferences
If found → connectDevice(savedDevice)
    │
    ▼ Connection events flow through eventStream
DeviceBloc._onSdkEvent() → connected state
```

### `BleStatusBar` Widget

The status bar appears at the top of every screen showing:

- **Connected**: Green dot + device name + MAC + battery % + "Disconnect" button
- **Disconnected**: Red dot + "Not Connected" label
- **Scanning/Connecting**: Animated pulsing dot

---

## 10. iOS Setup Guide

### Current Status

The `yc_product_plugin` SDK supports **both Android and iOS** via platform channels. The Flutter layer is fully platform-agnostic. However, iOS requires native project configuration:

### Required iOS Setup Steps

#### 1. Xcode Project Configuration

```plist
<!-- ios/Runner/Info.plist -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>HealthWare needs Bluetooth to connect to your smart ring</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>HealthWare needs Bluetooth to communicate with your smart ring</string>
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
    <string>bluetooth-peripheral</string>
</array>
```

#### 2. Add SDK Frameworks

The YC SDK provides iOS frameworks that must be embedded:

```
1. Copy the iOS SDK .framework / .xcframework files to ios/
2. In Xcode: Target → General → Frameworks → Add the SDK frameworks
3. Ensure "Embed & Sign" is set for each framework
```

#### 3. Podfile Configuration

```ruby
# ios/Podfile
platform :ios, '13.0'  # Minimum iOS version for BLE features

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
    end
  end
end
```

#### 4. Code Signing

- Requires a valid Apple Developer account
- BLE features require a **physical iOS device** (not simulator)
- Enable the "Bluetooth" background mode capability in Xcode

#### 5. Key Differences from Android

| Aspect          | Android                                | iOS                          |
| --------------- | -------------------------------------- | ---------------------------- |
| Permissions     | Runtime prompts (ACCESS_FINE_LOCATION) | Info.plist entries           |
| BLE scanning    | Requires Location permission           | Bluetooth permission only    |
| Background mode | Service-based                          | Background mode capability   |
| SDK integration | `.aar` in android/libs                 | `.framework` in ios/         |
| Auto-reconnect  | Works via SharedPreferences MAC        | Same mechanism (SDK handles) |

> **Important:** The Flutter code (`BleManager`, `BleDataSource`, all BLoCs) requires **zero changes** for iOS. Only native project configuration is needed.

---

## 11. Present / Past / Future Data Handling

### Present Data (✅ Implemented)

| Data Source               | Mechanism                                      | Refresh Rate                     |
| ------------------------- | ---------------------------------------------- | -------------------------------- |
| **Real-time stream**      | `streamRealTimeHealth()` → live\* state fields | As received (5s–5min per metric) |
| **On-demand measurement** | `startMeasurement(type)` → manual trigger      | On user action                   |
| **ECG waveform**          | `streamEcgFilteredData()` → 500-point buffer   | Continuous during measurement    |

### Past Data (⏳ Partially Implemented)

| Feature                      | Status     | Details                                             |
| ---------------------------- | ---------- | --------------------------------------------------- |
| **Device history queries**   | ✅ Working | 2-phase query on every 60s refresh cycle            |
| **Local persistence (Hive)** | ❌ Not yet | Data exists only in BLoC state; lost on app restart |
| **History charts/graphs**    | ⏳ Basic   | Detail pages show latest values; need chart widgets |
| **Data export**              | ❌ Not yet | No CSV/PDF export functionality                     |

#### Plan for Local Persistence

```
Technology: Hive (NoSQL, zero-config, fast)
Storage strategy:
  1. On each 60s refresh, persist new historical records to Hive boxes
  2. On app start, load from Hive first (instant display), then sync from device
  3. Hive box per metric type: heartRateBox, stepBox, sleepBox, etc.
  4. Deduplication by timestamp to prevent duplicates

Implementation files needed:
  - core/storage/hive_initializer.dart    — init Hive, register adapters
  - core/storage/health_data_adapter.dart — TypeAdapters for each record type
  - data/datasources/local_data_source.dart — Hive CRUD operations
  - Update HealthRepositoryImpl to read/write from local + device
```

### Future Data (❌ Not Yet Started)

| Feature                      | Priority | Description                                      |
| ---------------------------- | -------- | ------------------------------------------------ |
| **Cloud sync**               | High     | Upload health records to backend API             |
| **Trend analysis**           | Medium   | Weekly/monthly averages, trend lines             |
| **Health score**             | Medium   | Composite score from all metrics                 |
| **Notifications/Alerts**     | Medium   | HR/SpO2 threshold alerts                         |
| **Goals & targets**          | Low      | Step goals, sleep targets with progress tracking |
| **Multi-device support**     | Low      | Support connecting multiple wearables            |
| **Watch face customization** | Low      | OTA firmware updates, watch face sync            |

#### Cloud Sync Architecture (Planned)

```
┌────────────┐    ┌─────────────────┐    ┌──────────────┐
│ Hive Local │───▶│ Sync Service    │───▶│ Backend API  │
│ Storage    │    │ (background)    │    │ /health-data │
└────────────┘    │                 │    └──────────────┘
                  │ - Batch upload  │
                  │ - Conflict merge│
                  │ - Retry logic   │
                  └─────────────────┘
```

---

## 12. Key Learnings & Known Quirks

### BLE Communication Quirks

1. **CombinedData concurrent corruption**: Multiple `queryDeviceHealthData(HealthDataType.combinedData)` calls at the same time produce corrupted mixed responses. Solution: 2-phase query strategy.

2. **realTimeDataUpload never fires callback**: The native SDK processes the command but the Dart callback never receives a response, causing `TimeoutException`. Solution: Fire-and-forget with `.timeout()` and `.catchError()`.

3. **Step count discrepancy**: `HealthDataType.step` (type=0) can return stale/low counts. `HealthDataType.combinedData` (type=4) has the correct cumulative count. Solution: Compare max counts from both sources.

4. **Temperature bogus readings**: The SDK sometimes returns `0.15°C` which is clearly invalid. Solution: Filter out readings where `temperature <= 30.0`.

5. **500ms delay between BLE commands**: The BLE command queue gets blocked if commands are sent too rapidly. Always add `await Future.delayed(Duration(milliseconds: 500))` between sequential BLE commands.

### SDK Key Name Inconsistencies

The native SDK uses inconsistent key names across versions. All `fromMap()` factories handle multiple key formats:

```
Heart rate: 'heartRate' || 'value'
Steps:      'sportStep' || 'step' || 'steps' || 'value'
Calories:   'sportCalorie' || 'calories' || 'calorie'
Distance:   'sportDistance' || 'distance' || 'distanceValue'
SpO2:       'bloodOxygen' || 'value'
BP:         'systolicBloodPressure' || 'systolic'
Timestamp:  'time' || 'timestamp' || 'startTimeStamp'
```

### On-Demand Measurement Types

```dart
enum MeasurementType {
  heartRate,      // SDK type: 0x00
  bloodPressure,  // SDK type: 0x01
  bloodOxygen,    // SDK type: 0x02
  bodyTemperature,// SDK type: 0x04
  bloodGlucose    // SDK type: 0x05
}
```

Measurement results arrive via `NativeEventType.deviceHealthDataMeasureStateChange` with:

- `state: 1` = success (values present)
- `state: 0` = failure
- `state: 2` = measuring/stopped

---

## 13. Future Roadmap

### Phase 1: Data Persistence (Priority: High)

- [ ] Initialize Hive boxes for each metric type
- [ ] Create TypeAdapters for health record models
- [ ] Update `HealthRepositoryImpl` to persist data on each sync
- [ ] Load from Hive on app start (offline-first display)
- [ ] Add deduplication logic (timestamp-based)

### Phase 2: iOS Deployment (Priority: High)

- [ ] Add Info.plist Bluetooth permission entries
- [ ] Embed YC SDK iOS frameworks in Xcode project
- [ ] Configure minimum deployment target (iOS 13.0+)
- [ ] Test BLE scan + connect on physical iPhone
- [ ] Validate auto-reconnect on iOS

### Phase 3: Charts & Trend Analysis (Priority: Medium)

- [ ] Add fl_chart or syncfusion_flutter_charts dependency
- [ ] Create reusable chart widgets for each metric
- [ ] Daily/weekly/monthly view toggles
- [ ] Min/max/average overlays

### Phase 4: Cloud Sync (Priority: Medium)

- [ ] Design health data API endpoints
- [ ] Implement background sync service
- [ ] Add conflict resolution (local vs server)
- [ ] Batch upload optimization
- [ ] Retry with exponential backoff

### Phase 5: Notifications & Alerts (Priority: Low)

- [ ] HR threshold alerts (configurable high/low)
- [ ] SpO2 low-oxygen alert
- [ ] Temperature fever alert
- [ ] Local notification service implementation

### Phase 6: Advanced Features (Priority: Low)

- [ ] Multi-device support
- [ ] Watch face OTA updates
- [ ] Health score composite metric
- [ ] Data export (CSV/PDF)
- [ ] Widget for home screen quick glance

---

## Appendix A: Quick Reference — File Locations

| Component                     | File Path                                                              |
| ----------------------------- | ---------------------------------------------------------------------- |
| App entry point               | `lib/main.dart`                                                        |
| Routing                       | `lib/config/routes/app_router.dart`                                    |
| DI container                  | `lib/core/di/injection_container.dart`                                 |
| BLE Manager                   | `lib/core/ble/ble_manager.dart`                                        |
| BLE Event Handler             | `lib/core/ble/ble_event_handler.dart`                                  |
| Health Models (RT)            | `lib/core/models/health_models.dart`                                   |
| Health Entities (Domain)      | `lib/features/dashboard/domain/entities/health_data.dart`              |
| Health Repository (Interface) | `lib/features/dashboard/domain/repositories/health_repository.dart`    |
| Health Repository (Impl)      | `lib/features/dashboard/data/repositories/health_repository_impl.dart` |
| Dashboard BLoC                | `lib/features/dashboard/presentation/bloc/dashboard_bloc.dart`         |
| Dashboard State               | `lib/features/dashboard/presentation/bloc/dashboard_state.dart`        |
| Device BLoC                   | `lib/features/device/presentation/bloc/device_bloc.dart`               |
| BLE Data Source               | `lib/features/device/data/datasources/ble_data_source.dart`            |
| ECG BLoC                      | `lib/features/ecg/presentation/bloc/ecg_bloc.dart`                     |
| Theme                         | `lib/shared/theme/app_theme.dart`                                      |
| MetricCard Widget             | `lib/shared/widgets/metric_card.dart`                                  |
| BLE Status Bar                | `lib/shared/widgets/ble_status_bar.dart`                               |

## Appendix B: Dependencies

```yaml
# Key packages (from pubspec.yaml)
flutter_bloc: ^8.x # State management
go_router: ^x.x # Navigation / routing
get_it: ^7.x # Dependency injection
dartz: ^0.x # Functional programming (Either<L,R>)
equatable: ^2.x # Value equality for BLoC states
yc_product_plugin: (local) # YC Smart Ring native SDK bridge
google_fonts: ^x.x # Outfit font family
flutter_easyloading: ^3.x # Toast/loading overlay
shared_preferences: ^2.x # Auto-reconnect device persistence
```

---

_End of HealthWare Project v1 Documentation_
