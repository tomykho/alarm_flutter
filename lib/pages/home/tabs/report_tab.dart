import 'package:alarm_flutter/main.dart';
import 'package:alarm_flutter/models/schedule.dart';
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class ReportTab extends StatefulWidget {
  const ReportTab({Key? key}) : super(key: key);

  @override
  createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    var alarmBox = Hive.box(alarmBoxName);
    DateTime reportDate = alarmBox.get(
      "reportDate",
      defaultValue: DateTime.now(),
    );
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Wake up report",
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.normal),
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 6.0,
          ),
          Text(
            "For ${DateFormat.yMMMMd().format(reportDate)}",
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 12.0,
          ),
          Text(
            "Duration in seconds",
            style: Theme.of(context).textTheme.caption,
          ),
          Expanded(
            child: ValueListenableBuilder<Box<Schedule>>(
              valueListenable:
                  Hive.box<Schedule>(schedulesBoxName).listenable(),
              builder: (context, box, _) {
                return charts.BarChart(
                  [
                    charts.Series<Schedule, String>(
                      id: 'Schedule',
                      domainFn: (Schedule s, _) =>
                          DateFormat.jm().format(s.scheduleTime),
                      measureFn: (Schedule s, _) => s.durationInSeconds,
                      colorFn: (_, __) =>
                          charts.MaterialPalette.green.shadeDefault,
                      data: box.values.toList(),
                    ),
                  ],
                  animate: true,
                  primaryMeasureAxis: charts.NumericAxisSpec(
                    renderSpec: charts.GridlineRendererSpec(
                      labelStyle: const charts.TextStyleSpec(
                        color: charts.MaterialPalette.white,
                      ),
                      lineStyle: charts.LineStyleSpec(
                        color: charts.MaterialPalette.gray.shadeDefault,
                      ),
                    ),
                  ),
                  domainAxis: charts.OrdinalAxisSpec(
                    viewport: charts.OrdinalViewport('12:00 AM', 4),
                    renderSpec: charts.SmallTickRendererSpec(
                      labelStyle: const charts.TextStyleSpec(
                        color: charts.MaterialPalette.white,
                      ),
                      lineStyle: charts.LineStyleSpec(
                        color: charts.MaterialPalette.gray.shadeDefault,
                      ),
                    ),
                  ),
                  behaviors: [
                    charts.SlidingViewport(),
                    charts.PanAndZoomBehavior(),
                  ],
                );
              },
            ),
          ),
          Text(
            "Alarm time",
            style: Theme.of(context).textTheme.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
