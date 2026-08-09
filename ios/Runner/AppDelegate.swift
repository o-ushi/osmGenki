import AudioToolbox
import AVFoundation
import Flutter
import UIKit

// ネイティブ osmWashabe と同じ UIKit シェイク検出（CMMotionManager / HighFrequency HID を使わない）
extension Notification.Name {
  static let osmDeviceDidShake = Notification.Name("osmGenki.deviceDidShake")
}

extension UIWindow {
  open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
    super.motionEnded(motion, with: event)
    if motion == .motionShake {
      NotificationCenter.default.post(name: .osmDeviceDidShake, object: nil)
    }
  }
}

private final class DeviceShakeStreamHandler: NSObject, FlutterStreamHandler {
  private var sink: FlutterEventSink?
  private var observer: NSObjectProtocol?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    observer = NotificationCenter.default.addObserver(
      forName: .osmDeviceDidShake,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.sink?(true)
    }
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    if let observer {
      NotificationCenter.default.removeObserver(observer)
    }
    observer = nil
    sink = nil
    return nil
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var captureHandler: SpeechCaptureHandler?
  private var soundPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let shakeReg = engineBridge.pluginRegistry.registrar(forPlugin: "OsmGenkiDeviceShake")!
    let shakeChannel = FlutterEventChannel(
      name: "com.osamushikubo.osm_genki/device_shake",
      binaryMessenger: shakeReg.messenger()
    )
    shakeChannel.setStreamHandler(DeviceShakeStreamHandler())

    let captureHandler = SpeechCaptureHandler()
    self.captureHandler = captureHandler
    let captureReg = engineBridge.pluginRegistry.registrar(forPlugin: "OsmGenkiSpeechCapture")!
    let captureCh = FlutterMethodChannel(
      name: "com.osamushikubo.osm_genki/speech_capture",
      binaryMessenger: captureReg.messenger()
    )
    captureCh.setMethodCallHandler { [weak captureHandler] call, result in
      captureHandler?.handle(call, result: result)
    }

    // osmWashabeと同じ仕組み：カウントダウン終了チャイム用のシステムサウンド再生。
    let soundReg = engineBridge.pluginRegistry.registrar(forPlugin: "OsmGenkiSystemSound")!
    let soundCh = FlutterMethodChannel(
      name: "com.osamushikubo.osm_genki/system_sound",
      binaryMessenger: soundReg.messenger()
    )
    soundCh.setMethodCallHandler { call, result in
      guard call.method == "play", let soundId = call.arguments as? Int else {
        result(FlutterMethodNotImplemented); return
      }
      AudioServicesPlaySystemSound(SystemSoundID(UInt32(soundId)))
      result(nil)
    }

    // osmWashabeと同じ仕組み：端末内蔵の着信音ファイル一覧・再生（タイマー音設定用）。
    let iosSoundsReg = engineBridge.pluginRegistry.registrar(forPlugin: "OsmGenkiIosSounds")!
    let iosSoundsCh = FlutterMethodChannel(
      name: "com.osamushikubo.osm_genki/ios_sounds",
      binaryMessenger: iosSoundsReg.messenger()
    )
    iosSoundsCh.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "getSounds":
        result(self?.listSoundFiles() ?? [])
      case "play":
        guard let path = call.arguments as? String else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil)); return
        }
        self?.playSoundFile(path: path)
        result(nil)
      case "stop":
        self?.soundPlayer?.stop()
        self?.soundPlayer = nil
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  // ガラガラ・スライド等の着信音ファイルを返す。
  // Alert Tones / Classic はカタログ側 (AudioServicesPlaySystemSound) で処理するため不要。
  private func listSoundFiles() -> [[String: String]] {
    let exts: Set<String> = ["m4r", "caf", "aif", "aiff"]
    var results: [[String: String]] = []
    for dir in ["/System/Library/Ringtones", "/Library/Ringtones"] {
      let url = URL(fileURLWithPath: dir)
      guard let files = try? FileManager.default.contentsOfDirectory(
        at: url, includingPropertiesForKeys: nil
      ) else { continue }
      let sorted = files
        .filter { exts.contains($0.pathExtension.lowercased()) }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
      for file in sorted {
        results.append(["path": file.path, "title": file.deletingPathExtension().lastPathComponent])
      }
    }
    return results
  }

  private func playSoundFile(path: String) {
    soundPlayer?.stop()
    soundPlayer = nil
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
      let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
      soundPlayer = player
      player.play()
    } catch {}
  }
}
