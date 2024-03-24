import 'dart:math';

import 'package:flutter/material.dart';

class SecondPage extends StatefulWidget {
  final List<Offset> points;

  const SecondPage({Key? key, required this.points}) : super(key: key);

  @override
  State<SecondPage> createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: MyDrawingWidget(widget.points),
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
  late double targetDistance;
  String? comment;
  double? similarity;

  @override
  void initState() {
    super.initState();
    // set the target distance to the sum of the distances between consecutinve target points
    targetDistance = getDistanceFromPoints(widget.targetPoints);
  }

  double getDistanceFromPoints(List<Offset> points) {
    double distance = 0;
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] == Offset.zero || points[i + 1] == Offset.zero) {
        continue;
      }
      distance += (points[i] - points[i + 1]).distance;
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
              // calculate the distance between the drawing points
              double distance = getDistanceFromPoints(drawingPoints);
              // if the distance is within 20% of the target distance, then the user has drawn the image correctly
              if (distance < targetDistance * 1.2) {
                setState(() {
                  comment = "good";
                });
                print(
                    'good! tagetDistance: $targetDistance, actual distance: $distance');
              } else {
                setState(() {
                  comment = "bad";
                });
                print(
                    'bad! tagetDistance: $targetDistance, actual distance: $distance');
              }
            }
          },
          onPanEnd: (details) => drawingPoints.add(Offset.zero),
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
            child: CustomPaint(
              painter: MyPainter(drawingPoints),
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            var _similarity =
                ShapeContext.compare(widget.targetPoints, drawingPoints);
            setState(() {
              similarity = _similarity;
            });
          },
          child: const Text("shape context"),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              drawingPoints.clear();
              counter = 0;
              comment = null;
              similarity = null;
            });
          },
          child: const Text("clear"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("back"),
        ),
        if (comment != null)
          Text(
            comment!,
            style: TextStyle(fontSize: 18),
          ),
        if (similarity != null)
          Text(
            "similarity: $similarity",
            style: TextStyle(fontSize: 18),
          )
      ],
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

class ShapeContext {
  // Function to calculate Euclidean distance between two points
  static double euclideanDistance(Offset p1, Offset p2) {
    final dx = p1.dx - p2.dx;
    final dy = p1.dy - p2.dy;
    return sqrt(dx * dx + dy * dy);
  }

  static List<Offset> identifyKeypoints(List<Offset> points) {
    List<Offset> keypoints = [];

    for (int i = 1; i < points.length - 1; i++) {
      Offset prevPoint = points[max(0, i - 1)];
      Offset currentPoint = points[i];
      Offset nextPoint = points[min(points.length - 1, i + 1)];

      double prevAngle =
          atan2(currentPoint.dy - prevPoint.dy, currentPoint.dx - prevPoint.dx);
      double nextAngle =
          atan2(nextPoint.dy - currentPoint.dy, nextPoint.dx - currentPoint.dx);

      double angleDifference = (nextAngle - prevAngle).abs();

      if (angleDifference > 1.1) {
        // Adjust the threshold as needed
        keypoints.add(currentPoint);
      }
    }

    return keypoints;
  }

  // Function to calculate local descriptors for keypoints
  static List<List<int>> calculateLocalDescriptors(
      List<Offset> keypoints, List<Offset> points) {
    final descriptor = List<List<int>>.generate(
        keypoints.length, (_) => List<int>.filled(keypoints.length, 0));

    for (int i = 0; i < keypoints.length; i++) {
      final keypoint = keypoints[i];
      final distances =
          keypoints.map((point) => euclideanDistance(keypoint, point)).toList();

      // Populate the descriptor with the distances to all keypoints
      for (int j = 0; j < keypoints.length; j++) {
        descriptor[i][j] =
            (distances[j] * 10).round(); // Multiply by 10 for simplicity
      }
    }

    return descriptor;
  }

  // Function to concatenate descriptors into a single feature vector
  static List<int> concatenateDescriptors(List<List<int>> descriptors) {
    final featureVector = <int>[];

    for (final descriptor in descriptors) {
      featureVector.addAll(descriptor);
    }

    return featureVector;
  }

  // Function to measure similarity between two feature vectors using cosine similarity
  static double measureSimilarity(List<int> vector1, List<int> vector2) {
    final len1 = vector1.length;
    final len2 = vector2.length;
    final maxLength = max(len1, len2);

    // Pad the shorter vector with 0s
    final paddedVector1 = List<int>.filled(maxLength, 0);
    final paddedVector2 = List<int>.filled(maxLength, 0);

    for (int i = 0; i < len1; i++) {
      paddedVector1[i] = vector1[i];
    }

    for (int i = 0; i < len2; i++) {
      paddedVector2[i] = vector2[i];
    }

    double dotProduct = 0.0;
    double normVector1 = 0.0;
    double normVector2 = 0.0;

    // Calculate dot product and norms
    for (int i = 0; i < maxLength; i++) {
      dotProduct += paddedVector1[i] * paddedVector2[i];
      normVector1 += paddedVector1[i] * paddedVector1[i];
      normVector2 += paddedVector2[i] * paddedVector2[i];
    }

    // Calculate cosine similarity
    double similarity = dotProduct / (sqrt(normVector1) * sqrt(normVector2));

    return similarity;
  }

  // a function to compare two sets of points
  static double compare(List<Offset> points1, List<Offset> points2) {
    final keypoints1 = identifyKeypoints(points1);
    final keypoints2 = identifyKeypoints(points2);

    final descriptors1 = calculateLocalDescriptors(keypoints1, points1);
    final descriptors2 = calculateLocalDescriptors(keypoints2, points2);

    final featureVector1 = concatenateDescriptors(descriptors1);
    final featureVector2 = concatenateDescriptors(descriptors2);

    final similarity = measureSimilarity(featureVector1, featureVector2);

    return similarity;
  }
}
