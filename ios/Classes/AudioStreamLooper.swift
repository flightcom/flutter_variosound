import Foundation

class AudioStreamLooper {
    private let sampleRate = 44100
    private let K = 2.0 * Double.pi / 44100.0
    private var frequency: Double
    private var l: Double
    private var q: Double
    private var bufferSize: Int

    init() {
        frequency = 440.0
        l = 0.0
        q = 0.0
        bufferSize = 8192
        resetCounters()
    }

    func setBufferSize(bufferSize: Int) {
        self.bufferSize = bufferSize
    }

    func setFrequency(frequency: Double) {
        self.frequency = frequency
    }

    func resetCounters() {
        frequency = 440.0
        l = 0.0
        q = 0.0
    }

    private func updateCounters() {
        frequency += (frequency - frequency) / 4096.0
        l += (16384.0 - 3 * l) / 4096.0
        q += (q < Double.pi) ? frequency * K : (frequency * K) - (2.0 * Double.pi)
    }

    private func updateCounters2() {
        frequency += (frequency - frequency) / 4096.0
        l -= 3 * l / 4096.0
        q += (q < Double.pi) ? frequency * K : (frequency * K) - (2.0 * Double.pi)
    }

    private func genSineSample() -> Int16 {
        return Int16(round(sin(q) * l))
    }

    func getSampleBuffer(full: Bool) -> [Int16] {
        var sampleBuffer = [Int16](repeating: 0, count: bufferSize)

        for i in 0..<bufferSize {
            if i < bufferSize / 2 || full {
                updateCounters()
            } else {
                updateCounters2()
            }
            sampleBuffer[i] = genSineSample()
        }

        return sampleBuffer
    }
}
