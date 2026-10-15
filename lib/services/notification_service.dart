import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz_data.initializeTimeZones();
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_fitness'),
    );
    await _plugin.initialize(settings: settings);
  }

  static Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    final exactAllowed =
        await android?.canScheduleExactNotifications() ?? false;
    if (!exactAllowed) {
      await android?.requestExactAlarmsPermission();
    }
  }

  static Future<void> scheduleRestFinished() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'rest_timer',
        'Descanso do treino',
        channelDescription: 'Avisos quando o descanso entre séries terminar',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
    );
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final exactAllowed =
        await android?.canScheduleExactNotifications() ?? false;
    await _plugin.cancel(id: 1);
    await _plugin.zonedSchedule(
      id: 1,
      title: 'Descanso finalizado',
      body: 'Hora de começar a próxima série.',
      scheduledDate: tz.TZDateTime.now(tz.local)
          .add(const Duration(seconds: 60)),
      notificationDetails: details,
      androidScheduleMode: exactAllowed
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  static Future<void> cancelRestNotification() => _plugin.cancel(id: 1);
}
