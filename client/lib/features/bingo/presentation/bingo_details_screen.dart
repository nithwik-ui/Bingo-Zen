// Bingo Details screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/widgets/zen_widgets.dart';

class BingoDetailsScreen extends ConsumerWidget {
  const BingoDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ZenSurfaces.background,
      appBar: AppBar(title: const Text('Bingo')),
      body: SafeArea(
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
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: ZenAccent.primaryContainer,
                          borderRadius: ZenRadius.cardLg,
                        ),
                        child: const Center(
                          child: Text('B',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                              )),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tactical Dual-Grid',
                                style: ZenTypography.headlineMd),
                            Text('Fast 2-player number strategy',
                                style: ZenTypography.bodySm),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How to play',
                    style: ZenTypography.headlineSm,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Each player gets a 5x5 board with 25 unique numbers from 0–25. Take turns; the active player calls a number. If the number is on your board, mark it. The first to complete 5 lines (rows, columns, or diagonals) wins.',
                    style: ZenTypography.bodySm,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ZenButton(
              label: 'Quick Match',
              icon: Icons.bolt,
              expand: true,
              onPressed: () => context.push('/quick-match/bingo'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ZenButton(
                    label: 'Create Room',
                    icon: Icons.add_circle_outline,
                    variant: ZenButtonVariant.secondary,
                    expand: true,
                    onPressed: () => context.push('/create-room/bingo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ZenButton(
                    label: 'Join Code',
                    icon: Icons.dialpad,
                    variant: ZenButtonVariant.secondary,
                    expand: true,
                    onPressed: () => context.push('/join-room/bingo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}