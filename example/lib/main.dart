import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:variosound/variosound.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  double _speed = 0;
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    initPlatformState();
    Variosound.play();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      platformVersion = await Variosound.platformVersion;
      getPlaying();
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  void getPlaying() {
    bool playing;
    Timer.periodic(Duration(seconds: 1), (Timer t) async {
      playing = await Variosound.isPlaying;
      setState(() {
        _playing = playing;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Speed: $_speed\n'),
              ElevatedButton(
                onPressed: () => Variosound.stop(),
                child: Text('STOP'),
              ),
              ElevatedButton(
                onPressed: () => Variosound.play(),
                child: Text('PLAY'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _speed += 1.0);
                  Variosound.setSpeed(_speed);
                },
                child: Text('increase speed'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _speed -= 1.0);
                  Variosound.setSpeed(_speed);
                },
                child: Text('decrease speed'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => _speed = 0.0);
                  Variosound.setSpeed(_speed);
                },
                child: Text('RESET'),
              ),
              Text(_playing.toString())
            ],
          ),
        ),
      ),
    );
  }
}
