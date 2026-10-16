// Onboarding screen (Splash → Welcome → Name → Avatar → Notifications → PWA)
// We render all steps as a PageView within a single screen; the prompt
// requires us to "wire" each step, not produce 6 separate mockups.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/notifications/notifications_service.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/widgets/zen_widgets.dart';
import '../../auth/application/session_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  int _index = 0;
  String _name = '';
  String _avatar = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZenSurfaces.background,
      body: SafeArea(
        child: PageView(
          controller: _pages,
          onPageChanged: (i) => setState(() => _index = i),
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _splash(),
            _welcome(),
            _nameStep(),
            _avatarStep(),
            _notificationsStep(),
            _pwaStep(),
          ],
        ),
      ),
    );
  }

  Widget _splash() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: ZenAccent.primaryContainer,
              boxShadow: ZenShadow.primary,
            ),
            child: const Center(
              child: Text(
                'BZ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Bingo Zen', style: ZenTypography.headlineLg),
          const SizedBox(height: 4),
          Text('Premium multiplayer play', style: ZenTypography.bodySm),
        ],
      ),
    );
  }

  Widget _welcome() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Welcome', style: ZenTypography.displayXl),
          const SizedBox(height: 8),
          Text(
            'Tactical. Calm. Real-time multiplayer.',
            style: ZenTypography.bodyLg,
          ),
          const SizedBox(height: 24),
          const Expanded(child: SizedBox()),
          ZenButton(
            label: 'Get Started',
            expand: true,
            icon: Icons.arrow_forward,
            onPressed: () => _pages.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            ),
          ),
        ],
      ),
    );
  }

  Widget _nameStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose a player name', style: ZenTypography.headlineLg),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            maxLength: 24,
            onChanged: (v) => _name = v,
            decoration: const InputDecoration(
              hintText: 'e.g. TaroX',
            ),
          ),
          const SizedBox(height: 24),
          ZenButton(
            label: 'Continue',
            expand: true,
            icon: Icons.arrow_forward,
            onPressed: _name.trim().isEmpty
                ? null
                : () => _pages.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _avatarStep() {
    final List<String> ids = ['fox', 'cat', 'panda', 'zen', 'star'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pick your avatar', style: ZenTypography.headlineLg),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final id in ids)
                GestureDetector(
                  onTap: () => setState(() => _avatar = id),
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: _avatar == id
                          ? ZenAccent.primaryFixed
                          : ZenSurfaces.tile,
                      borderRadius: ZenRadius.cardLg,
                      border: Border.all(
                        color: _avatar == id
                            ? ZenAccent.primary
                            : ZenOutline.hairline,
                        width: _avatar == id ? 2 : 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        id[0].toUpperCase(),
                        style: ZenTypography.headlineMd,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          ZenButton(
            label: 'Continue',
            expand: true,
            icon: Icons.arrow_forward,
            onPressed: _avatar.isEmpty
                ? null
                : () => _pages.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    ),
          ),
        ],
      ),
    );
  }

  Widget _notificationsStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Stay in the loop', style: ZenTypography.headlineLg),
          const SizedBox(height: 8),
          Text(
            'We use notifications only for friend activity and active-match events. You can disable anytime in Settings.',
            style: ZenTypography.bodySm,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ZenButton(
                  label: 'Not now',
                  variant: ZenButtonVariant.secondary,
                  expand: true,
                  onPressed: () => _pages.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ZenButton(
                  label: 'Allow',
                  expand: true,
                  icon: Icons.notifications_active_outlined,
                  onPressed: () async {
                    await ref.read(notificationsProvider).requestPermission();
                    _pages.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pwaStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Bingo Zen to your home', style: ZenTypography.headlineLg),
          const SizedBox(height: 8),
          Text(
            'Install as an app for instant access. On iPhone: tap Share → Add to Home Screen.',
            style: ZenTypography.bodySm,
          ),
          const SizedBox(height: 24),
          ZenButton(
            label: 'Got it',
            expand: true,
            icon: Icons.check_circle_outline,
            onPressed: () async {
              await ref
                  .read(analyticsProvider)
                  .track(AnalyticsEvents.onboardingComplete);
              try {
                await ref
                    .read(sessionControllerProvider.notifier)
                    .completeOnboarding(
                      displayName: _name.trim(),
                      avatarUrl: 'asset:avatar:$_avatar',
                    );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Failed: $e')));
                return;
              }
              if (!mounted) return;
              // Mark onboarding complete in storage so we don't show again.
              final AsyncValue<ZenStorage> storage =
                  ref.read(storageProvider);
              storage.whenData((s) async {
                await s.write(StorageKeys.onboardingComplete, '1');
                await s.write(StorageKeys.pwaInstalledAcknowledged, '1');
              });
              if (!mounted) return;
              context.go('/home');
            },
          ),
        ],
      ),
    );
  }
}