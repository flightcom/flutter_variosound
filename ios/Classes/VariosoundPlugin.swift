import Flutter
import UIKit

public class VariosoundPlugin: NSObject, FlutterPlugin {
    private var toneGenerator: ToneGenerator?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "variosound", binaryMessenger: registrar.messenger())
        let instance = VariosoundPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "setSpeed":
            if let args = call.arguments as? [String: Any], let speed = args["speed"] as? Double {
                toneGenerator?.setSpeed(speed: speed)
            }
        case "play":
            if !(toneGenerator?.isPlaying() ?? false) {
                toneGenerator?.startPlayback()
            }
        case "stop":
            toneGenerator?.stopIfPlaying()
        case "isPlaying":
            result(toneGenerator?.isPlaying() ?? false)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    override init() {
        super.init()
        toneGenerator = ToneGenerator()
    }
}