import AVFoundation
import Flutter
import Speech

/// 発話フェーズの録音と、タイマー終了後のファイルベース文字起こしを担当する。
final class SpeechCaptureHandler: NSObject {
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private var audioRecorder: AVAudioRecorder?
    private var recordingOutputPath: String?
    private var recordingStartedAt: Date?

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startCapture":
            guard let args = call.arguments as? [String: Any],
                  let path = args["outputPath"] as? String
            else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            requestMicrophonePermission { [weak self] granted in
                guard let self else { return }
                guard granted else {
                    result(FlutterError(
                        code: "MIC_DENIED",
                        message: "Microphone permission denied",
                        details: nil
                    ))
                    return
                }
                do {
                    try self.startRecording(to: path)
                    result(true)
                } catch {
                    result(FlutterError(
                        code: "START_FAILED",
                        message: error.localizedDescription,
                        details: nil
                    ))
                }
            }

        case "stopCapture":
            result(stopRecording())

        case "transcribeFile":
            guard let args = call.arguments as? [String: Any],
                  let path = args["path"] as? String
            else {
                result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
                return
            }
            transcribe(path: path, flutterResult: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Private

    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        let session = AVAudioSession.sharedInstance()
        switch session.recordPermission {
        case .granted:
            completion(true)
        case .denied:
            completion(false)
        case .undetermined:
            session.requestRecordPermission { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        @unknown default:
            completion(false)
        }
    }

    private func startRecording(to path: String) throws {
        stopRecording()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)
        if session.isInputGainSettable {
            try? session.setInputGain(1.0)
        }

        let url = URL(fileURLWithPath: path)
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderBitRateKey: 128000,
        ]
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.isMeteringEnabled = true
        guard audioRecorder?.record() == true else {
            throw NSError(
                domain: "SpeechCapture",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Failed to start recording"]
            )
        }
        recordingOutputPath = path
        recordingStartedAt = Date()
    }

    @discardableResult
    private func stopRecording() -> String? {
        audioRecorder?.stop()
        audioRecorder = nil
        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation)
        let path = recordingOutputPath
        recordingOutputPath = nil
        recordingStartedAt = nil
        return path
    }

    private func transcribe(path: String, flutterResult: @escaping FlutterResult) {
        guard FileManager.default.fileExists(atPath: path) else {
            flutterResult(FlutterError(code: "NO_FILE", message: "Recording file missing", details: nil))
            return
        }

        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                guard status == .authorized else {
                    flutterResult(FlutterError(
                        code: "SPEECH_DENIED",
                        message: "Speech recognition permission denied",
                        details: nil
                    ))
                    return
                }
                self.performTranscription(path: path, flutterResult: flutterResult)
            }
        }
    }

    private func performTranscription(path: String, flutterResult: @escaping FlutterResult) {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            flutterResult(FlutterError(
                code: "SPEECH_UNAVAILABLE",
                message: "Speech recognizer unavailable",
                details: nil
            ))
            return
        }

        let url = URL(fileURLWithPath: path)
        let request = SFSpeechURLRecognitionRequest(url: url)
        request.shouldReportPartialResults = true

        var responded = false
        var latestSegments: [[String: Any]] = []

        func finish(with segments: [[String: Any]]) {
            guard !responded else { return }
            responded = true
            flutterResult(segments)
        }

        func finishWithError(_ error: Error) {
            guard !responded else { return }
            responded = true
            let nsError = error as NSError
            flutterResult(FlutterError(
                code: "RECOGNITION_ERROR",
                message: error.localizedDescription,
                details: "domain=\(nsError.domain) code=\(nsError.code)"
            ))
        }

        func mapSegments(_ transcription: SFTranscription) -> [[String: Any]] {
            transcription.segments.map { seg in
                [
                    "text": seg.substring,
                    "timestamp": seg.timestamp,
                    "duration": seg.duration,
                ]
            }
        }

        let task = recognizer.recognitionTask(with: request) { recognitionResult, error in
            if let recognitionResult = recognitionResult {
                latestSegments = mapSegments(recognitionResult.bestTranscription)
                if recognitionResult.isFinal {
                    finish(with: latestSegments)
                }
            }

            if let error = error {
                // 途中結果があればそれを返す（無音判定エラーでも拾えるようにする）。
                // 途中結果が無い場合は、原因調査のためエラー内容をそのままFlutter側へ伝える。
                if latestSegments.isEmpty {
                    NSLog("SpeechCapture transcribe error: \(error.localizedDescription)")
                    finishWithError(error)
                } else {
                    finish(with: latestSegments)
                }
            }
        }

        // isFinal が来ないケースの保険（シミュレーター等）
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            guard !responded else { return }
            task.cancel()
            finish(with: latestSegments)
        }
    }
}
