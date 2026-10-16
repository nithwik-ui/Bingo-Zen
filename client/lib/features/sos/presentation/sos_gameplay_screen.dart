// SOS gameplay screen — composed states (your turn / opponent turn / extra
// turn / reconnecting / opponent left / finished).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/widgets/zen_widgets.dart';
import '../application/sos_controller.dart';
import 'sos_board_view.dart';

class SosGameplayScreen extends ConsumerStatefulWidget {
  const SosGameplayScreen({
    super.key,
    required this.matchId,
    required this.you,
  });
  final String matchId;
  final String you;

  @override
  ConsumerState<SosGameplayScreen> createState() => _SosGameplayScreenState();
}

class _SosGameplayScreenState extends ConsumerState<SosGameplayScreen> {
  @override
  Widget build(BuildContext context) {
    final ctrlArgs = SosControllerArgs(widget.matchId, widget.you);
    final state = ref.watch(sosControllerProvider(ctrlArgs));
    final ctrl = ref.read(sosControllerProvider(ctrlArgs).notifier);
    final List<int>? board = state.board;
    return Scaffold(
      backgroundColor: ZenSurfaces.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('SOS Match Arena'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _chips(state),
              const SizedBox(height: 8),
              _versusBar(state),
              const SizedBox(height: 8),
              _symbolPicker(state, ctrl),
              const SizedBox(height: 8),
              if (board == null)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: SosBoardView(
                        board: board,
                        newSosLines: state.newSosLines,
                        enabled: state.isYourTurn && !state.isFinished,
                        onTapCell: (r, c) => ctrl.place(r, c),
                      ),
                    ),
                  ),
                ),
              _bottomActions(state, context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chips(SosState s) {
    final Color amber = ZenAccent.amber;
    return Row(
      children: [
        Expanded(
          child: ZenStatusChip(
            label: s.isReconnecting ? 'Reconnecting' : 'Live',
            background: s.isReconnecting
                ? const Color(0x33FFDDB8)
                : const Color(0x336CF8BB),
            foreground: s.isReconnecting
                ? ZenAccent.onTertiaryFixed
                : ZenAccent.onSecondaryContainer,
            leadingDotColor: s.isReconnecting ? amber : ZenAccent.secondary,
          ),
        ),
        const SizedBox(width: 8),
        ZenStatusChip(
          label: s.isYourTurn ? 'YOUR TURN' : 'OPPONENT',
          background: const Color(0x336CF8BB),
          foreground: ZenAccent.onSecondaryContainer,
          icon: Icons.hourglass_top,
        ),
        const SizedBox(width: 8),
        const ZenStatusChip(
          label: 'Ranked',
          icon: Icons.military_tech,
          background: ZenSurfaces.tile,
        ),
      ],
    );
  }

  Widget _versusBar(SosState s) {
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
                Text('${s.score} SOS',
                    style: ZenTypography.labelSm.copyWith(color: ZenAccent.secondary)),
              ],
            ),
          ),
          Text('${s.score}:${s.opponentScore}',
              style: ZenTypography.headlineLg.copyWith(color: ZenText.primary)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(s.opponentId ?? 'Opponent', style: ZenTypography.labelLg),
                Text('${s.opponentScore} SOS',
                    style: ZenTypography.labelSm.copyWith(color: ZenAccent.amber)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ZenAvatar(label: s.opponentId ?? '?', ringColor: ZenAccent.amber),
        ],
      ),
    );
  }

  Widget _symbolPicker(SosState s, SosController ctrl) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => ctrl.setSymbol(Sossymbol.s),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: s.symbol == Sossymbol.s
                    ? ZenAccent.primaryContainer
                    : ZenSurfaces.tile,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('S',
                  style: ZenTypography.headlineMd.copyWith(
                      color: s.symbol == Sossymbol.s
                          ? Colors.white
                          : ZenText.primary)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => ctrl.setSymbol(Sossymbol.o),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: s.symbol == Sossymbol.o
                    ? ZenAccent.primaryContainer
                    : ZenSurfaces.tile,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text('O',
                  style: ZenTypography.headlineMd.copyWith(
                      color: s.symbol == Sossymbol.o
                          ? Colors.white
                          : ZenText.primary)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomActions(SosState s, BuildContext context) {
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
    if (s.phase == SosUiPhase.error) {
      return ZenErrorView(
        title: 'Match ended',
        message: s.errorMessage ?? 'Connection lost',
        onRetry: () => ref.invalidate(sosControllerProvider),
      );
    }
    return const SizedBox.shrink();
  }
}