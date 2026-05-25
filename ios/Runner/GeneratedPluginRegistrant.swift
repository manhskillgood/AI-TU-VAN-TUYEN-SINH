import UIKit
import Flutter
import Firebase

@UIApplicationMain
@objc class GeneratedPluginRegistrant: NSObject {
}

func application(
  _ application: UIApplication,
  didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {
  FirebaseApp.configure()
  
  let controller = window?.rootViewController as! FlutterViewController
  let batteryChannel = FlutterMethodChannel(
    name: "com.example.education_guidance_app/battery",
    binaryMessenger: controller.binaryMessenger
  )
  
  batteryChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
    switch call.method {
    case "getBatteryLevel":
      result(getBatteryLevel())
    default:
      result(FlutterMethodNotImplemented)
    }
  }
  
  GeneratedPluginRegistrant.register(with: self)
  return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}

private func getBatteryLevel() -> Int {
  UIDevice.current.isBatteryMonitoringEnabled = true
  let batteryLevel = Int(UIDevice.current.batteryLevel * 100)
  return batteryLevel
}
