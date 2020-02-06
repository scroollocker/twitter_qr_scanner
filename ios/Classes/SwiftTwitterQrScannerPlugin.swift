import Flutter
import UIKit

public class SwiftTwitterQrScannerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    registrar.register(
      QRViewFactory(withRegistrar: registrar),
      withId: "com.anka.twitter_qr_scanner/qrview"
    )
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    result("iOS " + UIDevice.current.systemVersion)
  }
}
