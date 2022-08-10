import 'dart:async';

import 'package:alarm_flutter/main.dart';
import 'package:alarm_flutter/models/schedule.dart';
import 'package:alarm_flutter/notifications/notifications_utils.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:alarm_flutter/widgets/analog_clock.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class AlarmTab extends StatefulWidget {
  const AlarmTab({Key? key}) : super(key: key);

  @override
  createState() => _AlarmTabState();
}

class _AlarmTabState extends State<AlarmTab>
    with AutomaticKeepAliveClientMixin {
  List<bool> isSelected = List.generate(
    2,
    (index) => index == 0, // Defaults to AM
    growable: false,
  );
  bool _isAlarmEnabled = false;
  int hour = 1;
  int minute = 0;
  Duration? diff;

  @override
  initState() {
    refresh();
    super.initState();

    var now = DateTime.now();
    var nextMinute =
        DateTime(now.year, now.month, now.day, now.hour, now.minute + 1);
    Timer(nextMinute.difference(now), () {
      Timer.periodic(const Duration(minutes: 1), (timer) {
        refresh();
      });
      refresh();
    });
  }

  @override
  bool get wantKeepAlive => true;

  _onTimeChange(int hour, int minute) {
    setState(() {
      this.hour = hour;
      this.minute = minute;
    });
  }

  refresh() {
    refreshAlarm();
    refreshSchedules();
    refreshDiff();
  }

  refreshAlarm() {
    var alarmBox = Hive.box(alarmBoxName);
    DateTime? scheduleTime = alarmBox.get("scheduleTime");
    if (scheduleTime != null) {
      if (scheduleTime.isAfter(DateTime.now())) {
        hour = scheduleTime.hour;
        if (hour > 12) {
          hour = hour % 12;
          if (hour == 0) {
            hour = 12;
          }
          isSelected[0] = false;
          isSelected[1] = true;
        }
        minute = scheduleTime.minute;
        _isAlarmEnabled = true;
        alarmBox.delete("scheduleTime");
      } else if (_isAlarmEnabled) {
        hour = 1;
        minute = 0;
        _isAlarmEnabled = false;
      }
    }
  }

  refreshDiff() {
    if (_isAlarmEnabled) {
      var dateTime = _getDateTime();
      setState(() {
        diff = dateTime.difference(DateTime.now());
      });
    } else {
      setState(() {
        diff = null;
      });
    }
  }

  refreshSchedules() {
    var alarmBox = Hive.box(alarmBoxName);
    var schedulesBox = Hive.box<Schedule>(schedulesBoxName);
    DateTime? reportDate = alarmBox.get('reportDate');
    DateTime todayDate = DateUtils.dateOnly(DateTime.now());
    if (reportDate != null) {
      if (!reportDate.isAtSameMomentAs(todayDate)) {
        alarmBox.put('reportDate', todayDate);
        // Clear reports for next day
        schedulesBox.clear();
      }
    } else {
      alarmBox.put('reportDate', todayDate);
    }
  }

  DateTime _getDateTime() {
    var now = DateTime.now();
    var dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      hour + (isSelected[1] ? 12 : 0),
      minute,
    );
    if (dateTime.difference(now).isNegative) {
      dateTime = dateTime.add(const Duration(days: 1));
    }
    return dateTime;
  }

  _onAlarmToggle() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    var isAllowed = await AwesomeNotifications()
        .isNotificationAllowed()
        .then((isAllowed) async {
      if (!isAllowed) {
        isAllowed =
            await AwesomeNotifications().requestPermissionToSendNotifications();
      }
      return isAllowed;
    });
    if (!isAllowed) {
      const snackBar = SnackBar(
        content: Text('Notification permission is required to turn on alarm'),
      );
      scaffoldMessenger.showSnackBar(snackBar);
    } else {
      var enabled = !_isAlarmEnabled;
      var alarmBox = Hive.box(alarmBoxName);
      if (enabled) {
        final scheduleTime = _getDateTime();
        await NotificationUtils.scheduleAlarm(
          scheduleTime,
          title: 'Alarm',
          body:
              'Notification was schedule to shows at ${DateFormat.jm().format(scheduleTime)}',
        );
        await alarmBox.put("scheduleTime", scheduleTime);
      } else {
        await AwesomeNotifications().dismissAllNotifications();
        await AwesomeNotifications().cancelAllSchedules();
        await alarmBox.put("scheduleTime", null);
      }
      setState(
        () {
          _isAlarmEnabled = enabled;
          refreshDiff();
        },
      );
    }
  }

  _buildMessage() {
    var message = "Please set your alarm below";
    if (diff != null) {
      message = "Alarm will go off in";
      var inHours = diff!.inHours;
      if (inHours > 0) {
        message += " $inHours ${inHours > 1 ? "hours" : "hour"}";
      }
      var inMinutes = diff!.inMinutes;
      var inSeconds = diff!.inSeconds;
      if (inSeconds > 0) {
        inMinutes += 1;
      }
      inMinutes = inMinutes.remainder(60);
      if (inMinutes > 0) {
        message += " $inMinutes ${inMinutes > 1 ? "minutes" : "minute"}";
      }
      if (inHours == 0 && inMinutes == 0 && inSeconds == 0) {
        message = "Your alarm is ringing";
      }
    }
    return Text(message);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RichText(
            text: TextSpan(
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.normal),
              children: [
                const TextSpan(text: 'Alarm is '),
                TextSpan(
                  text: _isAlarmEnabled ? 'ON' : 'OFF',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isAlarmEnabled ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 4,
          ),
          _buildMessage(),
          const SizedBox(
            height: 4,
          ),
          Expanded(
            child: AnalogClock(
              hour: hour,
              minute: minute,
              onChange: !_isAlarmEnabled ? _onTimeChange : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}",
                  style: Theme.of(context).textTheme.headline2?.copyWith(
                        color: Colors.white,
                      ),
                ),
                const SizedBox(
                  width: 24.0,
                ),
                ToggleButtons(
                  onPressed: (int index) {
                    if (!_isAlarmEnabled) {
                      setState(() {
                        for (int buttonIndex = 0;
                            buttonIndex < isSelected.length;
                            buttonIndex++) {
                          if (buttonIndex == index) {
                            isSelected[buttonIndex] = true;
                          } else {
                            isSelected[buttonIndex] = false;
                          }
                        }
                      });
                    }
                  },
                  isSelected: isSelected,
                  children: const [
                    Text(
                      'AM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'PM',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 24.0,
          ),
          TextButton(
            style: TextButton.styleFrom(
              primary: Colors.white,
              backgroundColor: _isAlarmEnabled ? Colors.red : Colors.green,
              minimumSize: const Size.fromHeight(50),
            ),
            onPressed: _onAlarmToggle,
            child: Text(_isAlarmEnabled ? "Turn Off Alarm" : "Turn On Alarm"),
          )
        ],
      ),
    );
  }
}
