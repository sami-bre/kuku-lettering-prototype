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
            child: MyDrawingWidget(),
          ),
        ),
      ),
    );
  }
}

class MyDrawingWidget extends StatefulWidget {
  @override
  _MyDrawingWidgetState createState() => _MyDrawingWidgetState();
}

class _MyDrawingWidgetState extends State<MyDrawingWidget> {
  List<Offset> points = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          RenderBox renderBox = context.findRenderObject() as RenderBox;
          points.add(renderBox.globalToLocal(details.globalPosition));
        });
      },
      onPanEnd: (details) => points.add(Offset.zero),
      child: CustomPaint(
        painter: MyPainter(points),
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
      ..strokeWidth = 5.0;

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
