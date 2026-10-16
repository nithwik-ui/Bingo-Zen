// Notification service — non-blocking, optional. The app must remain fully
// functional when notifications are denied or disabled.
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

abstract class NotificationsService {
  Future<bool> requestPermission();
  Future<void> show({
    required String title,
    required String body,
    String? payload,
  });
}

class NoOpNotifications implements NotificationsService {
  const NoOpNotifications();
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> show(
      {required String title,
      required String body,
      String? payload}) async {}
}

final Provider<NotificationsService> notificationsProvider =
    Provider<NotificationsService>((_) => const NoOpNotifications());