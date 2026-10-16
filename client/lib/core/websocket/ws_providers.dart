// Shared WebSocket transport provider for match screens.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'websocket_transport.dart';

/// Provides a transport instance for a given match id.
final wsTransportProvider = Provider.family<WebSocketTransport, String>(
  (ref, matchId) {
    final transport = WebSocketTransport(url: 'ws://localhost/match/$matchId');
    ref.onDispose(() => transport.close());
    return transport;
  },
);