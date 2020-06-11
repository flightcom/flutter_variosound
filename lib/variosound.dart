import 'dart:async';
import 'package:flutter/services.dart';

const MethodChannel _variosoundMethodChannel =
    MethodChannel('com.flightcom.variosound');


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

	static void setSpeed(double speed) {
		_channel.invokeMethod('setSpeed', <String, dynamic>{ 'speed': speed });
	}
}