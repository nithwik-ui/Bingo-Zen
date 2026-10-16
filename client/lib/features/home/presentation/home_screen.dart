// Home screen — Stitch design rendered as composable widgets. Composed
// states handle loading / loaded / error per data source.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show WidgetRef;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/zen_widgets.dart';
import '../../auth/application/session_controller.dart';
import '../../friends/application/friends_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final SessionState session = ref.watch(sessionControllerProvider);
    final AsyncValue<FriendsOverview> friends = ref.watch(friendsOverviewProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _greeting(session.user?.displayName ?? 'Player'),
          const SizedBox(height: 16),
          _quickActions(context),
          const SizedBox(height: 24),
          _chooseAGame(context),
          const SizedBox(height: 24),
          _friendsOnline(context, ref, friends),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _greeting(String name) {
    final String hourGreet = () {
      final int h = DateTime.now().hour;
      if (h < 12) return 'Good morning';
      if (h < 18) return 'Good afternoon';
      return 'Good evening';
    }();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ZenAvatar(label: name, ringColor: ZenAccent.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Bingo Zen',
                          style: ZenTypography.headlineSm.copyWith(
                              fontWeight: FontWeight.w800)),
                      const SizedBox(width: 6),
                      const ZenStatusChip(
                        label: 'Online',
                        leadingDotColor: ZenAccent.secondary,
                        background: Color(0x336CF8BB),
                        foreground: ZenAccent.onSecondaryContainer,
                      ),
                    ],
                  ),
                  Text('Home',
                      style: ZenTypography.labelSm
                          .copyWith(color: ZenText.secondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Arcade Session'.toUpperCase(),
          style: ZenTypography.labelSm.copyWith(color: ZenText.secondary),
        ),
        const SizedBox(height: 4),
        Text('$hourGreet, $name', style: ZenTypography.headlineLg),
      ],
    );
  }

  Widget _quickActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ZenCard(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(Icons.bolt, color: ZenAccent.primaryContainer),
                const SizedBox(height: 4),
                Text('Quick Match',
                    style: ZenTypography.labelLg
                        .copyWith(fontWeight: FontWeight.w700)),
                Text('Instant pairing',
                    style: ZenTypography.labelSm
                        .copyWith(color: ZenText.secondary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ZenCard(
            padding: const EdgeInsets.symmetric(vertical: 16),
            onTap: () => context.push('/create-room/bingo'),
            child: Column(
              children: [
                Icon(Icons.add_circle_outline, color: ZenAccent.primary),
                const SizedBox(height: 4),
                Text('Create Room',
                    style: ZenTypography.labelLg
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('Share a code',
                    style: ZenTypography.labelSm
                        .copyWith(color: ZenText.secondary)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ZenCard(
            padding: const EdgeInsets.symmetric(vertical: 16),
            onTap: () => context.push('/join-room/bingo'),
            child: Column(
              children: [
                Icon(Icons.dialpad, color: ZenText.secondary),
                const SizedBox(height: 4),
                Text('Join Code',
                    style: ZenTypography.labelLg
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('Enter PIN',
                    style: ZenTypography.labelSm
                        .copyWith(color: ZenText.secondary)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _chooseAGame(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Choose a game', style: ZenTypography.headlineSm),
            const SizedBox(width: 8),
            const ZenLiveDot(),
          ],
        ),
        const SizedBox(height: 12),
        ZenCard(
          padding: const EdgeInsets.all(20),
          onTap: () => context.push('/home/bingo'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _gameThumb(secondary: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('BINGO',
                                style: ZenTypography.headlineSm
                                    .copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(width: 6),
                            const ZenStatusChip(
                              label: 'Featured',
                              background: Color(0x336CF8BB),
                              foreground: ZenAccent.onSecondaryContainer,
                              leadingDotColor: ZenAccent.secondary,
                            ),
                          ],
                        ),
                        Text('Tactical Dual-Grid',
                            style: ZenTypography.labelSm
                                .copyWith(color: ZenText.secondary)),
                      ],
                    ),
                  ),
                  const ZenStatusChip(
                    label: 'Live',
                    leadingDotColor: ZenAccent.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Take turns calling numbers. Complete 5 tactical lines before your opponent locks the board.',
                style: ZenTypography.bodySm,
              ),
              const SizedBox(height: 12),
              ZenButton(
                label: 'Play Bingo',
                icon: Icons.arrow_forward,
                expand: true,
                onPressed: () => context.push('/home/bingo'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ZenCard(
          padding: const EdgeInsets.all(20),
          onTap: () => context.push('/home/sos'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _gameThumb(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('SOS CLASSIC',
                            style: ZenTypography.headlineSm
                                .copyWith(fontWeight: FontWeight.w800)),
                        Text('Tactical Spatial Traps',
                            style: ZenTypography.labelSm
                                .copyWith(color: ZenText.secondary)),
                      ],
                    ),
                  ),
                  const ZenStatusChip(
                    label: 'Live',
                    leadingDotColor: ZenAccent.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Build SOS patterns and outplay your opponent in real-time. Score chains award bonus turns.',
                style: ZenTypography.bodySm,
              ),
              const SizedBox(height: 12),
              ZenButton(
                label: 'Play SOS',
                icon: Icons.chevron_right,
                variant: ZenButtonVariant.secondary,
                expand: true,
                onPressed: () => context.push('/home/sos'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _gameThumb({bool secondary = false}) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: ZenRadius.cardMd,
        color: ZenSurfaces.tile,
      ),
      padding: const EdgeInsets.all(8),
      child: secondary
          ? GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: 25,
              itemBuilder: (_, i) {
                final List<Color> palette = [
                  ZenAccent.primary,
                  ZenAccent.secondary,
                  ZenAccent.tertiaryFixedDim,
                  ZenSurfaces.containerHighest,
                ];
                final int n = (i * 7) % 4;
                return Container(
                  decoration: BoxDecoration(
                    color: palette[n],
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              },
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('S O S',
                    style: ZenTypography.labelSm
                        .copyWith(color: ZenAccent.primary)),
              ],
            ),
    );
  }

  Widget _friendsOnline(BuildContext context, WidgetRef ref, AsyncValue<FriendsOverview> friends) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Friends Online', style: ZenTypography.headlineSm),
            const SizedBox(width: 6),
            friends.when(
              data: (o) => ZenStatusChip(
                label: '${o.onlineCount}',
                background: const Color(0x336CF8BB),
                foreground: ZenAccent.onSecondaryContainer,
              ),
              loading: () => const ZenStatusChip(label: '…'),
              error: (_, __) => const ZenStatusChip(label: '!'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        friends.when(
          data: (overview) {
            if (overview.online.isEmpty) {
              return const ZenEmptyView(
                title: 'No friends online yet',
                message: 'Add friends from the Friends tab to invite them.',
              );
            }
            return Column(
              children: [
                for (final f in overview.online)
                  ZenCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ZenAvatar(
                            label: f.displayName,
                            ringColor: f.presence == PlayerPresence.online
                                ? ZenAccent.secondary
                                : null),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.displayName,
                                  style: ZenTypography.labelLg),
                              Text(
                                  f.presence == PlayerPresence.inMatch
                                      ? 'In match'
                                      : 'Available',
                                  style: ZenTypography.labelSm.copyWith(
                                      color: ZenText.secondary)),
                            ],
                          ),
                        ),
                        ZenStatusChip(
                          label: f.presence == PlayerPresence.online
                              ? 'Available'
                              : 'In Match',
                          background: f.presence == PlayerPresence.online
                              ? const Color(0x336CF8BB)
                              : ZenSurfaces.tile,
                          foreground: f.presence == PlayerPresence.online
                              ? ZenAccent.onSecondaryContainer
                              : ZenText.secondary,
                          leadingDotColor: f.presence == PlayerPresence.online
                              ? ZenAccent.secondary
                              : ZenAccent.amber,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => ZenErrorView(
            title: 'Could not load friends',
            message: e.toString(),
            onRetry: () => ref.invalidate(friendsOverviewProvider),
          ),
        ),
      ],
    );
  }
}