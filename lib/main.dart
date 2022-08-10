import 'package:alarm_flutter/models/schedule.dart';
import 'package:alarm_flutter/notifications/notification_controller.dart';
import 'package:alarm_flutter/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String alarmBoxName = "alarm";
const String schedulesBoxName = "schedules";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter<Schedule>(ScheduleAdapter());
  await Hive.openBox(alarmBoxName);
  await Hive.openBox<Schedule>(schedulesBoxName);
  NotificationsController.initializeLocalNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.green,
    );
    return MaterialApp(
      title: 'Alarm',
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          secondary: theme.primaryColor,
        ),
        toggleButtonsTheme: ToggleButtonsThemeData(
          selectedColor: theme.primaryColor,
          selectedBorderColor: theme.primaryColor,
          fillColor: theme.primaryColor.withOpacity(0.1),
          splashColor: theme.primaryColor.withOpacity(0.1),
        ),
        tabBarTheme: TabBarTheme(
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(width: 2.0, color: theme.primaryColor),
            insets: EdgeInsets.zero,
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}
