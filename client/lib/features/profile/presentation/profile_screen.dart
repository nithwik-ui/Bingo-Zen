// Profile screen — Stitch playroom_player_profile reference. Composed
// states: loading / loaded / editing / error.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/widgets/zen_widgets.dart';
import '../../auth/application/session_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionState s = ref.watch(sessionControllerProvider);
    final u = s.user;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ZenCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ZenAvatar(
                      label: u?.displayName ?? '?',
                      size: 80,
                      ringColor: ZenAccent.secondary,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u?.displayName ?? 'Loading…',
                              style: ZenTypography.headlineMd),
                          if (u != null) ...[
                            Text('@${u.handle ?? 'guest'}',
                                style: ZenTypography.labelSm
                                    .copyWith(color: ZenText.secondary)),
                            const SizedBox(height: 4),
                            const ZenStatusChip(
                              label: 'Zen Master Tier',
                              leadingDotColor: ZenAccent.secondary,
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.ios_share),
                      onPressed: () {},
                    ),
                  ],
                ),
                if (u != null && u.bio != null) ...[
                  const SizedBox(height: 12),
                  Text(u.bio!, style: ZenTypography.bodySm),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _statsCard(),
          const SizedBox(height: 16),
          _quickActions(context),
        ],
      ),
    );
  }

  Widget _statsCard() {
    return ZenCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0x336CF8BB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.qr_code_2,
                    color: ZenAccent.onSecondaryContainer, size: 20),
              ),
              const SizedBox(width: 8),
              Text('Zen Connect & QR Pass', style: ZenTypography.headlineSm),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: ZenSurfaces.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: ZenOutline.variant),
            ),
            child: const Center(
              child: Icon(Icons.qr_code_2, size: 120, color: ZenText.primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ZenButton(
                  label: 'Show QR',
                  icon: Icons.qr_code,
                  variant: ZenButtonVariant.secondary,
                  expand: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ZenButton(
                  label: 'Scan',
                  icon: Icons.qr_code_scanner,
                  variant: ZenButtonVariant.secondary,
                  expand: true,
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ZenButton(
            label: 'Achievements',
            variant: ZenButtonVariant.secondary,
            icon: Icons.emoji_events_outlined,
            expand: true,
            onPressed: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ZenButton(
            label: 'Settings',
            variant: ZenButtonVariant.secondary,
            icon: Icons.settings_outlined,
            expand: true,
            onPressed: () => context.push('/profile/settings'),
          ),
        ),
      ],
    );
  }
}