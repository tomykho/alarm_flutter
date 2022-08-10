import 'package:awesome_notifications/awesome_notifications.dart';

class NotificationUtils {
  static Future<bool> scheduleAlarm(
    DateTime scheduleTime, {
    String? title,
    String? body,
  }) {
    return AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 1,
        channelKey: 'alarm',
        title: title,
        body: body,
        wakeUpScreen: true,
        category: NotificationCategory.Alarm,
        payload: {
          "scheduleTime": scheduleTime.toIso8601String(),
        },
        displayOnBackground: true,
        displayOnForeground: true,
        autoDismissible: false,
      ),
      schedule: NotificationCalendar.fromDate(date: scheduleTime),
    );
  }
}
