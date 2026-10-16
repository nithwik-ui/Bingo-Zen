// Helper provider exposing the current room by id (used by waiting room).
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/room.dart';

class RoomController extends Notifier<Room?> {
  RoomController(this._roomId);
  final String _roomId;

  @override
  Room? build() => null;
  void update(Room? room) {
    state = room;
  }
}

final roomControllerProvider =
    NotifierProvider.family<RoomController, Room?, String>(
  RoomController.new,
);