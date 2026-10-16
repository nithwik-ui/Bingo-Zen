// SOS Details screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/widgets/zen_widgets.dart';

class SosDetailsScreen extends ConsumerWidget {
  const SosDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ZenSurfaces.background,
      appBar: AppBar(title: const Text('SOS')),
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
                          color: ZenAccent.secondary,
                          borderRadius: ZenRadius.cardLg,
                        ),
                        child: const Center(
                          child: Text('S',
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
                            Text('Spatial SOS Duel',
                                style: ZenTypography.headlineMd),
                            Text('Real-time letter-placement duel',
                                style: ZenTypography.bodySm),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('How to play',
                      style: ZenTypography.headlineSm),
                  const SizedBox(height: 8),
                  Text(
                    'Take turns placing S or O on a 5×5 board. Complete a straight line of S-O-S to score. Each new SOS grants another turn. When the board is full, the higher score wins.',
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
              onPressed: () => context.push('/quick-match/sos'),
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
                    onPressed: () => context.push('/create-room/sos'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ZenButton(
                    label: 'Join Code',
                    icon: Icons.dialpad,
                    variant: ZenButtonVariant.secondary,
                    expand: true,
                    onPressed: () => context.push('/join-room/sos'),
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