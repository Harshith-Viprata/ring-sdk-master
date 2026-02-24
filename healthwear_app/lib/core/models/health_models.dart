import 'package:yc_product_plugin/yc_product_plugin.dart' show DeviceFeature;

class RealTimeHeartRate {
  final int bpm;
  final DateTime timestamp;

  RealTimeHeartRate({required this.bpm, required this.timestamp});

  factory RealTimeHeartRate.fromMap(Map m) {
    final val = m['heartRate'] ?? m['value'] ?? 0;
    return RealTimeHeartRate(
      bpm: val is num ? val.toInt() : int.tryParse(val.toString()) ?? 0,
      timestamp: DateTime.now(),
    );
  }
}

class RealTimeBloodOxygen {
  final int spo2;
  final DateTime timestamp;

  RealTimeBloodOxygen({required this.spo2, required this.timestamp});

  factory RealTimeBloodOxygen.fromMap(Map m) {
    final val = m['bloodOxygen'] ?? m['value'] ?? 0;
    return RealTimeBloodOxygen(
      spo2: val is num ? val.toInt() : int.tryParse(val.toString()) ?? 0,
      timestamp: DateTime.now(),
    );
  }
}

class RealTimeBloodPressure {
  final int systolic;
  final int diastolic;
  final DateTime timestamp;

  RealTimeBloodPressure({
    required this.systolic,
    required this.diastolic,
    required this.timestamp,
  });

  factory RealTimeBloodPressure.fromMap(Map m) => RealTimeBloodPressure(
        systolic: ((m['systolicBloodPressure'] ?? m['systolic'] ?? 0) as num).toInt(),
        diastolic: ((m['diastolicBloodPressure'] ?? m['diastolic'] ?? 0) as num).toInt(),
        timestamp: DateTime.now(),
      );
}

class RealTimeTemperature {
  final double celsius;
  final DateTime timestamp;

  RealTimeTemperature({required this.celsius, required this.timestamp});

  factory RealTimeTemperature.fromMap(Map m) {
    final val = m['temperature'] ?? m['value'] ?? 0;
    return RealTimeTemperature(
      celsius: val is num ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0,
      timestamp: DateTime.now(),
    );
  }
}

class RealTimeSteps {
  final int steps;
  final int calories;
  final double distanceKm;
  final DateTime timestamp;

  RealTimeSteps({
    required this.steps,
    required this.calories,
    required this.distanceKm,
    required this.timestamp,
  });

  factory RealTimeSteps.fromMap(Map m) => RealTimeSteps(
        steps: (m['step'] ?? m['steps'] ?? 0) as int,
        calories: (m['calories'] ?? m['calorie'] ?? 0) as int,
        distanceKm:
            ((m['distance'] ?? m['distanceValue'] ?? 0) as num).toDouble(),
        timestamp: DateTime.now(),
      );
}

class RealTimePressure {
  final int stressLevel; // 0-100
  final DateTime timestamp;

  RealTimePressure({required this.stressLevel, required this.timestamp});

  factory RealTimePressure.fromMap(Map m) {
    final val = m['pressure'] ?? m['value'] ?? 0;
    return RealTimePressure(
      stressLevel: val is num ? val.toInt() : int.tryParse(val.toString()) ?? 0,
      timestamp: DateTime.now(),
    );
  }
}

class RealTimeBloodGlucose {
  final double mmolL;
  final DateTime timestamp;

  RealTimeBloodGlucose({required this.mmolL, required this.timestamp});

  factory RealTimeBloodGlucose.fromMap(Map m) {
    final val = m['bloodGlucose'] ?? m['value'] ?? 0.0;
    return RealTimeBloodGlucose(
      mmolL: val is num ? val.toDouble() : double.tryParse(val.toString()) ?? 0.0,
      timestamp: DateTime.now(),
    );
  }
}

// ─── Historical record models ──────────────────────────────────────────────

class HeartRateRecord {
  final int bpm;
  final int minBpm;
  final int maxBpm;
  final DateTime time;

  HeartRateRecord({
    required this.bpm,
    required this.minBpm,
    required this.maxBpm,
    required this.time,
  });

  factory HeartRateRecord.fromMap(Map m) => HeartRateRecord(
        bpm: ((m['heartRate'] ?? m['value'] ?? 0) as num).toInt(),
        minBpm: ((m['minHeartRate'] ?? 0) as num).toInt(),
        maxBpm: ((m['maxHeartRate'] ?? 0) as num).toInt(),
        time: DateTime.fromMillisecondsSinceEpoch(
          ((m['time'] ?? m['timestamp'] ?? m['startTimeStamp'] ?? 0) as num).toInt() * 1000,
        ),
      );
}

class StepRecord {
  final int steps;
  final int calories;
  final double distanceKm;
  final DateTime date;

  StepRecord({
    required this.steps,
    required this.calories,
    required this.distanceKm,
    required this.date,
  });

