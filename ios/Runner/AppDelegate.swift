import Flutter
import SafariServices
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let libraryKey = "mashhad-library-v1"

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "com.mashhad.app/browser",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "unavailable", message: nil, details: nil))
        return
      }
      switch call.method {
      case "restore":
        guard let key = call.arguments as? String, key == self.libraryKey else {
          result(FlutterError(code: "invalid_key", message: nil, details: nil))
          return
        }
        result(UserDefaults.standard.string(forKey: key))
      case "persist":
        guard let args = call.arguments as? [String: String],
              let key = args["key"], key == self.libraryKey,
              let value = args["value"] else {
          result(FlutterError(code: "invalid_value", message: nil, details: nil))
          return
        }
        UserDefaults.standard.set(value, forKey: key)
        result(nil)
      case "open":
        self.openProvider(call.arguments, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func openProvider(_ arguments: Any?, result: @escaping FlutterResult) {
    guard let raw = arguments as? String,
          let url = URL(string: raw),
          url.scheme == "https",
          url.host == "icinema.live",
          url.user == nil,
          url.password == nil,
          url.port == nil else {
      result(FlutterError(code: "invalid_url", message: nil, details: nil))
      return
    }
    DispatchQueue.main.async {
      let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      guard let scene = scenes.first(where: { $0.activationState == .foregroundActive }),
            let window = scene.windows.first(where: { $0.isKeyWindow }),
            let root = window.rootViewController else {
        result(FlutterError(code: "no_window", message: nil, details: nil))
        return
      }
      var presenter = root
      while let presented = presenter.presentedViewController {
        presenter = presented
      }
      guard !(presenter is SFSafariViewController) else {
        result(nil)
        return
      }
      let browser = SFSafariViewController(url: url)
      browser.dismissButtonStyle = .close
      browser.preferredBarTintColor = UIColor(red: 0.055, green: 0.063, blue: 0.078, alpha: 1)
      browser.preferredControlTintColor = UIColor(red: 0.847, green: 0.980, blue: 0.467, alpha: 1)
      presenter.present(browser, animated: true) { result(nil) }
    }
  }
}
