import 'dart:ui';

import 'package:flutter/material.dart';

class SecondPage extends StatefulWidget {
  final List<Offset> points;

  const SecondPage({Key? key, required this.points}) : super(key: key);

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  List<Offset> coordinatePoints = [];

  void _addCoordinatePoint(Offset point) {
    setState(() {
      coordinatePoints.add(point);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          child: Container(
            width: 200, // Replace with your desired width
            height: 200, // Replace with your desired height
            decoration: BoxDecoration(
              image: DecorationImage(
                image:
                    AssetImage('assets/ha.jpg'), // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
            child: MyDrawingWidget(widget.points),
          ),
        ),
      ),
    );
  }
}

class MyDrawingWidget extends StatefulWidget {
  final List<Offset> targetPoints;
  const MyDrawingWidget(this.targetPoints, {super.key});
  @override
  _MyDrawingWidgetState createState() => _MyDrawingWidgetState();
}

class _MyDrawingWidgetState extends State<MyDrawingWidget> {
  List<Offset> drawingPoints = [];
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (counter == widget.targetPoints.length) return;

        RenderBox renderBox = context.findRenderObject() as RenderBox;
        var localPoint = renderBox.globalToLocal(details.globalPosition);
        setState(() {
          drawingPoints.add(localPoint);
        });
        // see if the local point is within a certain distance of the target point
        // where the target points is the counter's index in the list
        if ((localPoint - widget.targetPoints[counter]).distance < 10) {
          counter++;
        }
        // if counter is equal to the length of the target points list, then the user has completed the drawing
        if (counter == widget.targetPoints.length) {
          print("Drawing completed");
        }
      },
      onPanEnd: (details) => drawingPoints.add(Offset.zero),
      child: CustomPaint(
        painter: MyPainter(drawingPoints),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final List<Offset> points;
  MyPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != Offset.zero && points[i + 1] != Offset.zero) {
        canvas.drawLine(points[i], points[i + 1], paint);
      } else if (points[i] != Offset.zero && points[i + 1] == Offset.zero) {
        // Draw small circles at the points when the user lifts the finger
        canvas.drawCircle(points[i], 2.0, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
