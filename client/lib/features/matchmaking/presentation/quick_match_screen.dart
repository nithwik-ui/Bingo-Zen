// Quick match waiting screen — composed states: connecting / matchmaking /
// matched / error / cancelled.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/zen_widgets.dart';
import '../../auth/application/session_controller.dart';
import '../application/matchmaking_repository.dart';

class QuickMatchScreen extends ConsumerStatefulWidget {
  const QuickMatchScreen({super.key, required this.kind});
  final String kind;

  @override
  ConsumerState<QuickMatchScreen> createState() => _QuickMatchScreenState();
}

class _QuickMatchScreenState extends ConsumerState<QuickMatchScreen> {
  String _phase = 'idle';
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _phase = 'connecting';
      _error = null;
    });
    try {
      final GameKind kind =
          widget.kind == 'sos' ? GameKind.sos : GameKind.bingo;
      final repo = ref.read(matchmakingRepoProvider);
      final room = await repo.startQuickMatch(kind);
      if (!mounted) return;
      // Redirect to waiting then to gameplay.
      setState(() => _phase = 'matched');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        final path = kind == GameKind.sos
            ? '/match/sos/${room.matchId ?? room.id}'
            : '/match/bingo/${room.matchId ?? room.id}';
        context.push('$path?you=${Uri.encodeComponent(ref.read(sessionControllerProvider).user?.id ?? '')}');
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = 'error';
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZenSurfaces.background,
      appBar: AppBar(title: const Text('Quick Match')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_phase == 'connecting' || _phase == 'matched') ...[
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: ZenAccent.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _phase == 'matched'
                      ? 'Opponent found!'
                      : 'Searching for opponent',
                  style: ZenTypography.headlineMd,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Pairing you with a real player. Average wait: <30s.',
                  style: ZenTypography.bodySm,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ZenButton(
                  label: 'Cancel',
                  variant: ZenButtonVariant.secondary,
                  icon: Icons.close,
                  expand: true,
                  onPressed: () => context.pop(),
                ),
              ] else if (_phase == 'error') ...[
                ZenErrorView(
                  title: 'Matchmaking failed',
                  message: _error ?? 'Unknown error',
                  onRetry: _start,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}