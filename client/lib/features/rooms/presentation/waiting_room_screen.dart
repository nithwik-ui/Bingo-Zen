// Waiting Room screen — handles waiting / player-joined / starting / error.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/widgets/zen_widgets.dart';

class WaitingRoomScreen extends ConsumerWidget {
  const WaitingRoomScreen({super.key, required this.roomId});
  final String roomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ZenSurfaces.background,
      appBar: AppBar(title: const Text('Waiting Room')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const ZenLiveDot(size: 12),
              const SizedBox(height: 8),
              const ZenStatusChip(
                label: 'Waiting for opponent to join',
                background: Color(0x336CF8BB),
                foreground: ZenAccent.onSecondaryContainer,
              ),
              const SizedBox(height: 24),
              Text('Lobby Roster', style: ZenTypography.headlineSm),
              const SizedBox(height: 12),
              ZenCard(
                child: Row(
                  children: [
                    ZenAvatar(
                      label: 'You',
                      ringColor: ZenAccent.secondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('You (Host)', style: ZenTypography.labelLg),
                          Text('Ready', style: ZenTypography.labelSm.copyWith(color: ZenAccent.secondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ZenCard(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ZenSurfaces.tile,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(Icons.hourglass_top,
                          color: ZenText.secondary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Waiting for opponent…',
                              style: ZenTypography.labelLg),
                          Text('Share the code to duel',
                              style: ZenTypography.labelSm.copyWith(color: ZenText.secondary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ZenButton(
                label: 'Cancel',
                variant: ZenButtonVariant.secondary,
                icon: Icons.close,
                expand: true,
                onPressed: () => context.pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}