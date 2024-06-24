import AVFoundation

class ToneGenerator {
    private var audioEngine: AVAudioEngine
    private var audioPlayerNode: AVAudioPlayerNode
    private var audioFormat: AVAudioFormat
    // private var audioBuffer: AVAudioPCMBuffer
    private var audioBuffers: [AVAudioPCMBuffer]
    private var playingStatus: Bool
    private var speed: Double
    private var duration: Int
    private var looper: AudioStreamLooper

    init() {
        audioEngine = AVAudioEngine()
        audioPlayerNode = AVAudioPlayerNode()
        // audioFormat = AVAudioFormat(
        //     commonFormat: AVAudioCommonFormat.pcmFormatInt32, 
        //     sampleRate: 44100, 
        //     channels: 1, 
        //     interleaved: true
        // )!
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 1)!
        // audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(audioFormat.sampleRate * 1))!
        audioBuffers = []
        playingStatus = false
        speed = 0.0
        duration = 1000
        looper = AudioStreamLooper()

        audioEngine.attach(audioPlayerNode)
        audioEngine.connect(audioPlayerNode, to: audioEngine.mainMixerNode, format: audioFormat)
        do {
            try audioEngine.prepare()    
            try audioEngine.start()
        } catch {
            print("Could not prepare the audio engine")
        }
        // Create double buffers
        for _ in 0..<2 {
            let buffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: AVAudioFrameCount(audioFormat.sampleRate * 1))!
            audioBuffers.append(buffer)
        }
    }

    func setSpeed(speed: Double) {
        self.speed = speed
        let frequency = 3 * pow(speed + 10, 2) + 200
        duration = speed >= 0.0 ? Int(200 + 400 / (speed + 1)) : 200
        looper.setFrequency(frequency: frequency)
        looper.setBufferSize(bufferSize: Int(audioFormat.sampleRate) * duration / 1000)
        stopPlayback()
        startPlayback()
        let bufferSize = Int(audioFormat.sampleRate) * duration / 1000
        looper.setBufferSize(bufferSize: bufferSize)

        // Update the buffers with the new size
        for buffer in audioBuffers {
            buffer.frameLength = AVAudioFrameCount(bufferSize)
        }
    }

    func startPlayback() {
        guard !playingStatus else { return }
        playingStatus = true
        audioPlayerNode.play()
        // playTone()
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

    // private func playTone() {
    //     let sampleBuffer = looper.getSampleBuffer(full: speed < 0)
    //     let frameLength = min(audioBuffer.frameCapacity, AVAudioFrameCount(sampleBuffer.count))
    //     audioBuffer.frameLength = frameLength
    //     for i in 0..<Int(frameLength) {
    //         audioBuffer.floatChannelData![0][i] = Float(sampleBuffer[i]) / Float(Int16.max)
    //     }
    //     audioPlayerNode.scheduleBuffer(audioBuffer, at: nil, options: .loops, completionHandler: nil)
    // }

    private func scheduleBuffer(_ bufferIndex: Int) {
        guard playingStatus else { return }

        let buffer = audioBuffers[bufferIndex]
        let sampleBuffer = looper.getSampleBuffer(full: speed < 0)
        let frameLength = min(buffer.frameCapacity, AVAudioFrameCount(sampleBuffer.count))
        buffer.frameLength = frameLength
        for i in 0..<Int(frameLength) {
            buffer.floatChannelData![0][i] = Float(sampleBuffer[i]) / Float(Int16.max)
        }

        audioPlayerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: { [weak self] in
            self?.scheduleBuffer(bufferIndex)
        })
    }
}