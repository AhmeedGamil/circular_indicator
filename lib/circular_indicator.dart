import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math';

class CircularIndicator extends StatefulWidget {
  Color backgroundColor;
  Color indicatorColor;
  double strokeWidth;
  double animationTime;
  int raduis;
  bool isAnimated;
  CircularIndicator(
      {this.raduis = 100,
        this.backgroundColor = Colors.grey,
        this.indicatorColor = Colors.red,
        this.strokeWidth = 30,
        this.isAnimated = true,
        this.animationTime = 1});

  @override
  State<CircularIndicator> createState() => _CircularIndicatorState();
}

class _CircularIndicatorState extends State<CircularIndicator> {
  double _rotationAngle = 0;
  double _lastAngle = 0;
  double percent = 0;
  late List<double> fourthQuarterPoints = [];
  late List<double> firstQuarterPoints = [];
  late List<double> secondQuarterPoints = [];
  late List<double> thirdQuarterPoints = [];
  Float32List? allPointsListFloat;
  int counter = 0;
  double pointsPerFrame = 0;
  double endPointsPerFrame = 0;
  GlobalKey canvasKey = GlobalKey();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    drawCircularBackground();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: (widget.raduis * 2),
        height: (widget.raduis * 2),
        //color: Colors.grey[100],
        child: (allPointsListFloat != null)
            ? LayoutBuilder(builder: (context, constraints) {
          Size canvasSize =
          Size(constraints.maxWidth, constraints.maxHeight);
          return RepaintBoundary(
              key: canvasKey,
              child: CustomPaint(
                painter: PaintBackground(
                  allPointsListFloat!,
                  backgroundColor: widget.backgroundColor,
                ),
                child: DrawIndicator(
                    offsetListFloat: allPointsListFloat!,
                    indicatorColor: widget.indicatorColor,
                    animationTime: widget.animationTime,
                    isAnimated: widget.isAnimated,
                    canvasSize: canvasSize),
                size: canvasSize,
              ));
        })
            : Container());
  }

  void drawCircularBackground() {
    double raduis = widget.raduis - 1; // this because the stroke width of custom painter is 2 which make the size of circle when drawing raduis+1
    _rotationAngle = 360 / (raduis * 2 * pi);
    if (_lastAngle < 90) {
      for (double currentAngle = 0;
      currentAngle < 90;
      currentAngle = currentAngle + _rotationAngle) {
        Offset offset = new Offset((cos(currentAngle * pi / 180) * raduis),
            (sin(currentAngle * pi / 180) * raduis));

        fourthQuarterPoints.add(offset.dx);
        fourthQuarterPoints.add(offset.dy);
        Offset normal = getNormalVectorOfPoint(offset);
        fourthQuarterPoints.addAll(addStrokeWidth(normal, false));

        Offset thirdHalfOffset = offset.translate(-offset.dx * 2, 0);

        thirdQuarterPoints.add(thirdHalfOffset.dy);
        thirdQuarterPoints.add(thirdHalfOffset.dx);
        thirdQuarterPoints.addAll(
            addStrokeWidth(getNormalVectorOfPoint(thirdHalfOffset), true));

        Offset secondHalfOffset = -normal * raduis;
        secondQuarterPoints.add(secondHalfOffset.dx);
        secondQuarterPoints.add(secondHalfOffset.dy);
        secondQuarterPoints.addAll(
            addStrokeWidth(getNormalVectorOfPoint(secondHalfOffset), false));

        Offset firstHalfOffset =
            -getNormalVectorOfPoint(thirdHalfOffset) * raduis;
        firstQuarterPoints.add(firstHalfOffset.dy);
        firstQuarterPoints.add(firstHalfOffset.dx);
        firstQuarterPoints.addAll(
            addStrokeWidth(getNormalVectorOfPoint(firstHalfOffset), true));

        _lastAngle += _rotationAngle;
      }
    }
    if (_lastAngle >= 90) {
      allPointsListFloat = Float32List.fromList([
        ...firstQuarterPoints.reversed,
        ...fourthQuarterPoints,
        ...thirdQuarterPoints.reversed,
        ...secondQuarterPoints
      ]);
      print(allPointsListFloat!.length);
      firstQuarterPoints.clear();
      secondQuarterPoints.clear();
      thirdQuarterPoints.clear();
      fourthQuarterPoints.clear();
    }
  }

  List<double> addStrokeWidth(Offset normal, bool reverse) {
    List<double> offsetList = [];
    Offset offset;
    double strokeWidthPoint;
    for (double i = 1; i <= widget.strokeWidth; i += 1) {
      strokeWidthPoint = ((widget.raduis - 1) - i);
      offset = new Offset(
          (normal.dx * strokeWidthPoint), (normal.dy * strokeWidthPoint));
      if (reverse) {
        offsetList.add(offset.dy);
        offsetList.add(offset.dx);
      } else {
        offsetList.add(offset.dx);
        offsetList.add(offset.dy);
      }
    }
    return offsetList;
  }

  Offset getNormalVectorOfPoint(Offset offset) {
    double magnitude = sqrt(offset.dx * offset.dx + offset.dy * offset.dy);
    return Offset(offset.dx / magnitude, offset.dy / magnitude);
  }
}

