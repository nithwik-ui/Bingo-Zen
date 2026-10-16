// Create room screen — produces QR code + share link + waiting flow.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/zen_colors.dart';
import '../../../core/theme/zen_typography.dart';
import '../../../shared/models/enums.dart';
import '../../../shared/models/room.dart';
import '../../../shared/widgets/zen_widgets.dart';
import '../../matchmaking/application/matchmaking_repository.dart';
import 'room_provider.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key, required this.kind});
  final String kind;

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  Room? _room;
  String? _error;

  @override
  void initState() {
    super.initState();
    _create();
  }

  Future<void> _create() async {
    try {
      final repo = ref.read(roomsRepoProvider);
      final kind = widget.kind == 'sos' ? GameKind.sos : GameKind.bingo;
      final r = await repo.create(kind);
      setState(() => _room = r);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZenSurfaces.background,
      appBar: AppBar(title: const Text('Create Room')),
      body: SafeArea(
        child: _room == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : ZenErrorView(
                        title: 'Could not create room',
                        message: _error,
                        onRetry: _create,
                      ),
              )
            : Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ZenStatusChip(
                      label: 'Waiting for opponent',
                      background: Color(0x336CF8BB),
                      foreground: ZenAccent.onSecondaryContainer,
                      leadingDotColor: ZenAccent.secondary,
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text('Code: #${_room!.code}',
                          style: ZenTypography.headlineLg),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ZenSurfaces.card,
                        borderRadius: BorderRadius.circular(20),
                        border: const Border.fromBorderSide(
                                BorderSide(color: ZenOutline.hairline)),
                      ),
                      child: QrImageView(
                        data: AppConfig.roomDeepLink(_room!.code),
                        size: 200,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ZenButton(
                      label: 'Copy invite link',
                      icon: Icons.link,
                      variant: ZenButtonVariant.secondary,
                      expand: true,
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: AppConfig.roomDeepLink(_room!.code)),
                        );
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invite link copied')),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    ZenButton(
                      label: 'Waiting Room',
                      icon: Icons.hourglass_top,
                      expand: true,
                      onPressed: () => context.push('/waiting/${_room!.id}'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}