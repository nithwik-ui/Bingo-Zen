// Settings — sound, haptics, notifications, account, privacy, help.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/widgets/zen_widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _sound = true;
  bool _haptics = true;
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZenSurfaces.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _group('Gameplay', [
            _switch('Sound effects', _sound, (v) => setState(() => _sound = v)),
            _switch('Haptics', _haptics, (v) => setState(() => _haptics = v)),
          ]),
          const SizedBox(height: 16),
          _group('Notifications', [
            _switch('Friend activity & challenges', _notifications,
                (v) => setState(() => _notifications = v)),
          ]),
          const SizedBox(height: 16),
          _group('Account', [
            _row('Edit Profile', Icons.chevron_right),
            _row('Privacy', Icons.chevron_right),
            _row('Help & Support', Icons.chevron_right),
          ]),
          const SizedBox(height: 16),
          ZenButton(
            label: 'Sign out',
            variant: ZenButtonVariant.danger,
            icon: Icons.logout,
            expand: true,
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _group(String title, List<Widget> children) {
    return ZenCard(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(title.toUpperCase(),
                style: ZenTypography.labelSm.copyWith(color: ZenText.secondary)),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _switch(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label, style: ZenTypography.bodyMd),
      value: value,
      onChanged: onChanged,
      activeThumbColor: ZenAccent.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _row(String label, IconData icon) {
    return ListTile(
      title: Text(label, style: ZenTypography.bodyMd),
      trailing: Icon(icon, color: ZenText.secondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      onTap: () {},
    );
  }
}