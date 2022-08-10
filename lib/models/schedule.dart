import 'package:hive_flutter/hive_flutter.dart';

part 'schedule.g.dart';

@HiveType(typeId: 0)
class Schedule extends HiveObject {
  @HiveField(0)
  DateTime scheduleTime;
  @HiveField(1)
  int durationInSeconds;

  Schedule(this.scheduleTime, this.durationInSeconds);
}
