import 'package:custom_gestures/custom_gestures.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: RawGestureDetector(
          gestures: {
            UpwardDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<UpwardDragGestureRecognizer>(
                () => UpwardDragGestureRecognizer(),
                (UpwardDragGestureRecognizer instance) {
                    instance
                      ..onDown = (details) { print("upward onDown");}
                      ..onStart = (details) { print("upward onStart");}
                      ..onUpdate = (details) { print("upward onUpdate");}
                      ..onEnd = (details) { print("upward onEnd");}
                      ..onCancel = () { print("upward onCancel");};
                }
            ),
            DownwardDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<DownwardDragGestureRecognizer>(
                    () => DownwardDragGestureRecognizer(),
                    (DownwardDragGestureRecognizer instance) {
                  instance
                    ..onDown = (details) { print("downward onDown");}
                    ..onStart = (details) { print("downward onStart");}
                    ..onUpdate = (details) { print("downward onUpdate");}
                    ..onEnd = (details) { print("downward onEnd");}
                    ..onCancel = () { print("downward onCancel");};
                }
            ),
            LeftDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<LeftDragGestureRecognizer>(
                    () => LeftDragGestureRecognizer(),
                    (LeftDragGestureRecognizer instance) {
                  instance
                    ..onDown = (details) { print("left onDown");}
                    ..onStart = (details) { print("left onStart");}
                    ..onUpdate = (details) { print("left onUpdate");}
                    ..onEnd = (details) { print("left onEnd");}
                    ..onCancel = () { print("left onCancel");};
                }
            ),
            RightDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<RightDragGestureRecognizer>(
                    () => RightDragGestureRecognizer(),
                    (RightDragGestureRecognizer instance) {
                  instance
                    ..onDown = (details) { print("right onDown");}
                    ..onStart = (details) { print("right onStart");}
                    ..onUpdate = (details) { print("right onUpdate");}
                    ..onEnd = (details) { print("right onEnd");}
                    ..onCancel = () { print("right onCancel");};
                }
            ),
            PinchScaleGestureRecognizer: GestureRecognizerFactoryWithHandlers<PinchScaleGestureRecognizer>(
                    () => PinchScaleGestureRecognizer(),
                    (PinchScaleGestureRecognizer instance) {
                  instance
                    ..onStart = () { print("multi scale onStart");}
                    ..onUpdate = (details) { print("multi scale onUpdate scale=${details.scale}");}
                    ..onEnd = (details) { print("multi scale onEnd");};
                }
            )
          },
          child: Container(
            width: MediaQuery.of(context).size.aspectRatio < 1 ? MediaQuery.of(context).size.width
                : MediaQuery.of(context).size.height,
            height: MediaQuery.of(context).size.aspectRatio < 1 ? MediaQuery.of(context).size.width
                : MediaQuery.of(context).size.height,
            color: Colors.green,
          ),
        )
      ),
    );
  }
}
