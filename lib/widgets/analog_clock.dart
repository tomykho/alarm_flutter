import 'package:flutter/material.dart';
import 'package:touchable/touchable.dart';
import 'dart:math';
import 'package:flutter/services.dart';

const double baseSize = 320.0;
const double strokeWidth = 8.0;
const double handPinSize = 8.0;

class AnalogClock extends StatefulWidget {
  final int hour;
  final int minute;
  final double width;
  final double height;
  final Function(int hour, int minute)? onChange;

  const AnalogClock({
    required this.hour,
    required this.minute,
    this.width = double.infinity,
    this.height = double.infinity,
    this.onChange,
    Key? key,
  }) : super(key: key);

  @override
  createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  AnalogClockHand? pannedClockHand;

  _AnalogClockState();

  @override
  initState() {
    super.initState();
  }

  void _onClockHandPanUpdate(
    DragUpdateDetails d,
    AnalogClockHand hand,
    double radius,
  ) {
    if (pannedClockHand == hand && widget.onChange != null) {
      var horizontalPos = AnalogClockHandHorizontalPosition.center;
      if (d.localPosition.dy < radius) {
        horizontalPos = AnalogClockHandHorizontalPosition.top;
      } else if (d.localPosition.dy > radius) {
        horizontalPos = AnalogClockHandHorizontalPosition.bottom;
      }
      var verticalPos = AnalogClockHandVerticalPosition.center;
      if (d.localPosition.dx < radius) {
        verticalPos = AnalogClockHandVerticalPosition.left;
      } else if (d.localPosition.dx > radius) {
        verticalPos = AnalogClockHandVerticalPosition.right;
      }

      List<AnalogClockHandPanDirection> panDirections = [];
      if (d.delta.dy < 0) {
        panDirections.add(AnalogClockHandPanDirection.top);
      } else if (d.delta.dy > 0) {
        panDirections.add(AnalogClockHandPanDirection.bottom);
      }
      if (d.delta.dx < 0) {
        panDirections.add(AnalogClockHandPanDirection.left);
      } else if (d.delta.dx > 0) {
        panDirections.add(AnalogClockHandPanDirection.right);
      }

      double dx = d.delta.dx.abs();
      double dy = d.delta.dy.abs();

      if (horizontalPos == AnalogClockHandHorizontalPosition.top &&
              panDirections.contains(AnalogClockHandPanDirection.left) ||
          horizontalPos == AnalogClockHandHorizontalPosition.bottom &&
              panDirections.contains(AnalogClockHandPanDirection.right)) {
        dx = -dx;
      }

      if (verticalPos == AnalogClockHandVerticalPosition.right &&
              panDirections.contains(AnalogClockHandPanDirection.top) ||
          verticalPos == AnalogClockHandVerticalPosition.left &&
              panDirections.contains(AnalogClockHandPanDirection.bottom)) {
        dy = -dy;
      }

      double diff = dx + dy;
      int hour = widget.hour;
      int minute = widget.minute;
      if (diff > 0) {
        // Increase
        if (pannedClockHand == AnalogClockHand.hour) {
          hour++;
        } else {
          minute++;
        }
      } else if (diff < 0) {
        // Decrease
        if (pannedClockHand == AnalogClockHand.hour) {
          hour--;
        } else {
          minute--;
        }
      }

      hour = hour % 12;
      if (hour == 0) {
        hour = 12;
      }
      minute = minute % 60;

      widget.onChange!(hour, minute);
      SystemSound.play(SystemSoundType.click);
    }
  }

