import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'services/alarm_ringer.dart';
import 'services/clock_store.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final NotificationService notifications = NotificationService.instance;
  await notifications.init();

  final AlarmRinger ringer = AlarmRinger(notifications.strings);
  await ringer.init();

  final ClockStore store = ClockStore(notifications, ringer);
  await store.load();

  runApp(MonogatariApp(
    store: store,
    notifications: notifications,
    ringer: ringer,
  ));
}
