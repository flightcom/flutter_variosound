package com.flightcom.variosound;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** VariosoundPlugin */
public class VariosoundPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that handles the communication between Flutter and native Android.
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity.
  private MethodChannel channel;
  private ToneGenerator tn;

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "variosound");
    channel.setMethodCallHandler(this);
    tn = new ToneGenerator();
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    if (call.method.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    } else if (call.method.equals("setSpeed")) {
      double speed = (double) call.argument("speed");
      tn.setSpeed(speed);
    } else if (call.method.equals("play")) {
      if (!tn.playing()) {
          tn.startPlayback();
      }
    } else if (call.method.equals("stop")) {
      tn.stopIfPlaying();
    } else if (call.method.equals("isPlaying")) {
      result.success(tn.playing());
    } else {
      result.notImplemented();
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
