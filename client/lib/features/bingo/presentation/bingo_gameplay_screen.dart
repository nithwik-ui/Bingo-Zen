// Bingo gameplay — composed states (your turn / opponent turn / line completed
// / reconnecting / opponent left / finished). The screen ALWAYS preserves the
// last board so the user never loses context during reconnects.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/zen_widgets.dart';
import '../application/bingo_controller.dart';
import 'bingo_board_view.dart';

class BingoGameplayScreen extends ConsumerStatefulWidget {
  const BingoGameplayScreen({
    super.key,
    required this.matchId,
    required this.you,
  });
  final String matchId;
  final String you;

  @override
  ConsumerState<BingoGameplayScreen> createState() =>
      _BingoGameplayScreenState();
}

class _BingoGameplayScreenState extends ConsumerState<BingoGameplayScreen> {
  @override
  Widget build(BuildContext context) {
    final ctrlArgs = BingoControllerArgs(widget.matchId, widget.you);
    final state = ref.watch(bingoControllerProvider(ctrlArgs));
    final ctrl = ref.read(bingoControllerProvider(ctrlArgs).notifier);
    final List<int>? board = state.board;
    return Scaffold(
      backgroundColor: ZenSurfaces.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => _confirmLeave(context),
        ),
        title: const Text('Gameplay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _latencyStrip(state),
              _versusBar(state),
              _callStrip(state),
              _boardArea(board, state, ctrl),
              const Spacer(),
              _bottomActions(state, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _latencyStrip(BingoState s) {
    return Row(
      children: [
        const ZenStatusChip(
          label: 'Live',
          background: Color(0x336CF8BB),
          foreground: ZenAccent.onSecondaryContainer,
          leadingDotColor: ZenAccent.secondary,
        ),
        const Spacer(),
        TextButton.icon(
          icon: const Icon(Icons.logout, size: 16),
          label: const Text('Leave'),
          onPressed: () => _confirmLeave(context),
        ),
      ],
    );
  }

  Widget _versusBar(BingoState s) {
    return ZenCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ZenAvatar(label: widget.you, ringColor: ZenAccent.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You', style: ZenTypography.labelLg),
                Text('${s.linesCompleted}/5 lines',
                    style: ZenTypography.labelSm.copyWith(color: ZenText.secondary)),
              ],
            ),
          ),
          _phaseBadge(s),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(s.opponentId ?? 'Opponent',
                    style: ZenTypography.labelLg),
                Text('${s.opponentLines}/5 lines',
                    style: ZenTypography.labelSm.copyWith(color: ZenText.secondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ZenAvatar(label: s.opponentId ?? '?'),
        ],
      ),
    );
  }

  Widget _phaseBadge(BingoState s) {
    final Color amber = ZenAccent.amber;
    if (s.isReconnecting) {
      return ZenStatusChip(
        label: 'Reconnecting',
        background: const Color(0x33FFDDB8),
        foreground: ZenAccent.onTertiaryFixed,
        leadingDotColor: amber,
      );
    }
    return ZenStatusChip(
      label: s.isYourTurn
          ? 'Your turn'
          : (s.phase == BingoUiPhase.lineCompleted ? 'Line!' : 'Waiting'),
      background:
          s.isYourTurn ? const Color(0x33D2D4FF) : ZenSurfaces.tile,
      foreground: s.isYourTurn
          ? ZenAccent.onPrimaryContainer
          : ZenText.secondary,
      leadingDotColor: s.isYourTurn ? ZenAccent.primary : amber,
    );
  }

  Widget _callStrip(BingoState s) {
    final Color amber = ZenAccent.amber;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x33FFDDB8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Last Call',
                    style: ZenTypography.labelSm.copyWith(color: amber)),
                Text(s.lastCall == null ? '—' : '${s.lastCall}',
                    style: ZenTypography.headlineSm),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: s.calledNumbers.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: ZenSurfaces.tile,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${s.calledNumbers[i]}',
                        style: ZenTypography.labelMd),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _boardArea(List<int>? board, BingoState s, BingoController ctrl) {
    if (board == null) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return AspectRatio(
      aspectRatio: 1,
      child: BingoBoardView(
        board: board,
        marked: s.marked,
        recentlyMarked: s.recentlyMarked,
        calledNumbers: s.calledNumbers,
        recentlyCompletedLines: s.recentlyCompletedLines,
        enabled: s.isYourTurn && !s.isFinished,
        onTapNumber: ctrl.callNumber,
      ),
    );
  }

  Widget _bottomActions(BingoState s, BuildContext context) {
    if (s.isFinished) {
      return Column(
        children: [
          Text(
            s.outcome == MatchOutcome.win
                ? 'You won!'
                : (s.outcome == MatchOutcome.loss ? 'You lost' : 'Draw'),
            style: ZenTypography.headlineLg,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ZenButton(
                  label: 'Rematch',
                  icon: Icons.refresh,
                  expand: true,
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ZenButton(
                  label: 'Home',
                  icon: Icons.home_outlined,
                  variant: ZenButtonVariant.secondary,
                  expand: true,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ],
      );
    }
    if (s.phase == BingoUiPhase.error) {
      return ZenErrorView(
        title: 'Match ended',
        message: s.errorMessage ?? 'Connection lost',
        onRetry: () => ref.invalidate(bingoControllerProvider),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Leave match?'),
        content: const Text(
          'Leaving may cause the match to be marked as abandoned.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave')),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      Navigator.of(context).pop();
    }
  }
}