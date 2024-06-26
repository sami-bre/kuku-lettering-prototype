import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lettering_demo/data.dart';
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
      home: LetterListScreen(),
    );
  }
}

class LetterListScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<Letter> lettersData = letters;

    return Scaffold(
      appBar: AppBar(
        title: Text('Letter List'),
      ),
      body: ListView.builder(
        itemCount: letters.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      LetterFaceScreen(letter: lettersData[index]),
                ),
              );
            },
            child: ListTile(
              title: Text(lettersData[index].letterText),
            ),
          );
        },
      ),
    );
  }
}

class LetterFaceScreen extends StatefulWidget {
  const LetterFaceScreen({super.key, required this.letter});

  final Letter letter;

  @override
  State<LetterFaceScreen> createState() => _LetterFaceScreenState();
}

class _LetterFaceScreenState extends State<LetterFaceScreen> {
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
      appBar: AppBar(),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: CoordinateListWidget(
            key: _coordinateListKey, letter: widget.letter),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          var strokes = _coordinateListKey.currentState!.strokes;
          print(strokes.map((stroke) =>
              "${stroke.map((point) => "Offset(${point.dx.toStringAsFixed(4)}, ${point.dy.toStringAsFixed(4)})").toList()}").toList());
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SecondPage(
                  letter: widget.letter,
                  strokes: _coordinateListKey.currentState!.strokes)));
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class CoordinateListWidget extends StatefulWidget {
  final Letter letter;
  const CoordinateListWidget({Key? key, required this.letter})
      : super(key: key);

  @override
  _CoordinateListWidgetState createState() => _CoordinateListWidgetState();
}

class _CoordinateListWidgetState extends State<CoordinateListWidget> {
  List<List<Offset>> strokes = [];
  List<Offset> currentStroke = [];

  late double canvasWidth;
  late double canvasHeight;

  void _addCoordinatePoint(Offset point) {
    setState(() {
      currentStroke.add(_normalizePoint(point));
    });
  }

  void _completeStroke() {
    setState(() {
      strokes.add(List.from(currentStroke));
      currentStroke.clear();
    });
  }

  Offset _normalizePoint(Offset point) {
    double normalizedX = point.dx / canvasWidth;
    double normalizedY = point.dy / canvasHeight;
    return Offset(normalizedX, normalizedY);
  }

  Offset _denormalizePoint(Offset point) {
    double denormalizedX = point.dx * canvasWidth;
    double denormalizedY = point.dy * canvasHeight;
    return Offset(denormalizedX, denormalizedY);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        GestureDetector(
          onTapDown: (TapDownDetails details) {
            _addCoordinatePoint(details.localPosition);
          },
          child: Container(
            width: 200, // Replace with your desired width
            height: 200, // Replace with your desired height
            child: Builder(builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
                var size = context.size;
                canvasWidth = size!.width;
                canvasHeight = size.height;
              });
              return Stack(
                children: [
                  SvgPicture.asset(
                    widget.letter.letterImage,
                    fit: BoxFit.fill,
                  ),
                  CustomPaint(
                    painter: CoordinatePointsPainter(
                      [...strokes, currentStroke].map((stroke) {
                        return stroke.map((point) {
                          return _denormalizePoint(point);
                        }).toList();
                      }).toList(),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _completeStroke,
          child: const Text("complete stroke"),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            setState(() {
              strokes = [];
              currentStroke = [];
            });
          },
          child: const Text("clear"),
        ),
        const SizedBox(height: 20),
        for (Offset point in currentStroke) Text("(${point.dx}, ${point.dy})")
      ],
    );
  }
}

class CoordinatePointsPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.cyan,
  ];

  CoordinatePointsPainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red // Replace with your desired color
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < strokes.length; i++) {
      paint.color = colors[i % colors.length];
      final stroke = strokes[i];
      for (final point in stroke) {
        canvas.drawPoints(PointMode.points, [point], paint);
      }
    }
  }

  @override
  bool shouldRepaint(CoordinatePointsPainter oldDelegate) {
    var repaint = oldDelegate.strokes != strokes;
    return true;
  }
}
