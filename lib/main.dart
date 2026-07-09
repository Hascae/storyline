import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/clock_store.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final NotificationService notifications = NotificationService.instance;
  await notifications.init();

  final ClockStore store = ClockStore(notifications);
  await store.load();

  final int? ringAlarmId = await notifications.launchedByAlarm();

  runApp(MonogatariApp(
    store: store,
    notifications: notifications,
    initialRingAlarmId: ringAlarmId,
  ));
}
