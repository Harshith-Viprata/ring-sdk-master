import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yc_product_plugin/yc_product_plugin.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../device/data/datasources/ble_data_source.dart';
import '../../../device/presentation/bloc/device_bloc.dart';
import '../../../../core/di/injection_container.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // User profile
  double _height = 170;
  double _weight = 70;
  int _age = 25;
  int _gender = 0; // 0=male, 1=female

  // Step goal
  double _stepGoal = 10000;

  // Health monitoring
  bool _autoMonitoring = true;
  bool _hrAlarm = false;
  bool _spo2Alarm = false;
  bool _wristWake = true;

  // Units
  int _distance = 0; // 0=km, 1=mile
  int _weight_unit = 0; // 0=kg, 1=lb
  int _tempUnit = 0; // 0=°C, 1=°F
  int _timeFormat = 0; // 0=24h, 1=12h

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _height = prefs.getDouble('userHeight') ?? 170;
      _weight = prefs.getDouble('userWeight') ?? 70;
      _age = prefs.getInt('userAge') ?? 25;
      _gender = prefs.getInt('userGender') ?? 0;
      _stepGoal = prefs.getDouble('stepGoal') ?? 10000;
      _autoMonitoring = prefs.getBool('autoMonitoring') ?? true;
      _hrAlarm = prefs.getBool('hrAlarm') ?? false;
      _spo2Alarm = prefs.getBool('spo2Alarm') ?? false;
      _wristWake = prefs.getBool('wristWake') ?? true;
      _distance = prefs.getInt('distanceUnit') ?? 0;
      _weight_unit = prefs.getInt('weightUnit') ?? 0;
      _tempUnit = prefs.getInt('tempUnit') ?? 0;
      _timeFormat = prefs.getInt('timeFormat') ?? 0;
    });
  }

  Future<void> _saveUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('userHeight', _height);
    await prefs.setDouble('userWeight', _weight);
    await prefs.setInt('userAge', _age);
    await prefs.setInt('userGender', _gender);
    await sl<BleDataSource>().setUserInfo(
      _height.toInt(),
      _weight.toInt(),
      _age,
      _gender == 0 ? DeviceUserGender.male : DeviceUserGender.female,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved & synced to device')),
      );
    }
  }

  Future<void> _saveStepGoal() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('stepGoal', _stepGoal);
    await sl<BleDataSource>().setStepGoal(_stepGoal.toInt());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Step goal saved')),
      );
    }
  }

  Future<void> _saveMonitoringSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('autoMonitoring', _autoMonitoring);
    await prefs.setBool('hrAlarm', _hrAlarm);
    await prefs.setBool('spo2Alarm', _spo2Alarm);
    await prefs.setBool('wristWake', _wristWake);
    await sl<BleDataSource>().setHealthMonitoring(enable: _autoMonitoring);
    await sl<BleDataSource>().setHeartRateAlarm(enable: _hrAlarm);
    await sl<BleDataSource>().setBloodOxygenAlarm(enable: _spo2Alarm);
    await sl<BleDataSource>().setWristWake(_wristWake);
  }

  Future<void> _applyUnits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('distanceUnit', _distance);
    await prefs.setInt('weightUnit', _weight_unit);
    await prefs.setInt('tempUnit', _tempUnit);
    await prefs.setInt('timeFormat', _timeFormat);
    // Use BleDataSource.setUnits when possible (requires correct SDK enums)
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Units applied')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: AppColors.background,
            expandedHeight: 100,
            pinned: true,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 0, 14),
              title: const Text(
                'Settings',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: BlocBuilder<DeviceBloc, DeviceState>(
              builder: (context, state) {
                final isConnected =
                    state.status == DeviceConnectionStatus.connected;

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // ── Device Info Card ──────────────────────────────────
                      _SettingsCard(children: [
                        _SettingsTile(
                          icon: Icons.bluetooth_rounded,
                          title: 'Device',
                          subtitle: isConnected
                              ? state.deviceName ?? 'Connected'
                              : 'Not connected',
                          onTap: () => context.push(AppRoutes.scan),
                        ),
                        if (isConnected && state.macAddress != null)
                          _SettingsTile(
                            icon: Icons.perm_device_info_rounded,
                            title: 'MAC Address',
                            subtitle: state.macAddress!,
                          ),
                        if (isConnected && state.batteryPercent > 0)
                          _SettingsTile(
                            icon: Icons.battery_std_rounded,
                            title: 'Battery',
                            subtitle: '${state.batteryPercent}%',
                          ),
                      ]),
                      const SizedBox(height: 12),
                      // ── Device Actions ────────────────────────────────────
                      if (isConnected)
                        _SettingsCard(children: [
                          _SettingsTile(
                            icon: Icons.vibration_rounded,
                            title: 'Find Device',
                            subtitle: 'Make your ring vibrate',
                            onTap: () {
                              sl<BleDataSource>().findDevice();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Ring is vibrating…')),
                              );
                            },
                          ),
                          _SettingsTile(
                            icon: Icons.access_time_rounded,
                            title: 'Sync Time',
                            subtitle: 'Sync phone clock to device',
                            onTap: () async {
                              await sl<BleDataSource>().syncPhoneTime();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Time synced')),
                                );
                              }
                            },
                          ),
                          _SettingsTile(
                            icon: Icons.link_off_rounded,
                            title: 'Disconnect',
                            subtitle: 'Disconnect from device',
                            onTap: () {
                              context
                                  .read<DeviceBloc>()
                                  .add(DisconnectDevice());
                            },
                          ),
                        ]),
                      if (isConnected) const SizedBox(height: 12),

                      // ── User Profile ──────────────────────────────────────
                      if (isConnected)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.surfaceLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('User Profile',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              _SliderRow(
                                label: 'Height',
                                value: _height,
                                min: 100,
                                max: 220,
                                unit: 'cm',
                                onChanged: (v) => setState(() => _height = v),
                              ),
                              _SliderRow(
                                label: 'Weight',
                                value: _weight,
                                min: 30,
                                max: 150,
                                unit: 'kg',
                                onChanged: (v) => setState(() => _weight = v),
                              ),
                              _SliderRow(
                                label: 'Age',
                                value: _age.toDouble(),
                                min: 10,
                                max: 100,
                                unit: 'yrs',
                                onChanged: (v) =>
                                    setState(() => _age = v.toInt()),
                              ),
                              Row(
                                children: [
                                  const Text('Gender',
                                      style: TextStyle(
                                          color: AppColors.textSecondary)),
                                  const Spacer(),
                                  ChoiceChip(
                                    label: const Text('Male'),
                                    selected: _gender == 0,
                                    onSelected: (_) =>
                                        setState(() => _gender = 0),
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('Female'),
                                    selected: _gender == 1,
                                    onSelected: (_) =>
                                        setState(() => _gender = 1),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveUserProfile,
                                  child: const Text('Save Profile'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isConnected) const SizedBox(height: 12),

                      // ── Step Goal ─────────────────────────────────────────
                      if (isConnected)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.surfaceLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Activity Goals',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              _SliderRow(
                                label: 'Step Goal',
                                value: _stepGoal,
                                min: 1000,
                                max: 30000,
                                unit: 'steps',
                                divisions: 29,
                                onChanged: (v) => setState(() => _stepGoal = v),
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _saveStepGoal,
                                  child: const Text('Save Goal'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (isConnected) const SizedBox(height: 12),

                      // ── Health Monitoring Toggles ─────────────────────────
                      if (isConnected)
                        _SettingsCard(children: [
                          SwitchListTile(
                            title: const Text('Auto Health Monitoring',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14)),
                            subtitle: const Text('Periodic measurements',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            value: _autoMonitoring,
                            onChanged: (v) {
                              setState(() => _autoMonitoring = v);
                              _saveMonitoringSettings();
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Heart Rate Alarm',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14)),
                            value: _hrAlarm,
                            onChanged: (v) {
                              setState(() => _hrAlarm = v);
                              _saveMonitoringSettings();
                            },
                          ),
                          SwitchListTile(
                            title: const Text('SpO₂ Alarm',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14)),
                            value: _spo2Alarm,
                            onChanged: (v) {
                              setState(() => _spo2Alarm = v);
                              _saveMonitoringSettings();
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Wrist Wake',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14)),
                            value: _wristWake,
                            onChanged: (v) {
                              setState(() => _wristWake = v);
                              _saveMonitoringSettings();
                            },
                          ),
                        ]),
                      if (isConnected) const SizedBox(height: 12),

                      // ── Units Configuration ──────────────────────────────
                      if (isConnected)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.surfaceLight),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Units',
                                  style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              _DropdownRow(
                                label: 'Distance',
                                value: _distance,
                                items: const {0: 'km', 1: 'mile'},
                                onChanged: (v) => setState(() => _distance = v),
                              ),
                              _DropdownRow(
                                label: 'Weight',
                                value: _weight_unit,
                                items: const {0: 'kg', 1: 'lb'},
                                onChanged: (v) =>
                                    setState(() => _weight_unit = v),
                              ),
                              _DropdownRow(
                                label: 'Temperature',
                                value: _tempUnit,
                                items: const {0: '°C', 1: '°F'},
                                onChanged: (v) => setState(() => _tempUnit = v),
                              ),
                              _DropdownRow(
                                label: 'Time',
                                value: _timeFormat,
                                items: const {0: '24h', 1: '12h'},
                                onChanged: (v) =>
                                    setState(() => _timeFormat = v),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _applyUnits,
                                  child: const Text('Apply'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),

                      // ── App Version ───────────────────────────────────────
                      _SettingsCard(children: [
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          title: 'App Version',
                          subtitle: '1.0.0',
                        ),
                      ]),
                      const SizedBox(height: 100),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceLight),
        ),
        child: Column(children: children),
      );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        trailing: onTap != null
            ? const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted)
            : null,
        onTap: onTap,
      );
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String unit;
  final int? divisions;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              Text(label,
                  style: const TextStyle(color: AppColors.textSecondary)),
              const Spacer(),
              Text('${value.round()} $unit',
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions ?? (max - min).toInt(),
            onChanged: onChanged,
          ),
        ],
      );
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final int value;
  final Map<int, String> items;
  final ValueChanged<int> onChanged;

  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            const Spacer(),
            DropdownButton<int>(
              value: value,
              dropdownColor: AppColors.surface,
              items: items.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value,
                          style:
                              const TextStyle(color: AppColors.textPrimary))))
                  .toList(),
              onChanged: (v) => onChanged(v!),
            ),
          ],
        ),
      );
}
