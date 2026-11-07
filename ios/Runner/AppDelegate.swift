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
  private var iCloudSyncChannel: ICloudSyncChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    // 一度 SwiftUI.AppSceneDelegate で保存されたシーンは、Info.plist の
    // SceneDelegate を読まずに復元される。畳んだ外側画面はプロセスが生きたまま黒くなる。
    // 設定名は毎回逆引き DNS にする。残った "flutter" を状態保存の種別に使うと落ちる。
    let configuration = UISceneConfiguration(
      name: SceneConfiguration.name,
      sessionRole: connectingSceneSession.role
    )
    configuration.delegateClass = SceneDelegate.self
    configuration.storyboard = UIStoryboard(name: "Main", bundle: nil)
    return configuration
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ICloudSyncChannel") {
      iCloudSyncChannel = ICloudSyncChannel(messenger: registrar.messenger())
    }

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

/// iCloud の KVS（日記・診断と設定の同期データ）を Dart から使う出入り口
/// （osmGradus の ICloudSyncChannel と同じ）。
/// 同期の判断（変わったか・マージ）は Dart の CloudSyncService で行う。
final class ICloudSyncChannel: NSObject {
  static let channelName = "com.osamushikubo.osm_genki/icloud"
  static let dataKey = "osmGenki-sync-v1"
  static let timestampKey = "osmGenki-sync-v1-ts"
  /// KVS の 1 値の上限（Dart 側でも確かめる）。
  static let maxBytes = 1_000_000

  private let channel: FlutterMethodChannel
  private let kvStore = NSUbiquitousKeyValueStore.default
  private var observer: NSObjectProtocol?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: Self.channelName, binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  deinit {
    if let observer { NotificationCenter.default.removeObserver(observer) }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "isAvailable":
      result(FileManager.default.ubiquityIdentityToken != nil)

    case "startObserving":
      if observer == nil {
        observer = NotificationCenter.default.addObserver(
          forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
          object: kvStore,
          queue: .main
        ) { [weak self] notification in
          guard let self else { return }
          let reason = (notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? NSNumber)?.intValue
          let keys = notification.userInfo?[NSUbiquitousKeyValueStoreChangedKeysKey] as? [String] ?? []
          // 初回ダウンロード前の書き込みは iOS が捨て、InitialSyncChange で知らせてくる。
          // そのときとアカウントの切り替えは、キーに関係なく Dart に取り込み直させる。
          let resync = reason == NSUbiquitousKeyValueStoreInitialSyncChange
            || reason == NSUbiquitousKeyValueStoreAccountChange
          guard resync || keys.contains(Self.dataKey) else { return }
          self.channel.invokeMethod("externalChange", arguments: nil)
        }
      }
      kvStore.synchronize()
      result(nil)

    case "read":
      kvStore.synchronize()
      result([
        "data": kvStore.string(forKey: Self.dataKey) as Any,
        "timestamp": kvStore.double(forKey: Self.timestampKey),
      ])

    case "write":
      guard let args = call.arguments as? [String: Any],
            let data = args["data"] as? String,
            let timestamp = args["timestamp"] as? Double else {
        result(FlutterError(code: "badArgs", message: "data / timestamp が必要", details: nil))
        return
      }
      let bytes = data.utf8.count
      guard bytes < Self.maxBytes else {
        result(FlutterError(code: "tooLarge", message: "\(bytes) bytes", details: bytes))
        return
      }
      kvStore.set(data, forKey: Self.dataKey)
      kvStore.set(timestamp, forKey: Self.timestampKey)
      // synchronize() は「すぐ iCloud へ送る」ではなく、送る準備ができたかの合図。
      // 実際の送信は iOS が数秒〜数十秒のうちにまとめて行う。
      kvStore.synchronize()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
