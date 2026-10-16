// Games tab — Stitch playroom_rooms_matchmaking_light reference. Provides
// three modes: Join Code / Create Room / Quick Match.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/widgets/zen_widgets.dart';
import '../../rooms/presentation/room_code_input.dart';

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  _TabMode _mode = _TabMode.join;
  final TextEditingController _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              ZenAvatar(label: 'BZ', size: 36, ringColor: ZenAccent.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bingo Zen', style: ZenTypography.headlineSm),
                    Text('Games & Social',
                        style: ZenTypography.labelSm
                            .copyWith(color: ZenText.secondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _modeSwitcher(),
          const SizedBox(height: 16),
          _modeBody(),
        ],
      ),
    );
  }

  Widget _modeSwitcher() {
    return Container(
      decoration: BoxDecoration(
        color: ZenSurfaces.tile,
        borderRadius: ZenRadius.pill,
      ),
      padding: const EdgeInsets.all(6),
      child: Row(
        children: [
          _modeButton(_TabMode.join, Icons.key, 'Join Code'),
          _modeButton(_TabMode.create, Icons.add_circle_outline, 'Create Room'),
          _modeButton(_TabMode.quick, Icons.bolt, 'Quick Match'),
        ],
      ),
    );
  }

  Widget _modeButton(_TabMode mode, IconData icon, String label) {
    final bool active = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _mode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? ZenSurfaces.card : Colors.transparent,
            borderRadius: ZenRadius.pill,
            boxShadow: active
                ? [
                    const BoxShadow(
                      color: Color(0x14111827),
                      offset: Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 16,
                  color: active ? ZenAccent.primary : ZenText.secondary),
              const SizedBox(width: 6),
              Text(label,
                  style: ZenTypography.labelMd.copyWith(
                    color: active ? ZenText.primary : ZenText.secondary,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modeBody() {
    switch (_mode) {
      case _TabMode.join:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ZenStatusChip(
              label: 'Instant Match Session',
              background: Color(0x336CF8BB),
              foreground: ZenAccent.onSecondaryContainer,
              leadingDotColor: ZenAccent.secondary,
            ),
            const SizedBox(height: 12),
            Text('Enter Access Code',
                style: ZenTypography.headlineMd,
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text('Ask your host for their 6-character room code',
                style: ZenTypography.bodySm,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            RoomCodeInput(
              controller: _code,
              length: 6,
              onSubmit: (code) async {
                context.push('/waiting/join:$code');
              },
            ),
            const SizedBox(height: 12),
            ZenButton(
              label: 'Enter Room',
              icon: Icons.arrow_forward,
              expand: true,
              onPressed: () => context.push('/waiting/join:${_code.text}'),
            ),
          ],
        );
      case _TabMode.create:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Create a private room', style: ZenTypography.headlineMd),
            const SizedBox(height: 8),
            Text('Pick a game and we will generate a code you can share.',
                style: ZenTypography.bodySm),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ZenButton(
                    label: 'Bingo Room',
                    icon: Icons.grid_view,
                    expand: true,
                    onPressed: () => context.push('/create-room/bingo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ZenButton(
                    label: 'SOS Room',
                    icon: Icons.token_outlined,
                    variant: ZenButtonVariant.secondary,
                    expand: true,
                    onPressed: () => context.push('/create-room/sos'),
                  ),
                ),
              ],
            ),
          ],
        );
      case _TabMode.quick:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Quick Match', style: ZenTypography.headlineMd),
            const SizedBox(height: 8),
            Text('Get paired with a real opponent in seconds.',
                style: ZenTypography.bodySm),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ZenButton(
                    label: 'Bingo',
                    icon: Icons.bolt,
                    expand: true,
                    onPressed: () => context.push('/quick-match/bingo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ZenButton(
                    label: 'SOS',
                    icon: Icons.token,
                    variant: ZenButtonVariant.secondary,
                    expand: true,
                    onPressed: () => context.push('/quick-match/sos'),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }
}

enum _TabMode { join, create, quick }