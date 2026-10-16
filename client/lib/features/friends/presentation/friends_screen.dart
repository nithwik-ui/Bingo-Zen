// Friends tab — matches Stitch "Friends & Social". Composed states for
// loading / loaded / requests / empty / error.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/zen_widgets.dart';
import '../application/friends_providers.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<FriendsOverview> overview =
        ref.watch(friendsOverviewProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _searchBar(),
          const SizedBox(height: 12),
          overview.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => ZenErrorView(
              title: 'Could not load friends',
              message: e.toString(),
              onRetry: () => ref.invalidate(friendsOverviewProvider),
            ),
            data: (o) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (o.requests.isNotEmpty) ...[
                  Text('Incoming Invites', style: ZenTypography.headlineSm),
                  const SizedBox(height: 8),
                  for (final r in o.requests)
                    ZenCard(
                      child: Row(
                        children: [
                          ZenAvatar(
                              label: r.from.displayName,
                              ringColor: ZenAccent.amber),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.from.displayName,
                                    style: ZenTypography.labelLg),
                                Text(
                                    r.gameKind != null
                                        ? '${r.gameKind!.displayName} duel • ${_ago(r.createdAt)}'
                                        : 'Friend request • ${_ago(r.createdAt)}',
                                    style: ZenTypography.labelSm.copyWith(
                                        color: ZenText.secondary)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            color: ZenText.secondary,
                            onPressed: () =>
                                ref.read(friendsControllerProvider.notifier).respond(r.id, false),
                          ),
                          IconButton(
                            icon: const Icon(Icons.check_circle),
                            color: ZenAccent.secondary,
                            onPressed: () =>
                                ref.read(friendsControllerProvider.notifier).respond(r.id, true),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                Text('Online Friends', style: ZenTypography.headlineSm),
                const SizedBox(height: 8),
                if (o.online.isEmpty)
                  const ZenEmptyView(
                    title: 'No friends online',
                    message: 'Send invites from your friends list.',
                  )
                else
                  for (final f in o.online)
                    ZenCard(
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
                                    f.presence == PlayerPresence.online
                                        ? 'Available'
                                        : 'In match',
                                    style: ZenTypography.labelSm.copyWith(
                                        color: ZenText.secondary)),
                              ],
                            ),
                          ),
                          ZenStatusChip(
                            label: 'Challenge',
                            icon: Icons.sports_kabaddi_outlined,
                            background: ZenSurfaces.tile,
                            foreground: ZenAccent.primary,
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: ZenSurfaces.card,
        borderRadius: BorderRadius.circular(999),
        border: const Border.fromBorderSide(
          BorderSide(color: ZenOutline.hairline),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      height: 48,
      child: const Row(
        children: [
          Icon(Icons.search, color: ZenText.secondary, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search username, tag, #BZ-ID...',
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          Icon(Icons.tune, color: ZenText.secondary, size: 20),
        ],
      ),
    );
  }

  String _ago(DateTime t) {
    final Duration d = DateTime.now().toUtc().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}