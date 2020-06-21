import 'dart:async';
import 'package:flutter/services.dart';

class Variosound {
  static const MethodChannel _channel =
      const MethodChannel('variosound');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

	static void play() {
		_channel.invokeMethod('play');
	}

	static void stop() {
		_channel.invokeMethod('stop');
	}

	static Future<bool> get isPlaying {
		return _channel.invokeMethod('isPlaying');
	}

	static void setSpeed(double speed) {
		_channel.invokeMethod('setSpeed', <String, dynamic>{ 'speed': speed });
	}
}
