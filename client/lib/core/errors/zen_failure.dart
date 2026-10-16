// Domain-level error types. UI uses these to render meaningful empty states.
sealed class ZenFailure implements Exception {
  const ZenFailure(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

class NetworkFailure extends ZenFailure {
  const NetworkFailure(super.message, {super.cause});
}

class TimeoutFailure extends ZenFailure {
  const TimeoutFailure(super.message, {super.cause});
}

class ServerFailure extends ZenFailure {
  const ServerFailure(super.message, {this.statusCode, super.cause});
  final int? statusCode;
}

class UnauthorizedFailure extends ZenFailure {
  const UnauthorizedFailure(super.message, {super.cause});
}

class InvalidMoveFailure extends ZenFailure {
  const InvalidMoveFailure(super.message, {this.code, super.cause});
  final String? code;
}

class RoomFailure extends ZenFailure {
  const RoomFailure(super.message, {this.code, super.cause});
  final String? code;
}

class MatchFailure extends ZenFailure {
  const MatchFailure(super.message, {this.code, super.cause});
  final String? code;
}

class OfflineFailure extends ZenFailure {
  const OfflineFailure([super.message = 'You appear to be offline.']);
}

class UnknownFailure extends ZenFailure {
  const UnknownFailure(super.message, {super.cause});
}