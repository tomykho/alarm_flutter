import 'package:alarm_flutter/main.dart';
import 'package:alarm_flutter/models/schedule.dart';
import 'package:alarm_flutter/pages/home/tabs/alarm_tab.dart';
import 'package:alarm_flutter/pages/home/tabs/report_tab.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final tabs = [
    const Tab(icon: Icon(Icons.more_time)),
    const Tab(icon: Icon(Icons.bar_chart)),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: tabs.length);

    AwesomeNotifications().actionStream.listen(
      (ReceivedNotification receivedNotification) {
        if (receivedNotification.channelKey == "alarm") {
          var payload = receivedNotification.payload;
          if (payload != null && payload["scheduleTime"] != null) {
            var scheduleTime = DateTime.parse(payload["scheduleTime"]!);
            var diff = DateTime.now().difference(scheduleTime);
            var schedulesBox = Hive.box<Schedule>(schedulesBoxName);
            schedulesBox.add(Schedule(scheduleTime, diff.inSeconds));
            _tabController?.animateTo(1);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: SafeArea(
          child: TabBar(
            controller: _tabController,
            tabs: tabs,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          AlarmTab(),
          ReportTab(),
        ],
      ),
    );
  }
}
