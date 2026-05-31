import AVFoundation

/// Streams the `AudioStreamLooper` output through an `AVAudioPlayerNode` using a
/// pair of buffers that are refilled in their completion handlers. Setting the
/// speed only updates a target value — the running generator picks it up
/// smoothly, with no restart of the engine.
class ToneGenerator {
    private let bufferFrames: AVAudioFrameCount = 1024 // ~23 ms at 44.1 kHz

    private let audioEngine = AVAudioEngine()
    private let audioPlayerNode = AVAudioPlayerNode()
    private let audioFormat: AVAudioFormat
    private var audioBuffers: [AVAudioPCMBuffer] = []
    private var playingStatus = false
    private let looper = AudioStreamLooper()

    init() {
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!

        // Play through the .playback category so the vario keeps sounding when
        // the app is backgrounded or the screen is locked (with the app's
        // "audio" UIBackgroundMode). Mix with other audio so music keeps going.
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Could not configure the audio session: \(error)")
        }

        audioEngine.attach(audioPlayerNode)
        audioEngine.connect(audioPlayerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        do {
            audioEngine.prepare()
            try audioEngine.start()
        } catch {
            print("Could not start the audio engine: \(error)")
        }

        for _ in 0..<2 {
            let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: bufferFrames)!
            buffer.frameLength = bufferFrames
            audioBuffers.append(buffer)
        }
    }

    func setSpeed(speed: Double) {
        looper.setSpeed(speed)
    }

    func startPlayback() {
        guard !playingStatus else { return }
        playingStatus = true
        looper.reset()
        audioPlayerNode.play()
        scheduleBuffer(0)
        scheduleBuffer(1)
    }

    func stopPlayback() {
        guard playingStatus else { return }
        playingStatus = false
        audioPlayerNode.stop()
    }

    func stopIfPlaying() -> Bool {
        if playingStatus {
            stopPlayback()
            return true
        }
        return false
    }

    func isPlaying() -> Bool {
        return playingStatus
    }

    private func scheduleBuffer(_ bufferIndex: Int) {
        guard playingStatus else { return }

        let buffer = audioBuffers[bufferIndex]
        buffer.frameLength = bufferFrames
        looper.fill(buffer.floatChannelData![0], Int(bufferFrames))

        audioPlayerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
            self?.scheduleBuffer(bufferIndex)
        })
    }
}