class DrawIndicator extends StatefulWidget {
  DrawIndicator(
      {super.key,
        required this.offsetListFloat,
        required this.canvasSize,
        required this.isAnimated,
        required this.animationTime,
        required this.indicatorColor});

  final canvasSize;
  Float32List offsetListFloat;
  bool isAnimated;
  double animationTime;
  Color indicatorColor;
  @override
  State<DrawIndicator> createState() => _DrawIndicatorState();
}

class _DrawIndicatorState extends State<DrawIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double startPointsPerFrame = 0;
  double endPointsPerFrame = 0;
  ui.Image? savedImage;
  bool isDrawing = false;
  bool isPainted = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.isAnimated) {
      _controller = AnimationController(
        vsync: this,
        animationBehavior: AnimationBehavior.normal,
        duration: Duration(
            milliseconds: (widget.animationTime != 0)
                ? ((widget.animationTime * 1000).toInt())
                : 1),
        upperBound: 1, // Highest value
      )
        ..repeat();
    }
    else
    {_controller = AnimationController(
        vsync: this,
        animationBehavior: AnimationBehavior.normal,
        duration: Duration.zero
    );
    }
  }

  void update(Size size) async {
    if (isPainted) {
      isPainted = false;
      if (endPointsPerFrame < widget.offsetListFloat.length) {
        final totalLength = widget.offsetListFloat.length;
        final step = totalLength / (60 * widget.animationTime);
        startPointsPerFrame = endPointsPerFrame;
        endPointsPerFrame += step;
        if(endPointsPerFrame>widget.offsetListFloat.length)
          endPointsPerFrame=widget.offsetListFloat.length.toDouble();
        if ((startPointsPerFrame.toInt() ^ endPointsPerFrame.toInt()) & 1 != 0) {
          endPointsPerFrame -= 1;
        }
      }
      await saveCanvasToImage(size);
    }
  }

  @override
  Widget build(BuildContext context) {
    return (widget.offsetListFloat != null)
        ? AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          if (endPointsPerFrame >= widget.offsetListFloat.length) {
            savedImage = null;
            endPointsPerFrame = 0;
          }
          if (widget.isAnimated) {
            update(widget.canvasSize);
            return CustomPaint(
                painter: PaintIndicator(null, savedImage,
                    indicatorColor: widget.indicatorColor),
                size: widget.canvasSize,
                child: Center(
                  child: Text(
                    "${((endPointsPerFrame) /
                        (widget.offsetListFloat.length) *
                        100)
                        .round()}%",
                    style: TextStyle(
                        fontSize: 30,
                        decoration: TextDecoration.none,
                        color: widget.indicatorColor),
                  ),
                )
            );
          } else {
            return CustomPaint(
                painter: PaintIndicator(widget.offsetListFloat, null,
                    indicatorColor: widget.indicatorColor),
                size: widget.canvasSize,
                child: Center(
                    child: Text(
                      "100%",
                      style: TextStyle(
                          fontSize: 30,
                          decoration: TextDecoration.none,
                          color: widget.indicatorColor),
                    ))
            );
          }
        })
        : Container();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> saveCanvasToImage(Size size) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    PaintIndicator(
        widget.offsetListFloat.sublist(
            startPointsPerFrame.toInt(), (endPointsPerFrame.toInt())),
        savedImage,
        indicatorColor: widget.indicatorColor)
        .paint(canvas, size);
    final picture = recorder.endRecording();
    final image =
    await picture.toImage((size.width).toInt(), (size.height).toInt());
    savedImage = image;
    isPainted = true;
  }
}

class PaintIndicator extends CustomPainter {
  ui.Image? savedImage;
  late Float32List? offsetList;
  final Color indicatorColor;

  PaintIndicator(this.offsetList, this.savedImage,
      {this.indicatorColor = Colors.red});

  @override
  void paint(Canvas canvas, Size size) {
    {
      canvas.save();

      final paint = new Paint()
        ..color = indicatorColor
        ..strokeWidth = 2;
      if (savedImage != null) {
        canvas.drawImage(savedImage!, Offset(0, 0), Paint());
      }
      if (offsetList != null) {
        canvas.translate(size.width / 2, size.height / 2);
        canvas.drawRawPoints(
          ui.PointMode.points,
          offsetList!,
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PaintIndicator oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
}

class PaintBackground extends CustomPainter {
  final Float32List floatList;
  final Color backgroundColor;
  const PaintBackground(this.floatList, {this.backgroundColor = Colors.grey});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (floatList.isNotEmpty) {
      final paint =  Paint()
        ..color = backgroundColor
        ..strokeWidth = 2;
      canvas.translate(size.width / 2, size.height / 2);
      canvas.drawRawPoints(
        ui.PointMode.points,
        floatList,
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant PaintBackground oldDelegate) {
    // TODO: implement shouldRepaint
    return false;
  }
}
