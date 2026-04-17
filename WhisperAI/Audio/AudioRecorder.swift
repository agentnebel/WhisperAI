import AVFoundation

class AudioRecorder: NSObject {
    private var recorder: AVAudioRecorder?

    private var tempFileURL: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("whisperai_recording.m4a")
    }

    static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func startRecording() throws {
        try? FileManager.default.removeItem(at: tempFileURL)

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        recorder = try AVAudioRecorder(url: tempFileURL, settings: settings)
        guard recorder?.record() == true else {
            throw AudioError.recordingFailed
        }
    }

    func stopRecording() -> URL? {
        guard let recorder = recorder, recorder.isRecording else { return nil }
        recorder.stop()
        let url = tempFileURL
        self.recorder = nil
        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
}

enum AudioError: LocalizedError {
    case recordingFailed

    var errorDescription: String? {
        "Aufnahme konnte nicht gestartet werden."
    }
}
