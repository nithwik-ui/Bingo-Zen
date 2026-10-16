// WebSocket transport layer. Provides:
//   - Auto-reconnect with exponential backoff
//   - Heartbeat ping every 20s (configurable)
//   - Stale-connection detection (missed 2 pongs)
//   - Outgoing message queue while disconnected
//   - Sequence number tracking
//   - Duplicate-event protection
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/websocket_envelope.dart';

class WsConnectionState {
  const WsConnectionState({
    required this.connected,
    required this.lastEventId,
    required this.lastSequence,
    required this.lastServerTimestamp,
    this.attempts = 0,
    this.error,
  });

  final bool connected;
  final String? lastEventId;
  final int lastSequence;
  final int lastServerTimestamp;
  final int attempts;
  final Object? error;

  WsConnectionState copyWith({
    bool? connected,
    String? lastEventId,
    int? lastSequence,
    int? lastServerTimestamp,
    int? attempts,
    Object? error,
  }) {
    return WsConnectionState(
      connected: connected ?? this.connected,
      lastEventId: lastEventId ?? this.lastEventId,
      lastSequence: lastSequence ?? this.lastSequence,
      lastServerTimestamp: lastServerTimestamp ?? this.lastServerTimestamp,
      attempts: attempts ?? this.attempts,
      error: error,
    );
  }
}

typedef EventHandler = void Function(WsEvent event);

class WebSocketTransport {
  WebSocketTransport({
    required this.url,
    this.heartbeatIntervalMs = 20000,
    this.maxBackoffMs = 30000,
    this.staleAfterMissedPongs = 2,
  });

  final String url;
  final int heartbeatIntervalMs;
  final int maxBackoffMs;
  final int staleAfterMissedPongs;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  Timer? _heartbeatTimer;
  Timer? _reconnectTimer;
  bool _disposed = false;
  int _missedPongs = 0;
  int _attempts = 0;
  final Random _rng = Random();
  final Map<String, WsEvent> _seen = <String, WsEvent>{};
  final List<String> _pendingOutgoing = <String>[];
  String? _lastEventId;
  int _lastSequence = 0;
  int _lastServerTimestamp = 0;
  bool _connected = false;

  // Public event stream.
  final StreamController<WsEvent> _eventsCtrl =
      StreamController<WsEvent>.broadcast();
  final StreamController<WsConnectionState> _stateCtrl =
      StreamController<WsConnectionState>.broadcast();

  Stream<WsEvent> get events => _eventsCtrl.stream;
  Stream<WsConnectionState> get state => _stateCtrl.stream;
  bool get isConnected => _connected;
  WsConnectionState snapshotState() => WsConnectionState(
        connected: _connected,
        lastEventId: _lastEventId,
        lastSequence: _lastSequence,
        lastServerTimestamp: _lastServerTimestamp,
        attempts: _attempts,
      );

  Future<void> connect() async {
    if (_disposed) return;
    _emitState();
    _openOnce();
  }

  Future<void> _openOnce() async {
    try {
      _channel = IOWebSocketChannel.connect(
        Uri.parse(url),
        pingInterval: Duration(milliseconds: heartbeatIntervalMs),
      );
      _sub = _channel!.stream.listen(_onRaw,
          onError: _onError, onDone: _onDone, cancelOnError: false);
      _connected = true;
      _attempts = 0;
      _emitState();
      _flushPending();
      _startHeartbeat();
    } catch (e) {
      _onError(e);
    }
  }

  void _onRaw(dynamic raw) {
    if (raw is! String) return;
    try {
      final Map<String, dynamic> json =
          jsonDecode(raw) as Map<String, dynamic>;
      final WsEvent event = WsEvent.fromJson(json);
      _lastEventId = event.eventId;
      _lastSequence = event.sequenceNumber;
      _lastServerTimestamp = event.serverTimestamp;
      if (_seen.containsKey(event.eventId)) {
        // Duplicate — drop.
        return;
      }
      _seen[event.eventId] = event;
      if (_seen.length > 500) {
        // Trim old entries to bound memory.
        final List<String> firstKeys = _seen.keys.take(100).toList();
        for (final String k in firstKeys) {
          _seen.remove(k);
        }
      }
      if (event.eventType == WsEvents.heartbeat) {
        _missedPongs = 0;
        return;
      }
      _eventsCtrl.add(event);
      _emitState();
    } catch (_) {
      // Malformed payload — server is authoritative; ignore.
    }
  }

  void _onError(Object e) {
    _connected = false;
    _emitState(error: e);
    _scheduleReconnect();
  }

  void _onDone() {
    _connected = false;
    _emitState();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _heartbeatTimer?.cancel();
    _attempts += 1;
    final int backoffMs = min(
      maxBackoffMs,
      (1000 * (1 << (_attempts.clamp(0, 5)))).toInt() + _rng.nextInt(500),
    );
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(milliseconds: backoffMs), _openOnce);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: heartbeatIntervalMs),
      (_) {
        if (!_connected) return;
        _missedPongs += 1;
        if (_missedPongs >= staleAfterMissedPongs) {
          // Stale connection — force reconnect.
          try {
            _channel?.sink.close(ws_status.normalClosure);
          } catch (_) {}
          _onError('Stale connection');
          return;
        }
        _sendRaw({
          'eventType': WsEvents.heartbeat,
          'clientTimestamp': DateTime.now().millisecondsSinceEpoch,
        });
      },
    );
  }

  void _flushPending() {
    if (_pendingOutgoing.isEmpty) return;
    final List<String> copy = List<String>.from(_pendingOutgoing);
    _pendingOutgoing.clear();
    for (final String raw in copy) {
      _sendRaw(_decode(raw));
    }

  }

  Map<String, dynamic> _decode(String raw) =>
      jsonDecode(raw) as Map<String, dynamic>;

  void _sendRaw(Map<String, dynamic> body) {
    if (!_connected || _channel == null) {
      _pendingOutgoing.add(jsonEncode(body));
      return;
    }
    try {
      _channel!.sink.add(jsonEncode(body));
    } catch (_) {
      _pendingOutgoing.add(jsonEncode(body));
    }
  }

  /// Send a typed event. Caller provides eventType + payload; transport
  /// fills eventId / sequenceNumber / serverTimestamp with placeholders that
  /// the server may overwrite (server is authoritative on these fields).
  void send({required String eventType, Map<String, dynamic>? payload}) {
    final Map<String, dynamic> body = {
      'eventId': 'c-${DateTime.now().microsecondsSinceEpoch}-$_attempts',
      'matchId': null,
      'sequenceNumber': ++_lastSequence,
      'serverTimestamp': 0,
      'eventType': eventType,
      'payload': payload ?? const <String, dynamic>{},
    };
    _sendRaw(body);
  }

  void _emitState({Object? error}) {
    if (_stateCtrl.isClosed) return;
    _stateCtrl.add(WsConnectionState(
      connected: _connected,
      lastEventId: _lastEventId,
      lastSequence: _lastSequence,
      lastServerTimestamp: _lastServerTimestamp,
      attempts: _attempts,
      error: error,
    ));
  }

  Future<void> close() async {
    _disposed = true;
    _heartbeatTimer?.cancel();
    _reconnectTimer?.cancel();
    await _sub?.cancel();
    try {
      await _channel?.sink.close(ws_status.normalClosure);
    } catch (_) {}
    _eventsCtrl.close();
    _stateCtrl.close();
  }
}