  _onClockHandPanStart(DragStartDetails d, AnalogClockHand hand) {
    pannedClockHand = hand;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _AnalogClockFramePainter(
                hour: widget.hour,
                minute: widget.minute,
              ),
            ),
            CanvasTouchDetector(
              gesturesToOverride: const [
                GestureType.onPanUpdate,
                GestureType.onPanStart,
              ],
              builder: (context) => CustomPaint(
                painter: _AnalogClockHandPainter(
                  context,
                  hour: widget.hour,
                  minute: widget.minute,
                  onClockHandPanUpdate: _onClockHandPanUpdate,
                  onClockHandPanStart: _onClockHandPanStart,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalogClockFramePainter extends CustomPainter {
  final Color tickColor = Colors.grey;
  final Color numberColor = Colors.white;
  final double textScaleFactor = 1.0;
  final int hour;
  final int minute;

  _AnalogClockFramePainter({
    required this.hour,
    required this.minute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double scaleFactor = size.shortestSide / baseSize;
    _paintTickMarks(canvas, size, scaleFactor);
    _drawIndicators(canvas, size, scaleFactor);
    _paintPin(canvas, size, scaleFactor);
  }

  @override
  bool shouldRepaint(_AnalogClockFramePainter oldDelegate) {
    return oldDelegate.hour != hour || oldDelegate.minute != minute;
  }

  _paintPin(Canvas canvas, size, scaleFactor) {
    Paint midPointStrokePainter = Paint()
      ..color = numberColor
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      size.center(Offset.zero),
      (handPinSize + 2.0) * scaleFactor,
      midPointStrokePainter,
    );
  }

  void _drawIndicators(Canvas canvas, Size size, double scaleFactor) {
    TextStyle style = TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 18.0 * scaleFactor * textScaleFactor);
    double p = 12.0;
    p += 24.0;
    double r = size.shortestSide / 2;
    double longHandLength = r - (p * scaleFactor);

    for (var h = 1; h <= 12; h++) {
      double angle = (h * pi / 6) - pi / 2; //+ pi / 2;
      Offset offset =
          Offset(longHandLength * cos(angle), longHandLength * sin(angle));

      TextSpan span = TextSpan(
        style: style.copyWith(
          color: hour == h ? Colors.green : numberColor,
        ),
        text: h.toString(),
      );
      TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, size.center(offset - tp.size.center(Offset.zero)));
    }
  }

  void _paintTickMarks(Canvas canvas, Size size, double scaleFactor) {
    double r = size.shortestSide / 2;
    double tick = 5 * scaleFactor, longTick = 3.0 * tick;
    Paint tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 2.0 * scaleFactor;
    for (int i = 0; i < 60; i++) {
      double len = tick;
      if (i % 5 == 0) {
        len = longTick;
      }

      double degrees = (i / 60) * 360;
      double radians = degrees * (-pi / 180);
      radians = -pi / 2.0 - radians; // Rotate to make it start from top

      double x1 = r * cos(radians);
      double y1 = r * sin(radians);

      double x2 = (r - len) * cos(radians);
      double y2 = (r - len) * sin(radians);

      canvas.drawLine(
        size.center(Offset(x1, y1)),
        size.center(Offset(x2, y2)),
        tickPaint..color = minute == i ? Colors.green : tickColor,
      );
    }
  }
}

class _AnalogClockHandPainter extends CustomPainter {
  final BuildContext context;
  final int hour;
  final int minute;
  final Function(DragStartDetails d, AnalogClockHand hand)? onClockHandPanStart;
  final Function(DragUpdateDetails d, AnalogClockHand hand, double radius)?
      onClockHandPanUpdate;

  _AnalogClockHandPainter(
    this.context, {
    required this.hour,
    required this.minute,
    this.onClockHandPanStart,
    this.onClockHandPanUpdate,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double scaleFactor = size.shortestSide / baseSize;
    _paintClockHands(canvas, size, scaleFactor);
  }

  @override
  bool shouldRepaint(_AnalogClockHandPainter oldDelegate) {
    return oldDelegate.hour != hour || oldDelegate.minute != minute;
  }

  void _paintClockHands(Canvas canvas, Size size, double scaleFactor) {
    double r = size.shortestSide / 2;
    double p = 64.0;
    double longHandLength = r - (p * scaleFactor);
    double shortHandLength = r - (p + 36.0) * scaleFactor;

    Paint handPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.bevel
      ..strokeWidth = strokeWidth * scaleFactor
      ..color = Colors.white;

    var myCanvas = TouchyCanvas(context, canvas);

    double minuteDegrees = (minute / 60) * 360;
    double minuteRadians = minuteDegrees * (-pi / 180);
    minuteRadians = -pi / 2.0 - minuteRadians;
    myCanvas.drawLine(
      size.center(Offset.zero),
      size.center(
        Offset(
          longHandLength * cos(minuteRadians),
          longHandLength * sin(minuteRadians),
        ),
      ),
      handPaint,
      onPanUpdate: (d) {
        if (onClockHandPanUpdate != null) {
          onClockHandPanUpdate!(d, AnalogClockHand.minute, r);
        }
      },
      onPanStart: (d) {
        if (onClockHandPanStart != null) {
          onClockHandPanStart!(d, AnalogClockHand.minute);
        }
      },
    );

    double hourDegrees = (hour / 12) * 360;
    double hourRadians = hourDegrees * (-pi / 180);
    hourRadians = -pi / 2.0 - hourRadians;
    myCanvas.drawLine(
      size.center(Offset.zero),
      size.center(
        Offset(
          shortHandLength * cos(hourRadians),
          shortHandLength * sin(hourRadians),
        ),
      ),
      handPaint,
      onPanUpdate: (d) {
        if (onClockHandPanUpdate != null) {
          onClockHandPanUpdate!(d, AnalogClockHand.hour, r);
        }
      },
      onPanStart: (d) {
        if (onClockHandPanStart != null) {
          onClockHandPanStart!(d, AnalogClockHand.hour);
        }
      },
    );
  }
}

enum AnalogClockHand {
  hour,
  minute,
}

enum AnalogClockHandVerticalPosition {
  right,
  left,
  center,
}

enum AnalogClockHandHorizontalPosition {
  top,
  bottom,
  center,
}

enum AnalogClockHandPanDirection {
  top,
  bottom,
  right,
  left,
}
