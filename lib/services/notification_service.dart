import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static const int _restFinishedId = 1;
  static const int _activeWorkoutId = 2;
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

  static Future<void> showActiveWorkout({
    required String exerciseName,
    required Duration elapsed,
  }) {
    final startedAt = DateTime.now().subtract(elapsed);
    return _showWorkoutNotification(
      title: exerciseName,
      body: 'Treino em execução',
      startedAt: startedAt,
    );
  }

  static Future<void> showPausedWorkout({
    required String exerciseName,
    required Duration elapsed,
  }) {
    return _plugin.show(
      id: _activeWorkoutId,
      title: exerciseName,
      body: 'Treino pausado • ${_formatDuration(elapsed)}',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'active_workout',
          'Treino em execução',
          channelDescription: 'Acompanhamento do treino atual',
          importance: Importance.low,
          priority: Priority.low,
          ongoing: true,
          autoCancel: false,
          onlyAlertOnce: true,
          playSound: false,
          enableVibration: false,
          showWhen: false,
        ),
      ),
    );
  }

  static Future<void> showRestProgress({
    required String exerciseName,
  }) {
    return _showWorkoutNotification(
      title: 'Descanso • $exerciseName',
      body: 'Tempo de descanso',
      startedAt: DateTime.now(),
    );
  }

  static Future<void> _showWorkoutNotification({
    required String title,
    required String body,
    required DateTime startedAt,
  }) {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'active_workout',
        'Treino em execução',
        channelDescription: 'Acompanhamento do treino atual',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        onlyAlertOnce: true,
        playSound: false,
        enableVibration: false,
        showWhen: true,
        when: startedAt.millisecondsSinceEpoch,
        usesChronometer: true,
        chronometerCountDown: false,
      ),
    );
    return _plugin.show(
      id: _activeWorkoutId,
      title: title,
      body: body,
      notificationDetails: details,
    );
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
    await _plugin.cancel(id: _restFinishedId);
    await _plugin.zonedSchedule(
      id: _restFinishedId,
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

  static Future<void> cancelRestNotification() =>
      _plugin.cancel(id: _restFinishedId);

  static Future<void> cancelWorkoutNotification() =>
      _plugin.cancel(id: _activeWorkoutId);

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }
}
