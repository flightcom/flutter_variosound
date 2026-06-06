import 'dart:async';
import 'package:flutter/services.dart';

class Variosound {
  static const MethodChannel _channel = const MethodChannel('variosound');

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

  static Future<bool> get isPlaying async {
    final dynamic isPlaying = await _channel.invokeMethod('isPlaying');
    return isPlaying as bool;
  }

  static void setSpeed(double speed) {
    _channel.invokeMethod('setSpeed', <String, dynamic>{'speed': speed});
  }

  /// Enables the soft "weak lift" (zérotage) sound, overriding the normal
  /// climb/sink tone — used when the air is lifting just enough to offset the
  /// glider's sink (net vertical speed near zero, below the climb threshold).
  static void setWeakLift(bool active) {
    _channel.invokeMethod('setWeakLift', <String, dynamic>{'weak': active});
  }
}
