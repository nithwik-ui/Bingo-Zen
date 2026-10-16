// Join Room screen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/zen_failure.dart';
import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/widgets/zen_widgets.dart';
import '../../matchmaking/application/matchmaking_repository.dart';
import 'room_code_input.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key, required this.kind});
  final String kind;

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final TextEditingController _code = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _join(String code) async {
    setState(() => _error = null);
    try {
      final repo = ref.read(roomsRepoProvider);
      await repo.joinByCode(code);
      if (!mounted) return;
      context.push('/waiting/join:$code');
    } on RoomFailure catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not join. Check the code.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZenSurfaces.background,
      appBar: AppBar(title: const Text('Join Room')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text('Enter Access Code', style: ZenTypography.headlineMd),
              const SizedBox(height: 8),
              Text(
                'Ask your host for their 6-character room code',
                style: ZenTypography.bodySm,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              RoomCodeInput(
                controller: _code,
                onSubmit: _join,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!,
                    style: ZenTypography.bodySm.copyWith(color: ZenAccent.error)),
              ],
              const SizedBox(height: 24),
              ZenButton(
                label: 'Join',
                icon: Icons.arrow_forward,
                expand: true,
                onPressed: () => _join(_code.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}