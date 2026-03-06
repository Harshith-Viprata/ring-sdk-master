# HealthWear App — Complete Project Documentation

> **Version:** 1.0.0+1  
> **Framework:** Flutter (Dart ≥ 3.1.0)  
> **Generated:** 2026-03-06

---

## Table of Contents

1. [Project Overview](#1-project-overview)
2. [Architecture Design](#2-architecture-design)
3. [Local Plugin Integration — `yc_product_plugin`](#3-local-plugin-integration--yc_product_plugin)
4. [App Structure & Navigation — Screen Inventory](#4-app-structure--navigation--screen-inventory)
5. [Functionality Matrix](#5-functionality-matrix)
6. [Setup & Installation Guide](#6-setup--installation-guide)

---

## 1. Project Overview

**HealthWear** is a Flutter-based companion application designed to connect with **YC-series smart rings and wearable watches** over Bluetooth Low Energy (BLE). The app provides users with real-time biometric monitoring, historical health data visualization, on-demand measurement triggers, and full device settings management.

### Core Technologies

| Layer                | Technology                                                              |
| -------------------- | ----------------------------------------------------------------------- |
| **Framework**        | Flutter (Material 3, Dart ≥ 3.1)                                        |
| **State Management** | `flutter_riverpod` ^2.5.1 — `StateProvider` + `FutureProvider`          |
| **Local Storage**    | `hive` ^2.2.3 / `hive_flutter` ^1.1.0 — lightweight NoSQL boxes         |
| **BLE Bridge**       | `yc_product_plugin` (local plugin) — MethodChannel→ native YC SDK       |
| **Charting**         | `fl_chart` ^0.67.0 — Line, Bar, and Pie charts                          |
| **UI/UX**            | Google Fonts (`Outfit`), `flutter_easyloading`, `lottie`, glassmorphism |
| **Permissions**      | `permission_handler` ^11.3.1, `device_info_plus` ^10.1.0                |
| **Preferences**      | `shared_preferences` ^2.2.3 — user profile, auto-reconnect MAC storage  |
| **Utilities**        | `intl` ^0.19.0 (date formatting), `path_provider` ^2.1.2                |

### Supported Health Metrics

Heart Rate · Blood Oxygen (SpO₂) · Blood Pressure · Body Temperature · Steps & Calories · Sleep Stages · ECG Waveform · Stress Level · Blood Glucose

---

## 2. Architecture Design

The app follows a **feature-first, layered architecture** with three primary layers: **Core**, **Features**, and **Shared**.

### High-Level Data Flow

```
┌──────────────────────────────────────────────────────────────────┐
│  HARDWARE (YC Smart Ring / Watch)                                │
│       ↕ BLE (Bluetooth Low Energy)                               │
├──────────────────────────────────────────────────────────────────┤
│  yc_product_plugin (MethodChannel → Native Android/iOS SDK)      │
│       ↕ onListening() event stream + async method calls          │
├──────────────────────────────────────────────────────────────────┤
│  CORE LAYER                                                      │
│  ┌─────────────┐   ┌──────────────────┐   ┌──────────────────┐  │
│  │ BleManager   │──→│ BleEventHandler  │──→│ Riverpod         │  │
│  │ (Singleton)  │   │ (Event Mapper)   │   │ StateProviders   │  │
│  └─────────────┘   └──────────────────┘   └──────────────────┘  │
│       ↑                                          ↕               │
│  health_models.dart ←────── FutureProviders (history queries)    │
├──────────────────────────────────────────────────────────────────┤
│  FEATURE SCREENS (ConsumerStatefulWidget / ConsumerWidget)       │
│  ref.watch(provider) → reactive UI rebuild                       │
├──────────────────────────────────────────────────────────────────┤
│  SHARED LAYER                                                    │
│  AppTheme · MetricCard · BleStatusBar                            │
└──────────────────────────────────────────────────────────────────┘
```

### Layer Breakdown

#### 2.1 Core Layer (`lib/core/`)

| File / Directory              | Responsibility                                                                                                                                                                                                                                                                                                                                                                                                                       |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `ble/ble_manager.dart`        | **Singleton** wrapping `YcProductPlugin`. Provides all BLE operations: `init()`, `scan()`, `connect()`, `disconnect()`, real-time data upload, on-demand measurement start/stop, ECG control, device settings, OTA, and auto-reconnect via `SharedPreferences`.                                                                                                                                                                      |
| `ble/ble_event_handler.dart`  | **Singleton** event mapper. Receives raw `Map` events from `BleManager.onEvent()` and dispatches typed callbacks (`onHeartRate`, `onBloodOxygen`, `onECGFilteredData`, etc.) using `NativeEventType` constants. Also exposes a `ValueNotifier<int?>` for heart rate so widgets outside Riverpod can react.                                                                                                                           |
| `models/health_models.dart`   | Dart model classes for **real-time data** (`RealTimeHeartRate`, `RealTimeBloodOxygen`, `RealTimeBloodPressure`, `RealTimeTemperature`, `RealTimeSteps`, `RealTimePressure`, `RealTimeBloodGlucose`, `ECGPoint`) and **historical records** (`HeartRateRecord`, `StepRecord`, `SleepRecord`, `BloodOxygenRecord`, `BloodPressureRecord`, `TemperatureRecord`). All include `fromMap()` factories with resilient key-fallback parsing. |
| `providers/ble_provider.dart` | Central Riverpod provider definitions. `StateProvider`s for live BLE state, connected device info, and all real-time metrics. `FutureProvider`s for historical queries (heart rate, steps, sleep, blood oxygen, blood pressure, temperature). Also contains `initBleEventWiring()` which wires `BleEventHandler` callbacks → Riverpod state.                                                                                         |

#### 2.2 Feature Layer (`lib/features/`)

Each feature resides in its own directory containing a single screen widget file. Screens use `ConsumerStatefulWidget` or `ConsumerWidget` and access providers via `ref.watch()` / `ref.read()`.

#### 2.3 Shared Layer (`lib/shared/`)

| File                          | Responsibility                                                                                                                                                                                                                                    |
| ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `theme/app_theme.dart`        | Dark-only `ThemeData` using Material 3 and **Google Fonts Outfit**. Defines `AppColors` (background, surface, accent palette, per-metric colours) and `AppTheme.dark` with custom styling for AppBar, cards, buttons, inputs, and navigation bar. |
| `widgets/metric_card.dart`    | Reusable `MetricCard` — glassmorphism card with `BackdropFilter`, gradient background, icon, value, unit text, optional tap handler, and loading shimmer state. Also includes `StatusBadge` pill widget.                                          |
| `widgets/ble_status_bar.dart` | `BleStatusBar` — animated top banner showing BLE connection status (green = connected, red = disconnected) with device name, MAC, pulsing icon, and inline disconnect button.                                                                     |

### State Management Strategy (Riverpod)

```
┌── StateProviders (synchronous, push-updated) ──┐
│  bleStateProvider          → int               │
│  connectedDeviceProvider   → ConnectedDeviceInfo│
│  heartRateProvider         → RealTimeHeartRate  │
│  bloodOxygenProvider       → RealTimeBloodOxygen│
│  bloodPressureProvider     → RealTimeBloodPressure│
│  temperatureProvider       → RealTimeTemperature│
│  stepsProvider             → RealTimeSteps      │
│  pressureProvider          → RealTimePressure   │
│  bloodGlucoseProvider      → RealTimeBloodGlucose│
│  ecgPointsProvider         → List<ECGPoint>     │
│  isECGActiveProvider       → bool               │
│  scannedDevicesProvider    → List<BluetoothDevice>│
│  isScanningProvider        → bool               │
│  isConnectingProvider      → bool               │
└─────────────────────────────────────────────────┘

┌── FutureProviders (async, pull-fetched from ring)──┐
│  heartRateHistoryProvider     → List<HeartRateRecord>    │
│  stepHistoryProvider          → List<StepRecord>         │
│  sleepHistoryProvider         → List<SleepRecord>        │
│  bloodOxygenHistoryProvider   → List<BloodOxygenRecord>  │
│  bloodPressureHistoryProvider → List<BloodPressureRecord>│
│  temperatureHistoryProvider   → List<TemperatureRecord>  │
└──────────────────────────────────────────────────────────┘
```

### Data Pipeline — Real-Time Measurement

```
Ring Sensor → native SDK → MethodChannel → YcProductPlugin.onListening()
  → BleManager.onEvent(handler)
    → BleEventHandler.handleEvent(Map event)
      → typed callback  (e.g. onHeartRate(RealTimeHeartRate))
        → ref.read(heartRateProvider.notifier).state = data
          → all UI widgets watching heartRateProvider rebuild
```

---

## 3. Local Plugin Integration — `yc_product_plugin`

### 3.1 Directory Structure

```
healthwear_app/
├── yc_product_plugin/           ← Local Flutter plugin (path dependency)
│   ├── android/                 ← Native Android implementation (Java/Kotlin, YC SDK .jars)
│   ├── ios/                     ← Native iOS implementation (Swift/ObjC, YC SDK .frameworks)
│   ├── lib/
│   │   ├── yc_product_plugin.dart                    ← Public API facade
│   │   ├── yc_product_plugin_data_type.dart           ← Data type constants & enums
│   │   ├── yc_product_plugin_method_channel.dart      ← MethodChannel implementation
│   │   ├── yc_product_plugin_platform_interface.dart   ← Platform interface (abstract)
│   │   └── yc_product_plugin_tools.dart               ← Utility helpers
│   ├── pubspec.yaml             ← Plugin metadata (platforms: android, ios)
│   └── example/                 ← Standalone example app
```

### 3.2 pubspec.yaml Configuration

In the host app's `pubspec.yaml`, the plugin is declared as a **path dependency**:

```yaml
dependencies:
  # === LOCAL BLE PLUGIN (yc_product_plugin) — bundled inside app ===
  yc_product_plugin:
    path: yc_product_plugin/
```

The plugin's own `pubspec.yaml` declares platform class registrations:

```yaml
flutter:
  plugin:
    platforms:
      android:
        package: com.example.yc_product_plugin
        pluginClass: YcProductPlugin
      ios:
        pluginClass: YcProductPlugin
```

### 3.3 Primary Responsibilities

| Category                       | APIs Exposed                                                                                                                                            |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Initialization**             | `initPlugin(isReconnectEnable, isLogEnable)`                                                                                                            |
| **BLE Scanning**               | `scanDevice(time)`, `stopScanDevice()`                                                                                                                  |
| **Connection**                 | `connectDevice(device)`, `disconnectDevice()`, `resetBond()`                                                                                            |
| **Event Stream**               | `onListening(callback)`, `cancelListening()` — real-time native event broadcasts                                                                        |
| **Bluetooth State**            | `getBluetoothState()`                                                                                                                                   |
| **Device Info**                | `getDeviceFeature()`, `queryDeviceBasicInfo()`, `queryDeviceMacAddress()`, `queryDeviceModel()`, `queryDeviceMCU()`                                     |
| **Real-time Streaming**        | `realTimeDataUpload(enable, dataType)` — enables continuous push of combined health data                                                                |
| **Historical Data**            | `queryDeviceHealthData(type)`, `deleteDeviceHealthData(type)`                                                                                           |
| **App-Controlled Measurement** | `appControlMeasureHealthData(start, type)` — triggers on-demand HR, BP, SpO₂, Temp, Glucose                                                             |
| **ECG**                        | `startECGMeasurement()`, `stopECGMeasurement()`, `getECGResult()`                                                                                       |
| **Device Settings**            | User info, heart rate alarm, SpO₂ alarm, units, DND, health monitoring mode, temperature monitoring, step goal, wrist wake, wearing position, info push |
| **OTA Firmware**               | `deviceUpgrade(platform, firmwarePath, callback)`                                                                                                       |

### 3.4 Key Data Type Constants

| Constant Class                          | Important Values                                                                                                                                                                                                                                                                                                                |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `BluetoothState`                        | `.off`, `.connected`, `.disconnected`, `.connectFailed`                                                                                                                                                                                                                                                                         |
| `NativeEventType`                       | `.bluetoothStateChange`, `.deviceInfo`, `.deviceRealHeartRate`, `.deviceRealBloodOxygen`, `.deviceRealBloodPressure`, `.deviceRealTemperature`, `.deviceRealStep`, `.deviceRealPressure`, `.deviceRealBloodGlucose`, `.deviceRealECGData`, `.deviceRealECGFilteredData`, `.deviceEndECG`, `.deviceHealthDataMeasureStateChange` |
| `HealthDataType`                        | `.heartRate`, `.bloodPressure`, `.bloodOxygen`, `.step`, `.sleep`, `.combinedData`                                                                                                                                                                                                                                              |
| `DeviceRealTimeDataType`                | `.combinedData` (streams all metrics in one channel)                                                                                                                                                                                                                                                                            |
| `DeviceAppControlMeasureHealthDataType` | `.heartRate`, `.bloodPressure`, `.bloodOxygen`, `.bodyTemperature`, `.bloodGlucose`                                                                                                                                                                                                                                             |
| `DeviceFeature`                         | Boolean capability flags: `isSupportHeartRate`, `isSupportBloodOxygen`, `isSupportBloodPressure`, `isSupportTemperature`, `isSupportStep`, `isSupportSleep`, `isSupportRealTimeECG`, `isSupportPressure`, `isSupportBloodGlucose`                                                                                               |

---

## 4. App Structure & Navigation — Screen Inventory

### 4.1 Directory Map

```
lib/
├── main.dart                                    ← App entry, BLE init, ProviderScope
├── core/
│   ├── ble/
│   │   ├── ble_manager.dart                     ← Singleton BLE facade
│   │   └── ble_event_handler.dart               ← Native → typed event mapper
│   ├── models/
│   │   └── health_models.dart                   ← Data models (real-time + history)
│   └── providers/
│       └── ble_provider.dart                    ← Riverpod provider definitions
├── features/
│   ├── dashboard/
│   │   └── dashboard_screen.dart                ← Main hub screen
│   ├── device/
│   │   └── scan_screen.dart                     ← BLE device scan + connect
│   ├── heart_rate/
│   │   └── heart_rate_screen.dart               ← HR detail + measurement
│   ├── ecg/
│   │   └── ecg_screen.dart                      ← ECG waveform recording
│   ├── activity/
│   │   └── activity_screen.dart                 ← Steps + activity tracking
│   ├── sleep/
│   │   └── sleep_screen.dart                    ← Sleep analysis
│   ├── health_metrics/
│   │   └── metrics_screen.dart                  ← SpO₂, BP, Temp, Glucose, Stress
│   └── settings/
│       └── settings_screen.dart                 ← Device + user settings
└── shared/
    ├── theme/
    │   └── app_theme.dart                       ← Dark theme + colour tokens
    └── widgets/
        ├── metric_card.dart                     ← Glassmorphism metric card
        └── ble_status_bar.dart                  ← Connection status banner
```

### 4.2 Screen Details & Navigation Flow

```
              ┌────────────┐
              │ main.dart  │
              │ (App Init) │
              └──────┬─────┘
                     │ home:
           ┌─────────▼──────────┐
           │  DashboardScreen   │  ← BottomNavigationBar (4 tabs)
           │  (Tab 0: _HomeTab) │
           └─────┬──────────────┘
 ┌───────────────┼───────────────────────────────┐
 │ Tab 0         │ Tab 1          Tab 2           Tab 3
 │ _HomeTab      │ ActivityScreen SleepScreen     SettingsScreen
 │               │
 │ push →        │
 │ ┌─────────────▼───────────────────────────────┐
 │ │ Quick Actions: ECG │ Metrics │ Sleep        │
 │ │ Metric Cards → detail screens               │
 │ └───┬─────────┬──────┬───────────────────────-┘
 │     │         │      │
 │     ▼         ▼      ▼
 │ EcgScreen MetricsScreen SleepScreen
 │
 ▼
ScanScreen (BLE pairing — pushed from AppBar icon or "Connect" button)
HeartRateScreen (pushed from HR MetricCard tap)
```

### 4.3 Screen Descriptions

| #   | Screen              | File                     | Purpose                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     |
| --- | ------------------- | ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | **DashboardScreen** | `dashboard_screen.dart`  | Main hub. Houses a `BottomNavigationBar` with 4 tabs (Home, Activity, Sleep, Settings). The Home tab displays a `BleStatusBar`, greeting, quick action buttons (ECG, Metrics, Sleep), a dynamic 2-column grid of `MetricCard` widgets showing real-time data from the ring (HR, Steps, SpO₂, BP, Glucose, Temp, Stress), and an ECG banner. Metric cards are conditionally rendered based on `DeviceFeature` capability flags. Shows a "Not Connected" card with scan CTA when no device is paired.                                                                                                         |
| 2   | **ScanScreen**      | `scan_screen.dart`       | BLE device discovery. Requests `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` (Android 12+) or location (older Android) permissions. Triggers a 6-second scan via `BleManager.scan()`, displays results sorted by RSSI with signal strength bars, and connects on tap. On successful connection, fetches device feature capabilities, MAC, model, and battery info, stores in `connectedDeviceProvider`, and pops back to Dashboard.                                                                                                                                                                                |
| 3   | **HeartRateScreen** | `heart_rate_screen.dart` | Detailed heart rate view. Displays a `LineChart` of historical HR data (24h timeline), a large live BPM readout via `ValueListenableBuilder`, highest/lowest stats, an on-demand "Heart rate measurement" button (45s timed cycle that pauses background telemetry), an analysis card, a settings card, and a scrollable history record list (last 5 entries with timestamps). Day/Week/Month tab selector (UI present, filtering wired to Day by default).                                                                                                                                                 |
| 4   | **EcgScreen**       | `ecg_screen.dart`        | Real-time ECG waveform capture. Shows a dark ECG monitor area with a `LineChart` rendering up to 500 filtered ECG data points. Start/Stop button triggers `BleManager.startECG()` / `stopECG()`. A 30-second countdown timer shows progress. After completion, calls `getECGResult()` and displays a result dialog with: Heart Rate (BPM), HRV Norm, Respiratory Rate, QRS Diagnosis (Normal/Arrhythmia/Tachycardia/Bradycardia/ST Elevation), and Atrial Fibrillation flag.                                                                                                                                |
| 5   | **ActivityScreen**  | `activity_screen.dart`   | Step tracking and activity overview. Shows a circular step-progress ring (current steps vs 10,000 goal), calorie count, distance in km, goal percentage, and a weekly bar chart (`BarChart`) of the last 7 days' step history. Data sourced from `stepsProvider` (real-time) and `stepHistoryProvider` (historical).                                                                                                                                                                                                                                                                                        |
| 6   | **SleepScreen**     | `sleep_screen.dart`      | Sleep analysis dashboard. Displays a sleep summary card (total duration, start→end times), a `PieChart` of sleep stages (Deep, Light, REM, Awake), a colour-coded legend with durations, and a history list (up to 7 past nights). Empty state with "Wear your device to bed" message.                                                                                                                                                                                                                                                                                                                      |
| 7   | **MetricsScreen**   | `metrics_screen.dart`    | Consolidated health metrics hub. Sections for **Blood Oxygen**, **Blood Pressure**, **Body Temperature**, **Blood Glucose**, and **Stress Level**. Each section has a `_MetricDetailCard` showing current value, a "Measure" button (45s timed on-demand measurement cycle with progress indicator), and up to 5 recent history entries. Stress is display-only via `MetricCard`.                                                                                                                                                                                                                           |
| 8   | **SettingsScreen**  | `settings_screen.dart`   | Device and user configuration. **Device card:** name, MAC, model, battery, Find Device, Sync Time, Disconnect buttons. **User Profile card:** height/weight/age sliders, gender selector, Save button → `BleManager.setUserInfo()`. **Activity Goals card:** step goal slider + Save. **Health Monitoring card:** toggle switches for Auto Monitoring (hourly), Heart Rate Alarm, Blood Oxygen Alarm, Wrist Wake. **Units card:** dropdowns for Distance (km/mile), Weight (kg/lb), Temperature (°C/°F), Time (24h/12h) + Apply button. All settings persisted to `SharedPreferences` and synced to device. |

---

## 5. Functionality Matrix

### ✅ Working Functionality

| Feature                                    | Description                                                              | Status    |
| ------------------------------------------ | ------------------------------------------------------------------------ | --------- |
| **BLE Device Scanning**                    | 6-second scan with RSSI-sorted results, signal strength visualization    | ✅ Stable |
| **BLE Connection**                         | Connect to YC ring/watch, auto-fetch `DeviceFeature` capabilities        | ✅ Stable |
| **Auto-Reconnect**                         | Saves MAC to `SharedPreferences`, reconnects on app restart              | ✅ Stable |
| **Real-Time Heart Rate**                   | Live BPM via `NativeEventType.deviceRealHeartRate` + `ValueNotifier`     | ✅ Stable |
| **Real-Time Blood Oxygen**                 | Live SpO₂ percentage via event stream                                    | ✅ Stable |
| **Real-Time Blood Pressure**               | Live systolic/diastolic via event stream                                 | ✅ Stable |
| **Real-Time Temperature**                  | Live body temp (°C) via event stream                                     | ✅ Stable |
| **Real-Time Steps**                        | Live step count, calories, distance via event stream                     | ✅ Stable |
| **Real-Time Stress**                       | Live stress index (0–100) via event stream                               | ✅ Stable |
| **Real-Time Blood Glucose**                | Live glucose (mmol/L) via event stream                                   | ✅ Stable |
| **Historical Data Sync**                   | Fetch HR, step, sleep, SpO₂, BP, and temperature history from ring       | ✅ Stable |
| **ECG Recording**                          | 30-second real-time ECG waveform capture with live chart rendering       | ✅ Stable |
| **ECG Result Analysis**                    | Post-recording result: HR, HRV, respiratory rate, QRS diagnosis, AF flag | ✅ Stable |
| **On-Demand Measurement — Heart Rate**     | App-triggered 45s HR measurement cycle with progress UI                  | ✅ Stable |
| **On-Demand Measurement — SpO₂**           | App-triggered SpO₂ measurement with progress indicator                   | ✅ Stable |
| **On-Demand Measurement — Blood Pressure** | App-triggered BP measurement with progress indicator                     | ✅ Stable |
| **On-Demand Measurement — Temperature**    | App-triggered temperature measurement with progress indicator            | ✅ Stable |
| **On-Demand Measurement — Blood Glucose**  | App-triggered glucose measurement with progress indicator                | ✅ Stable |
| **Dashboard Metric Grid**                  | Dynamic grid showing only device-supported metrics via `DeviceFeature`   | ✅ Stable |
| **Activity Tracking**                      | Circular progress ring + weekly bar chart for steps                      | ✅ Stable |
| **Sleep Analysis**                         | Pie chart (Deep/Light/REM/Awake), summary card, 7-night history          | ✅ Stable |
| **Device Settings Sync**                   | User profile, step goal, heart rate alarm, SpO₂ alarm, wrist wake        | ✅ Stable |
| **Unit Configuration**                     | Distance, weight, temperature, time format — synced to device            | ✅ Stable |
| **Find Device**                            | Ring buzzer/vibrate via `BleManager.findDevice()`                        | ✅ Stable |
| **Phone Time Sync**                        | Sync phone clock to ring via `BleManager.syncPhoneTime()`                | ✅ Stable |
| **Disconnect**                             | Clean disconnect + clear saved MAC                                       | ✅ Stable |
| **Permission Handling**                    | Android 12+ `BLUETOOTH_SCAN`/`BLUETOOTH_CONNECT`, older: location        | ✅ Stable |
| **Dark Theme**                             | Full Material 3 dark theme with Outfit font, custom colour tokens        | ✅ Stable |
| **BLE Status Bar**                         | Animated top banner showing connection state, pulsing icon               | ✅ Stable |
| **Riverpod State Updates**                 | All `StateProvider` ↔ `BleEventHandler` wiring functional                | ✅ Stable |

### ⚠️ Pending / Not Working Functionality

| Feature                         | Description                                                                                                                                                                                                                                          | Status             |
| ------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------ |
| **Hive Local Persistence**      | Hive is declared as a dependency but **not currently initialized** in `main.dart`. No Hive boxes are opened or used for caching health data locally. All historical data is fetched fresh from the ring each time.                                   | 🔴 Not Implemented |
| **Blood Glucose History**       | `bloodGlucoseHistoryProvider` does not exist. The `MetricsScreen` uses a hardcoded `AsyncValue.loading()` placeholder for glucose history.                                                                                                           | 🔴 Not Implemented |
| **Sleep Data Sync Gaps**        | Real-time sleep data has been reported as available on the watch but may not always sync to the app. Sleep records depend on `HealthDataType.sleep` queries which can return empty if the ring has not completed a sleep cycle.                      | 🟡 Intermittent    |
| **Data Sync Dropping**          | Ring data synchronization can intermittently drop during long sessions, especially when the app background-state conflicts with BLE keepalive. The `_refreshTimer` on DashboardScreen (60s periodic) attempts to mitigate this.                      | 🟡 Known Issue     |
| **ECG Disconnect on No Signal** | The ECG measurement may disconnect or abort early when proper electrode contact is lost (no finger on sensor), rather than showing a "place finger" guidance message.                                                                                | 🟡 Known Issue     |
| **Battery Display**             | `ConnectedDeviceInfo.batteryPower` is fetched from `DeviceBasicInfo` at connection time but is **static** — it does not update in real-time and may show outdated values. Previously showed 0% due to reading wrong field (fixed to `batteryPower`). | 🟡 Partial         |
| **Heart Rate Week/Month Tabs**  | Tab selector (Day/Week/Month) on `HeartRateScreen` is rendered but only "Day" view actually filters data. Week and Month views show the same unfiltered dataset.                                                                                     | 🟡 UI Only         |
| **Health Settings Navigation**  | "Health settings" card on `HeartRateScreen` has no `onTap` action.                                                                                                                                                                                   | 🔴 Not Implemented |
| **Share Button**                | Share icon on `HeartRateScreen` header has an empty `onPressed: () {}`.                                                                                                                                                                              | 🔴 Not Implemented |
| **OTA Firmware Update**         | `BleManager.startOTA()` method exists but no UI screen is implemented for firmware upgrades.                                                                                                                                                         | 🔴 Not Implemented |
| **Do Not Disturb Mode**         | `setDoNotDisturb()` API exists in `BleManager` but no UI toggle is present in Settings.                                                                                                                                                              | 🔴 Not Implemented |
| **Wearing Position**            | `setWearingPosition()` API exists but no UI is implemented.                                                                                                                                                                                          | 🔴 Not Implemented |
| **Info Push (Notifications)**   | `setInfoPush()` API exists but no UI is implemented for configuring phone notification forwarding.                                                                                                                                                   | 🔴 Not Implemented |
| **Offline Data Caching**        | Without Hive initialization, the app cannot display data when the ring is disconnected. Opening the dashboard offline shows only "--" values.                                                                                                        | 🔴 Not Implemented |
| **iOS Testing**                 | Plugin declares iOS support but current development and testing focus is Android. iOS BLE behavior may differ.                                                                                                                                       | 🟡 Untested        |

---

## 6. Setup & Installation Guide

### Prerequisites

| Tool                        | Version              | Notes                                                           |
| --------------------------- | -------------------- | --------------------------------------------------------------- |
| **Flutter SDK**             | ≥ 3.1.0              | [Install Flutter](https://docs.flutter.dev/get-started/install) |
| **Dart SDK**                | ≥ 3.1.0              | Bundled with Flutter                                            |
| **Android Studio**          | Latest               | For Android emulator and SDK tools                              |
| **Xcode**                   | Latest (macOS only)  | For iOS builds                                                  |
| **Git**                     | Any                  | Source control                                                  |
| **Physical Android Device** | Android 8+ (API 26+) | BLE required — emulators won't work                             |

### Step 1 — Clone the Repository

```bash
git clone <repo-url>
cd ring-sdk-master/healthwear_app
```

### Step 2 — Install Dependencies

The `yc_product_plugin` is a local path dependency and will resolve automatically:

```bash
flutter pub get
```

> **Note:** If you see errors about the plugin, verify that `yc_product_plugin/` exists at the project root and contains a valid `pubspec.yaml`.

### Step 3 — Generate Hive Type Adapters (if needed)

The project includes `hive_generator` and `build_runner` as dev dependencies. Run code generation if Hive models are added:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 4 — Android Configuration

The native YC SDK `.jar` / `.aar` files are bundled inside `yc_product_plugin/android/`. Verify:

1. **Minimum SDK** — Ensure `android/app/build.gradle` has `minSdkVersion 21` or higher.
2. **Permissions** — The following permissions should already be declared in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

3. **ProGuard** — If using minification, add keep rules for the YC SDK classes.

### Step 5 — iOS Configuration (macOS only)

1. **Info.plist** — Add Bluetooth usage descriptions:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>HealthWear needs Bluetooth to connect to your smart ring.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>HealthWear needs Bluetooth to connect to your smart ring.</string>
```

2. **Podfile** — Run `pod install` inside `ios/`:

```bash
cd ios && pod install && cd ..
```

### Step 6 — Run the App

Connect a **physical Android device** with Bluetooth enabled and a YC-compatible ring nearby:

```bash
flutter run
```

For debug logging with verbose BLE output:

```bash
flutter run --verbose
```

### Step 7 — Build for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

---

### Project Quick Reference

| Item                 | Value                                                    |
| -------------------- | -------------------------------------------------------- |
| **Package Name**     | `healthwear_app`                                         |
| **App Title**        | HealthWear                                               |
| **Entry Point**      | `lib/main.dart`                                          |
| **Home Screen**      | `DashboardScreen`                                        |
| **Theme**            | Dark only (Material 3, `AppTheme.dark`)                  |
| **Font**             | Google Fonts — Outfit                                    |
| **BLE Plugin**       | `yc_product_plugin/` (path dependency)                   |
| **State Management** | `flutter_riverpod` ^2.5.1                                |
| **Local DB**         | `hive` ^2.2.3 (dependency declared, not yet initialized) |
| **Min Dart SDK**     | ≥ 3.1.0                                                  |
| **Target Platforms** | Android (primary), iOS (declared, untested)              |

---

_Generated by Antigravity AI — 2026-03-06_
