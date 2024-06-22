import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lettering_demo/data.dart';

class SecondPage extends StatelessWidget {
  final Letter letter;
  final List<List<Offset>> strokes;

  const SecondPage({Key? key, required this.letter, required this.strokes})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: MyDrawingWidget(letter: letter, targetStrokes: strokes),
      ),
    );
  }
}

class MyDrawingWidget extends StatefulWidget {
  final Letter letter;
  final List<List<Offset>> targetStrokes;
  const MyDrawingWidget(
      {required this.letter, required this.targetStrokes, super.key});
  @override
  _MyDrawingWidgetState createState() => _MyDrawingWidgetState();
}

class _MyDrawingWidgetState extends State<MyDrawingWidget> {
  List<List<Offset>> drawingStrokes = [
    []
  ]; // holds the strokes (list of offsets) that we draw on the screen as the user traces
  int currentOffsetIndex =
      0; // indicates what point (offset) the user is at while drawing a stroke (strokes are made up of points)
  late List<double>
      targetDistances; // the distance (length) of each target stroke
  List<double> drawingDistances =
      []; // the distance (length) of each drawing stroke
  int currentStrokeIndex = 0; // the current stroke the user is tracing
  String? comment; // the final result (good or bad trace),
  late List<bool> strokeValidity; // good or bad trace for each stroke
  bool tracingActive = true; // indicates if the user can still draw (trace)

  @override
  void initState() {
    super.initState();
    strokeValidity =
        List.generate(widget.targetStrokes.length, (index) => false);
    // set the target distance to the sum of the distances between consecutinve target points
    targetDistances = [];
    for (int i = 0; i < widget.targetStrokes.length; i++) {
      targetDistances.add(getDistanceOfStroke(widget.targetStrokes[i]));
    }

    // populate the drawingStrokes list with empty lists
    for (int i = 0; i < widget.targetStrokes.length; i++) {
      drawingStrokes.add([]);
    }
    print(drawingStrokes.length);
  }

  double getDistanceOfStroke(List<Offset> stroke) {
    double distance = 0;
    for (int i = 0; i < stroke.length - 1; i++) {
      if (stroke[i] == Offset.zero || stroke[i + 1] == Offset.zero) {
        continue;
      }
      distance += (stroke[i] - stroke[i + 1]).distance;
    }
    return distance;
  }

  double getDistanceOfAllStrokes(List<List<Offset>> strokes) {
    double distance = 0;
    for (int i = 0; i < strokes.length; i++) {
      distance += getDistanceOfStroke(strokes[i]);
    }
    return distance;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onPanUpdate: (details) {
            if (currentOffsetIndex ==
                widget.targetStrokes[currentStrokeIndex].length) return;

            RenderBox renderBox = context.findRenderObject() as RenderBox;
            var localPoint = renderBox.globalToLocal(details.globalPosition);
            if (tracingActive) {
              // we draw the point only if the user is still tracing.
              // Note that adding a point to the drawingStrokes results in the CustomPainter drawing a line between the current point and the previous point
              setState(() {
                drawingStrokes[currentStrokeIndex].add(localPoint);
              });
            }
            // see if the local point is within a certain distance of the target point
            if ((localPoint -
                        widget.targetStrokes[currentStrokeIndex]
                            [currentOffsetIndex])
                    .distance <
                10) {
              currentOffsetIndex++;
              // if the currentOffsetIndex is equal to the length of the stroke, then the user has completed the stroke
              if (currentOffsetIndex ==
                  widget.targetStrokes[currentStrokeIndex].length) {
                strokeValidity[currentStrokeIndex] = true;
              }
            }
          },
          onPanEnd: (details) {
            endStroke();
            // to prevent the user from drawing indefinitely, we compare the total distance (length) of the drawing strokes with the target strokes
            double targetDistance =
                targetDistances.reduce((value, element) => value + element);
            double distance =
                drawingDistances.reduce((value, element) => value + element);
            if (distance > targetDistance * 1.6) {
              endTracing();
            }
          },
          child: Container(
            width: 200, // Replace with your desired width
            height: 200, // Replace with your desired height
            child: Stack(
              children: [
                SvgPicture.asset(
                  widget.letter.letterImage,
                  fit: BoxFit.fill,
                ),
                CustomPaint(
                  painter: MyPainter(drawingStrokes),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            drawingStrokes =
                List.generate(widget.targetStrokes.length, (index) => []);
            strokeValidity =
                List.generate(widget.targetStrokes.length, (index) => false);
            drawingDistances = [];
            setState(() {
              currentOffsetIndex = 0;
              currentStrokeIndex = 0;
              comment = null;
              tracingActive = true;
            });
          },
          child: const Text("clear"),
        ),
        if (comment != null)
          Text(
            comment!,
            style: const TextStyle(fontSize: 18),
          )
      ],
    );
  }

  void endStroke() {
    // calculate the distance of the drawing stroke and save it in a list for a later calculation
    double distance = getDistanceOfStroke(drawingStrokes[currentStrokeIndex]);
    drawingDistances.add(distance);

    // now check if we just finished the last stroke
    if (currentStrokeIndex == widget.targetStrokes.length - 1) {
      endTracing();
    } else {
      // move to the next stroke
      currentStrokeIndex++;
      currentOffsetIndex = 0;
      setState(() {
        // we add a zero offset to mark the end of the stroke for the CustomPainter
        drawingStrokes[currentStrokeIndex].add(Offset.zero);
      });
    }
  }

  void endTracing() {
    // we set the tracingActive to false to prevent the user from drawing anymore
    tracingActive = false;
    // if we did, then we can calculate the final result
    double targetDistance =
        targetDistances.reduce((value, element) => value + element);
    double distance =
        drawingDistances.reduce((value, element) => value + element);

    bool goodTrace = true;
    // if the distance is within 20% above target distance, we assume the user has drawn the image correctly
    if (distance > targetDistance * 1.2 || distance < targetDistance) {
      goodTrace = false;
    }

    // if all the strokes are drawn correctly, then the user has drawn the image correctly
    for (int i = 0; i < strokeValidity.length; i++) {
      if (!strokeValidity[i]) {
        goodTrace = false;
        break;
      }
    }

    if (goodTrace) {
      setState(() {
        comment = "good";
      });
      print('good! tagetDistance: $targetDistance, actual distance: $distance');
    } else {
      setState(() {
        comment = "bad";
      });
      print('bad! tagetDistance: $targetDistance, actual distance: $distance');
    }
  }
}

class MyPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  MyPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 10;

    for (var stroke in strokes) {
      for (int i = 0; i < stroke.length - 1; i++) {
        if (stroke[i] != Offset.zero && stroke[i + 1] != Offset.zero) {
          canvas.drawLine(stroke[i], stroke[i + 1], paint);
        } else if (stroke[i] != Offset.zero && stroke[i + 1] == Offset.zero) {
          // Draw small circles at the points when the user lifts the finger
          canvas.drawCircle(stroke[i], 2.0, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
