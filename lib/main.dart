import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:lettering_demo/second_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<_CoordinateListWidgetState> _coordinateListKey =
      GlobalKey<_CoordinateListWidgetState>();

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: CoordinateListWidget(key: _coordinateListKey),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SecondPage(
                  points: _coordinateListKey.currentState!.coordinatePoints)));
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class CoordinateListWidget extends StatefulWidget {
  const CoordinateListWidget({Key? key}) : super(key: key);

  @override
  _CoordinateListWidgetState createState() => _CoordinateListWidgetState();
}

class _CoordinateListWidgetState extends State<CoordinateListWidget> {
  List<Offset> coordinatePoints = [];
  List<Offset> keyPoints = [];

  void _addCoordinatePoint(Offset point) {
    setState(() {
      coordinatePoints.add(point);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onPanUpdate: (details) {
            RenderBox renderBox = context.findRenderObject() as RenderBox;
            var localPoint = renderBox.globalToLocal(details.globalPosition);
            _addCoordinatePoint(localPoint);
          },
          child: Container(
            width: 200, // Replace with your desired width
            height: 200, // Replace with your desired height
            decoration: const BoxDecoration(
              image: DecorationImage(
                image:
                    AssetImage('assets/ha.jpg'), // Replace with your image path
                fit: BoxFit.cover,
              ),
            ),
            child: CustomPaint(
              painter: CoordinatePointsPainter(
                  coordinatePoints: coordinatePoints, keyPoints: keyPoints),
            ),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: () {
            setState(() {
              coordinatePoints.clear();
              keyPoints.clear();
            });
          },
          child: const Text('Clear'),
        ),
        ElevatedButton(
          onPressed: () {
            keyPoints.addAll(ShapeContext.identifyKeypoints(coordinatePoints));
            setState(() {});
          },
          child: const Text('key points'),
        ),
      ],
    );
  }
}

class CoordinatePointsPainter extends CustomPainter {
  final List<Offset> coordinatePoints;
  final List<Offset> keyPoints;

  CoordinatePointsPainter(
      {required this.coordinatePoints, required this.keyPoints});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red // Replace with your desired color
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    for (final point in coordinatePoints) {
      canvas.drawPoints(PointMode.points, [point], paint);
    }

    final keyPaint = Paint()
      ..color = Colors.blue // Replace with your desired color
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    for (final point in keyPoints) {
      canvas.drawPoints(PointMode.points, [point], keyPaint);
    }
  }

  @override
  bool shouldRepaint(CoordinatePointsPainter oldDelegate) {
    var repaint = oldDelegate.coordinatePoints != coordinatePoints;
    return true;
  }
}
