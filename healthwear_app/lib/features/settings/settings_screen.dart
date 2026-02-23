import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';
import '../../core/ble/ble_manager.dart';
import '../../core/providers/ble_provider.dart';
import '../device/scan_screen.dart';
import '../../shared/theme/app_theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // User profile
  int _height = 170;
  int _weight = 70;
  int _age = 30;
  DeviceUserGender _gender = DeviceUserGender.male;

  // Preferences
  int _stepGoal = 10000;
  bool _heartRateAlarm = true;
  bool _bloodOxyAlarm = true;
  bool _wristWake = true;
  bool _healthMonitoring = true;
  int _monitoringInterval = 60; // 1 hour
  DeviceDistanceUnit _distanceUnit = DeviceDistanceUnit.km;
  DeviceWeightUnit _weightUnit = DeviceWeightUnit.kg;
  DeviceTemperatureUnit _tempUnit = DeviceTemperatureUnit.celsius;
  DeviceTimeFormat _timeFormat = DeviceTimeFormat.h24;
  bool _doNotDisturb = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _height = prefs.getInt('height') ?? 170;
      _weight = prefs.getInt('weight') ?? 70;
      _age = prefs.getInt('age') ?? 30;
      _stepGoal = prefs.getInt('stepGoal') ?? 10000;
    });
  }

  Future<void> _saveUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('height', _height);
    await prefs.setInt('weight', _weight);
    await prefs.setInt('age', _age);

    EasyLoading.show(status: 'Saving...');
    final ok = await BleManager.instance.setUserInfo(
      height: _height,
      weight: _weight,
      age: _age,
      gender: _gender,
    );
    EasyLoading.dismiss();
    if (ok) {
      EasyLoading.showSuccess('User info saved!');
    } else {
      EasyLoading.showError('Failed to save — check connection');
    }
  }

  Future<void> _applyUnits() async {
    EasyLoading.show(status: 'Applying...');
    final ok = await BleManager.instance.setUnits(
      distance: _distanceUnit,
      weight: _weightUnit,
      temperature: _tempUnit,
      timeFormat: _timeFormat,
    );
    EasyLoading.dismiss();
    if (ok) EasyLoading.showSuccess('Units applied!');
  }

  Future<void> _syncTime() async {
    EasyLoading.show(status: 'Syncing time...');
    final ok = await BleManager.instance.syncPhoneTime();
    EasyLoading.dismiss();
    if (ok) EasyLoading.showSuccess('Time synced!');
  }

  Future<void> _findDevice() async {
    EasyLoading.show(status: 'Finding device...');
    await BleManager.instance.findDevice();
    EasyLoading.dismiss();
  }

  Future<void> _disconnect() async {
    EasyLoading.show(status: 'Disconnecting...');
    await BleManager.instance.disconnect();
    EasyLoading.dismiss();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(bleStateProvider) == BluetoothState.connected;
    final device = ref.watch(connectedDeviceProvider);
    final feature = device?.feature;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Device Info
                if (isConnected && device != null) ...[
                  _Card(
                    title: 'Device',
                    children: [
                      _InfoRow('Name', device.name),
                      _InfoRow('MAC', device.mac),
                      if (device.model != null) _InfoRow('Model', device.model!),
                      if (device.batteryPower != null) _InfoRow('Battery', '${device.batteryPower}%'),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _findDevice,
                            icon: const Icon(Icons.location_searching_rounded, size: 16),
                            label: const Text('Find'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(color: AppColors.accent),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _syncTime,
                            icon: const Icon(Icons.sync_rounded, size: 16),
                            label: const Text('Sync Time'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accentGreen,
                              side: const BorderSide(color: AppColors.accentGreen),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _disconnect,
                          icon: const Icon(Icons.bluetooth_disabled_rounded, size: 16),
                          label: const Text('Disconnect'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ] else ...[
                  // Not connected state
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.surfaceLight),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.bluetooth_disabled_rounded, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 16),
                        const Text('No device is connected',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        const Text('Connect your smart ring to access settings and sync data.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const ScanScreen())),
                          icon: const Icon(Icons.bluetooth_searching_rounded),
                          label: const Text('Scan for Devices'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // User Profile
                _Card(
                  title: 'User Profile',
                  children: [
                    _SliderRow(
                      label: 'Height',
                      value: _height.toDouble(),
                      unit: 'cm',
                      min: 120, max: 220,
                      onChanged: (v) => setState(() => _height = v.round()),
                    ),
                    _SliderRow(
                      label: 'Weight',
                      value: _weight.toDouble(),
                      unit: 'kg',
                      min: 30, max: 200,
                      onChanged: (v) => setState(() => _weight = v.round()),
                    ),
                    _SliderRow(
                      label: 'Age',
                      value: _age.toDouble(),
                      unit: 'yrs',
                      min: 10, max: 100,
                      onChanged: (v) => setState(() => _age = v.round()),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('Gender',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                        const Spacer(),
                        SegmentedButton<DeviceUserGender>(
                          style: SegmentedButton.styleFrom(
                            backgroundColor: AppColors.surfaceLight,
                            selectedBackgroundColor: AppColors.accent,
                            selectedForegroundColor: AppColors.background,
                            foregroundColor: AppColors.textSecondary,
                          ),
                          segments: const [
                            ButtonSegment(value: DeviceUserGender.male, label: Text('Male')),
                            ButtonSegment(value: DeviceUserGender.female, label: Text('Female')),
                          ],
                          selected: {_gender},
                          onSelectionChanged: (s) => setState(() => _gender = s.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: isConnected ? _saveUserInfo : null,
                      child: const Text('Save User Info'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Activity Goal
                _Card(
                  title: 'Activity Goals',
                  children: [
                    _SliderRow(
                      label: 'Daily Steps Goal',
                      value: _stepGoal.toDouble(),
                      unit: 'steps',
                      min: 1000, max: 30000,
                      divisions: 58,
                      onChanged: (v) => setState(() => _stepGoal = (v / 1000).round() * 1000),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: isConnected
                          ? () async {
                              EasyLoading.show(status: 'Saving...');
                              await BleManager.instance.setStepGoal(_stepGoal);
                              EasyLoading.dismiss();
                              EasyLoading.showSuccess('Step goal saved!');
                            }
                          : null,
                      child: const Text('Save Goal'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Health Monitoring
                _Card(
                  title: 'Health Monitoring',
                  children: [
                    _SwitchRow(
                      label: 'Auto Monitoring (1 Hr)',
                      value: _healthMonitoring,
                      onChanged: (v) async {
                        setState(() => _healthMonitoring = v);
                        await BleManager.instance.setHealthMonitoring(
                          enable: v,
                          intervalMinutes: _monitoringInterval,
                        );
                      },
                    ),
                    _SwitchRow(
                      label: 'Heart Rate Alarm',
                      value: _heartRateAlarm,
                      onChanged: (v) async {
                        setState(() => _heartRateAlarm = v);
                        await BleManager.instance.setHeartRateAlarm(enable: v);
                      },
                    ),
                    _SwitchRow(
                      label: 'Blood Oxygen Alarm',
                      value: _bloodOxyAlarm,
                      onChanged: (v) async {
                        setState(() => _bloodOxyAlarm = v);
                        await BleManager.instance.setBloodOxygenAlarm(enable: v);
                      },
                    ),
                    _SwitchRow(
                      label: 'Wrist Wake Screen',
                      value: _wristWake,
                      onChanged: (v) async {
                        setState(() => _wristWake = v);
                        await BleManager.instance.setWristWake(v);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Units
                _Card(
                  title: 'Units & Display',
                  children: [
                    _DropdownRow<DeviceDistanceUnit>(
                      label: 'Distance',
                      value: _distanceUnit,
                      items: const [
                        DropdownMenuItem(value: DeviceDistanceUnit.km, child: Text('Kilometers')),
                        DropdownMenuItem(value: DeviceDistanceUnit.mile, child: Text('Miles')),
                      ],
                      onChanged: (v) => setState(() => _distanceUnit = v!),
                    ),
                    _DropdownRow<DeviceWeightUnit>(
                      label: 'Weight',
                      value: _weightUnit,
                      items: const [
                        DropdownMenuItem(value: DeviceWeightUnit.kg, child: Text('Kilograms')),
                        DropdownMenuItem(value: DeviceWeightUnit.lb, child: Text('Pounds')),
                      ],
                      onChanged: (v) => setState(() => _weightUnit = v!),
                    ),
                    _DropdownRow<DeviceTemperatureUnit>(
                      label: 'Temperature',
                      value: _tempUnit,
                      items: const [
                        DropdownMenuItem(value: DeviceTemperatureUnit.celsius, child: Text('Celsius (°C)')),
                        DropdownMenuItem(value: DeviceTemperatureUnit.fahrenheit, child: Text('Fahrenheit (°F)')),
                      ],
                      onChanged: (v) => setState(() => _tempUnit = v!),
                    ),
                    _DropdownRow<DeviceTimeFormat>(
                      label: 'Time Format',
                      value: _timeFormat,
                      items: const [
                        DropdownMenuItem(value: DeviceTimeFormat.h24, child: Text('24h')),
                        DropdownMenuItem(value: DeviceTimeFormat.h12, child: Text('12h')),
                      ],
                      onChanged: (v) => setState(() => _timeFormat = v!),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: isConnected ? _applyUnits : null,
                      child: const Text('Apply Units'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Setting widgets ─────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1)),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const Spacer(),
            Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _SwitchRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const Spacer(),
            Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.accent,
            ),
          ],
        ),
      );
}

class _SliderRow extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13)),
              const Spacer(),
              Text(
                '${value.round()} $unit',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.accent,
              inactiveTrackColor: AppColors.surfaceLight,
              thumbColor: AppColors.accent,
              overlayColor: AppColors.accent.withOpacity(0.15),
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
              min: min, max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      );
}

class _DropdownRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const Spacer(),
            DropdownButton<T>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: AppColors.surface,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 14),
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.expand_more_rounded,
                  color: AppColors.textSecondary),
            ),
          ],
        ),
      );
}
