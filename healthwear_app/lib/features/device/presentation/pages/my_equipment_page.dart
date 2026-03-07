import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_theme.dart';
import '../bloc/device_bloc.dart';

/// "My Equipment" screen — shown when the device is already connected.
/// Displays device name, battery, MAC address, and settings actions.
class MyEquipmentPage extends StatelessWidget {
  const MyEquipmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DeviceBloc, DeviceState>(
      builder: (context, state) {
        final name = state.deviceName ?? 'Unknown Device';
        final mac = state.macAddress ?? '--:--:--:--:--:--';
        final battery = state.batteryPercent;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.chevron_left, size: 28),
              color: AppColors.textPrimary,
              onPressed: () => context.pop(),
            ),
            centerTitle: true,
            title: const Text(
              'My Equipment',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Column(
            children: [
              // ── Device Image + Info ──
              const SizedBox(height: 24),
              _DeviceHeader(name: name, battery: battery, mac: mac),
              const SizedBox(height: 32),

              // ── Action Rows ──
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _ActionTile(
                      icon: Icons.favorite_border_rounded,
                      label: 'Health settings',
                      onTap: () {
                        // TODO: navigate to health settings
                      },
                    ),
                    _divider(),
                    _ActionTile(
                      icon: Icons.settings_rounded,
                      label: 'Device settings',
                      onTap: () {
                        // TODO: navigate to device settings
                      },
                    ),
                    _divider(),
                    _ActionTile(
                      icon: Icons.info_outline_rounded,
                      label: 'About device',
                      onTap: () {
                        _showAboutDialog(context, state);
                      },
                    ),
                  ],
                ),
              ),

              // ── Disconnect Button ──
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.surfaceLight,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      context.read<DeviceBloc>().add(DisconnectDevice());
                      context.pop();
                    },
                    child: const Text(
                      'Disconnect',
                      style: TextStyle(
                        color: AppColors.accentRed,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        color: AppColors.textMuted.withOpacity(0.3),
        height: 1,
      ),
    );
  }

  void _showAboutDialog(BuildContext context, DeviceState state) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'About Device',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _aboutRow('Name', state.deviceName ?? 'N/A'),
            const SizedBox(height: 8),
            _aboutRow('MAC', state.macAddress ?? 'N/A'),
            const SizedBox(height: 8),
            _aboutRow('Battery', '${state.batteryPercent}%'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ─── Device Header Widget ───────────────────────────────────────────────────

class _DeviceHeader extends StatelessWidget {
  final String name;
  final int battery;
  final String mac;

  const _DeviceHeader({
    required this.name,
    required this.battery,
    required this.mac,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ring icon in a circular container
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.15),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(
            Icons.watch_rounded,
            size: 56,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(height: 20),
        // Device name
        Text(
          name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        // Battery + MAC
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _batteryIcon(battery),
              color: _batteryColor(battery),
              size: 22,
            ),
            const SizedBox(width: 4),
            Text(
              '$battery%',
              style: TextStyle(
                color: _batteryColor(battery),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              mac,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _batteryIcon(int pct) {
    if (pct > 80) return Icons.battery_full_rounded;
    if (pct > 50) return Icons.battery_5_bar_rounded;
    if (pct > 20) return Icons.battery_3_bar_rounded;
    return Icons.battery_1_bar_rounded;
  }

  Color _batteryColor(int pct) {
    if (pct > 50) return AppColors.accentGreen;
    if (pct > 20) return AppColors.accentOrange;
    return AppColors.accentRed;
  }
}

// ─── Action Tile Widget ─────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withOpacity(0.12),
                ),
                child: Icon(icon, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 16),
              // Label
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Chevron
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
