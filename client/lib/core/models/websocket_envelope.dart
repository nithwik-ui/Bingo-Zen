// WebSocket event envelope — shared between client and server.
//
// Every event MUST carry:
//   - eventId: unique id for duplicate-event protection
//   - matchId: identifies the match context
//   - sequenceNumber: monotonic per match, used to detect out-of-order / stale
//   - serverTimestamp: epoch ms, used for client clock-sync
//   - eventType: typed message discriminator
//   - payload: opaque JSON-serializable body
import 'dart:convert';

class WsEvent {
  const WsEvent({
    required this.eventId,
    required this.matchId,
    required this.sequenceNumber,
    required this.serverTimestamp,
    required this.eventType,
    required this.payload,
  });

  final String eventId;
  final String? matchId;
  final int sequenceNumber;
  final int serverTimestamp;
  final String eventType;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toJson() => {
        'eventId': eventId,
        'matchId': matchId,
        'sequenceNumber': sequenceNumber,
        'serverTimestamp': serverTimestamp,
        'eventType': eventType,
        'payload': payload,
      };

  factory WsEvent.fromJson(Map<String, dynamic> json) => WsEvent(
        eventId: json['eventId'] as String,
        matchId: json['matchId'] as String?,
        sequenceNumber: (json['sequenceNumber'] as num).toInt(),
        serverTimestamp: (json['serverTimestamp'] as num).toInt(),
        eventType: json['eventType'] as String,
        payload: Map<String, dynamic>.from(json['payload'] as Map),
      );

  String encode() => jsonEncode(toJson());

  factory WsEvent.decode(String raw) =>
      WsEvent.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// All event-type discriminators.
class WsEvents {
  WsEvents._();
  // Match lifecycle.
  static const String matchFound = 'MATCH_FOUND';
  static const String gameStart = 'GAME_START';
  static const String gameFinished = 'GAME_FINISHED';

  // Per-move updates.
  static const String turnChanged = 'TURN_CHANGED';
  static const String numberSelected = 'NUMBER_SELECTED';
  static const String numberMarked = 'NUMBER_MARKED';
  static const String lineCompleted = 'LINE_COMPLETED';
  static const String scoreUpdated = 'SCORE_UPDATED';

  // Player presence.
  static const String playerConnected = 'PLAYER_CONNECTED';
  static const String playerDisconnected = 'PLAYER_DISCONNECTED';
  static const String playerReconnected = 'PLAYER_RECONNECTED';

  // State synchronization.
  static const String gameStateSync = 'GAME_STATE_SYNC';

  // Rematch.
  static const String rematchRequest = 'REMATCH_REQUEST';
  static const String rematchAccepted = 'REMATCH_ACCEPTED';
  static const String rematchExpired = 'REMATCH_EXPIRED';

  // Other.
  static const String opponentLeft = 'OPPONENT_LEFT';
  static const String roomCreated = 'ROOM_CREATED';
  static const String roomJoined = 'ROOM_JOINED';
  static const String roomExpired = 'ROOM_EXPIRED';
  static const String friendRequest = 'FRIEND_REQUEST';
  static const String friendAccepted = 'FRIEND_ACCEPTED';

  // Acknowledgement from server.
  static const String ack = 'ACK';
  static const String error = 'ERROR';
  static const String heartbeat = 'HEARTBEAT';
}