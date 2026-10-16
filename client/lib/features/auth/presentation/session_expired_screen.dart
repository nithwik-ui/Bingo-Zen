// Session Expired — used when server returns 401. Recovery re-authenticates.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/widgets/zen_widgets.dart';
import '../application/session_controller.dart';

class SessionExpiredScreen extends ConsumerWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: ZenSurfaces.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_clock_outlined,
                  size: 56, color: ZenAccent.primary),
              const SizedBox(height: 12),
              Text('Session expired', style: ZenTypography.headlineLg),
              const SizedBox(height: 8),
              Text(
                'Sign in again to continue playing.',
                style: ZenTypography.bodyMd,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ZenButton(
                label: 'Sign in again',
                icon: Icons.refresh,
                expand: true,
                onPressed: () async {
                  await ref.read(sessionControllerProvider.notifier).bootstrap();
                  if (!context.mounted) return;
                  context.go('/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}