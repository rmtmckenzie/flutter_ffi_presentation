import Flutter
import UIKit
import mic_ffi_objc

public class MicFfiPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "mic_ffi", binaryMessenger: registrar.messenger())
    let instance = MicFfiPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    AudioMarshaller.init { pointer, int in
      // do nothing.
      print("Marshalled")
    }
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
