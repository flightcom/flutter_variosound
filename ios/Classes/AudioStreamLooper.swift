import Foundation

/// Continuous real-time variometer tone generator (iOS).
///
/// Mirror of the Android `AudioStreamLooper.java`. See TONE.md for the model.
/// Keep the constants below in sync with the Android version.
class AudioStreamLooper {

    static let sampleRate = 44100.0
    private let twoPi = 2.0 * Double.pi

    // ---- Tunable tone model (mirror the Java constants) ----
    private let baseFreq = 700.0   // Hz at 0 m/s
    private let octavePer = 6.0    // m/s per octave
    private let freqMin = 200.0
    private let freqMax = 1600.0
    private let cadMin = 1.5        // beeps/s near 0
    private let cadMax = 8.0        // beeps/s at strong climb
    private let cadSlope = 1.3      // beeps/s per m/s
    private let dutyMax = 0.55      // on-fraction near 0
    private let dutyMin = 0.30      // on-fraction at strong climb
    private let dutySlope = 0.05    // per m/s
    private let amplitude = 0.45    // 0..1 of full scale
    private let vzSmooth = 0.0006   // per-sample one-pole
    private let edgeS = 0.006       // attack/release seconds (anti-click)

    // ---- Weak-lift detector ("zérotage"), mirror the Java constants ----
    private let weakCad = 1.2       // beeps/s (fixed, slow)
    private let weakDuty = 0.22     // short on-fraction
    private let weakAmp = 0.28      // softer than the climb tone

    private var targetSpeed = 0.0
    private var weakLift = false
    private var currentSpeed = 0.0
    private var phase = 0.0     // sine phase, radians
    private var beepClock = 0.0 // seconds into the current beep cycle

    func setSpeed(_ v: Double) {
        targetSpeed = v
    }

    /// Enables the soft weak-lift sound, overriding the climb/sink tone.
    func setWeakLift(_ w: Bool) {
        weakLift = w
    }

    /// Resets the generator for a clean (click-free) start from silence.
    func reset() {
        phase = 0.0
        beepClock = 0.0
        currentSpeed = targetSpeed
    }

    func fill(_ buffer: UnsafeMutablePointer<Float>, _ count: Int) {
        for i in 0..<count {
            currentSpeed += (targetSpeed - currentSpeed) * vzSmooth

            let f = clamp(baseFreq * pow(2.0, currentSpeed / octavePer),
                          freqMin, freqMax)
            phase += twoPi * f / AudioStreamLooper.sampleRate
            if phase >= twoPi { phase -= twoPi }

            var amp: Double
            var level = amplitude
            if weakLift {
                // Weak lift: soft, slow blip, overriding the sign-based tone.
                let period = 1.0 / weakCad
                let onTime = period * weakDuty
                beepClock += 1.0 / AudioStreamLooper.sampleRate
                if beepClock >= period { beepClock -= period }
                amp = envelope(beepClock, onTime)
                level = weakAmp
            } else if currentSpeed < 0.0 {
                // Sink: continuous tone.
                amp = 1.0
                beepClock = 0.0
            } else {
                // Climb: beeping, faster and crisper as the climb rate rises.
                let cadence = clamp(cadMin + cadSlope * currentSpeed, cadMin, cadMax)
                let period = 1.0 / cadence
                let duty = clamp(dutyMax - dutySlope * currentSpeed, dutyMin, dutyMax)
                let onTime = period * duty

                beepClock += 1.0 / AudioStreamLooper.sampleRate
                if beepClock >= period { beepClock -= period }
                amp = envelope(beepClock, onTime)
            }

            let sample = sin(phase) * amp * level
            buffer[i] = Float(clamp(sample, -1.0, 1.0))
        }
    }

    /// Trapezoidal beep envelope: attack, sustain, release, then silence.
    private func envelope(_ t: Double, _ onTime: Double) -> Double {
        if t >= onTime { return 0.0 }
        let edge = min(edgeS, onTime / 2.0)
        if t < edge { return t / edge }
        if t > onTime - edge { return (onTime - t) / edge }
        return 1.0
    }

    private func clamp(_ x: Double, _ lo: Double, _ hi: Double) -> Double {
        return x < lo ? lo : (x > hi ? hi : x)
    }
}
