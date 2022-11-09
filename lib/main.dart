import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartVideo Flutter Demo',
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
      home: const MyHomePage(title: 'SmartVideo Flutter Demo'),
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
  final nameBoxController =  TextEditingController(text: 'Flutter App Customer');
  static const platform = MethodChannel('videoengager.smartvideo.channel');


  void clickToVideo(){
    platform.invokeMethod('ClickToVideo',nameBoxController.text);
    log(nameBoxController.text);
  }

  Future<void> veHandler(MethodCall call) async {
    final String args = call.arguments;
    log(args);

    switch (call.method) {

      case "Ve_onError": // this method name needs to be the same from invokeMethod in Android
          log("Error received: "+args);
        break;

      case "Ve_onChatMessage": // this method name needs to be the same from invokeMethod in Android
        showDialog(context: context, builder:(BuildContext context) {
          return AlertDialog(
            title: const Text("Chat message"),
            content: Text(args),
              actions: <Widget>[
                  TextButton(
                  style: TextButton.styleFrom(
                      textStyle: Theme.of(context).textTheme.labelLarge,
                  ),
                  child: const Text('   OK   '),
                  onPressed: () { Navigator.of(context).pop();},
                  )
          ]
          );
        });
        break;

      default:
        log('no method handler for method ${call.method}');
    }
  }

  @override
  void dispose() {
    nameBoxController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    platform.setMethodCallHandler(veHandler);
    super.initState();
  }

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
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,

          children: <Widget>[

            const Text(
              'Fill your name and click Button \n to make demo call:',
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
              child: TextField(
                decoration: const InputDecoration(
                    labelText: 'Enter Your Name',
                    hintText: 'Enter Your Name',
                ),
                controller: nameBoxController,
              ),
            ),
            TextButton(
              style: const ButtonStyle(
                backgroundColor:MaterialStatePropertyAll(Colors.blue),
                foregroundColor: MaterialStatePropertyAll(Colors.white),
                padding: MaterialStatePropertyAll(EdgeInsets.all(20))
              ),
              onPressed: clickToVideo,
              child: Text("  ..:: ClickToVideo ::..  "),
            )
          ],
        ),
      ),
    );
  }
}
