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

  /// Initialize Hive and open all boxes. Call once in main().
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

  // ─── Utility ─────────────────────────────────────────────────────────

  /// Save a single real-time reading as a HeartRateRecord.
  static Future<void> saveRealtimeHeartRate(int bpm) async {
    if (bpm <= 0) return;
    final now = DateTime.now();
    await saveHeartRateRecords([
      HeartRateRecord(bpm: bpm, minBpm: bpm, maxBpm: bpm, time: now),
    ]);
  }

  /// Save a single real-time SpO2 reading.
  static Future<void> saveRealtimeSpO2(int spo2) async {
    if (spo2 <= 0) return;
    await saveBloodOxygenRecords([
      BloodOxygenRecord(spo2: spo2, time: DateTime.now()),
    ]);
  }

  /// Save a single real-time blood pressure reading.
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

  /// Save a single real-time temperature reading.
  static Future<void> saveRealtimeTemperature(double celsius) async {
    if (celsius <= 0) return;
    await saveTemperatureRecords([
      TemperatureRecord(celsius: celsius, time: DateTime.now()),
    ]);
  }

  /// Save a single real-time blood glucose reading.
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