  factory StepRecord.fromMap(Map m) => StepRecord(
        steps: ((m['step'] ?? m['steps'] ?? 0) as num).toInt(),
        calories: ((m['calories'] ?? m['calorie'] ?? 0) as num).toInt(),
        distanceKm:
            ((m['distance'] ?? m['distanceValue'] ?? 0) as num).toDouble(),
        date: DateTime.fromMillisecondsSinceEpoch(
          ((m['date'] ?? m['timestamp'] ?? m['startTimeStamp'] ?? 0) as num).toInt() * 1000,
        ),
      );
}

class SleepRecord {
  final int deepMinutes;
  final int lightMinutes;
  final int remMinutes;
  final int awakeMinutes;
  final DateTime startTime;
  final DateTime endTime;

  SleepRecord({
    required this.deepMinutes,
    required this.lightMinutes,
    required this.remMinutes,
    required this.awakeMinutes,
    required this.startTime,
    required this.endTime,
  });

  int get totalMinutes => deepMinutes + lightMinutes + remMinutes;

  factory SleepRecord.fromMap(Map m) {
    int awakeSeconds = 0;
    if (m['detail'] is List) {
      for (var d in (m['detail'] as List)) {
        if (d is Map && d['sleepType'] == 0xF4) {
          awakeSeconds += (d['duration'] as int? ?? 0);
        }
      }
    }

    return SleepRecord(
      deepMinutes: ((m['deepSleepSeconds'] ?? m['deepSleepTime'] ?? 0) as int) ~/ 60,
      lightMinutes: ((m['lightSleepSeconds'] ?? m['lightSleepTime'] ?? 0) as int) ~/ 60,
      remMinutes: ((m['remSleepSeconds'] ?? m['remSleepTime'] ?? 0) as int) ~/ 60,
      awakeMinutes: awakeSeconds > 0 ? (awakeSeconds ~/ 60) : ((m['awakeTime'] ?? 0) as int),
      startTime: DateTime.fromMillisecondsSinceEpoch(
        ((m['startTimeStamp'] ?? m['startTime'] ?? 0) as int) * 1000,
      ),
      endTime: DateTime.fromMillisecondsSinceEpoch(
        ((m['endTimeStamp'] ?? m['endTime'] ?? 0) as int) * 1000,
      ),
    );
  }
}

class BloodOxygenRecord {
  final int spo2;
  final DateTime time;

  BloodOxygenRecord({required this.spo2, required this.time});

  factory BloodOxygenRecord.fromMap(Map m) => BloodOxygenRecord(
        spo2: ((m['bloodOxygen'] ?? m['value'] ?? 0) as num).toInt(),
        time: DateTime.fromMillisecondsSinceEpoch(
          ((m['time'] ?? m['timestamp'] ?? m['startTimeStamp'] ?? 0) as num).toInt() * 1000,
        ),
      );
}

class BloodPressureRecord {
  final int systolic;
  final int diastolic;
  final DateTime time;

  BloodPressureRecord({
    required this.systolic,
    required this.diastolic,
    required this.time,
  });

  factory BloodPressureRecord.fromMap(Map m) => BloodPressureRecord(
        systolic: ((m['systolicBloodPressure'] ?? m['systolic'] ?? 0) as num).toInt(),
        diastolic: ((m['diastolicBloodPressure'] ?? m['diastolic'] ?? 0) as num).toInt(),
        time: DateTime.fromMillisecondsSinceEpoch(
          ((m['time'] ?? m['timestamp'] ?? m['startTimeStamp'] ?? 0) as num).toInt() * 1000,
        ),
      );
}

class TemperatureRecord {
  final double celsius;
  final DateTime time;

  TemperatureRecord({required this.celsius, required this.time});

  factory TemperatureRecord.fromMap(Map m) => TemperatureRecord(
        celsius: ((m['temperature'] ?? m['value'] ?? 0) as num).toDouble(),
        time: DateTime.fromMillisecondsSinceEpoch(
          ((m['time'] ?? m['timestamp'] ?? m['startTimeStamp'] ?? 0) as num).toInt() * 1000,
        ),
      );
}

// ─── ECG Point for waveform rendering ─────────────────────────────────────

class ECGPoint {
  final double value;
  final double filteredValue;
  final int index;

  ECGPoint({
    required this.value,
    required this.filteredValue,
    required this.index,
  });
}

// ─── Connected Device State ────────────────────────────────────────────────

class ConnectedDeviceInfo {
  final String name;
  final String mac;
  final String? model;
  final int? firmwareVersion;
  final DeviceFeature? feature;
  final int? batteryPower;

  const ConnectedDeviceInfo({
    required this.name,
    required this.mac,
    this.model,
    this.firmwareVersion,
    this.feature,
    this.batteryPower,
  });

  ConnectedDeviceInfo copyWith({
    String? name,
    String? mac,
    String? model,
    int? firmwareVersion,
    DeviceFeature? feature,
    int? batteryPower,
  }) =>
      ConnectedDeviceInfo(
        name: name ?? this.name,
        mac: mac ?? this.mac,
        model: model ?? this.model,
        firmwareVersion: firmwareVersion ?? this.firmwareVersion,
        feature: feature ?? this.feature,
        batteryPower: batteryPower ?? this.batteryPower,
      );
}
