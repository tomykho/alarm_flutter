import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationsController {
  static Future<void> initializeLocalNotifications() async {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'alarm',
          channelName: 'Alarm notifications',
          channelDescription: 'Notification channel for alarm',
          playSound: true,
          enableLights: true,
          enableVibration: true,
          defaultRingtoneType: DefaultRingtoneType.Alarm,
          importance: NotificationImportance.Max,
        )
      ],
      debug: true,
    );
  }
}
