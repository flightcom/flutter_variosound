package com.flightcom.variosound;

/**
 * Continuous real-time variometer tone generator.
 *
 * A free-running sample clock fills fixed-size buffers; every sample the current
 * (smoothed) vertical speed drives the pitch and, when climbing, the beep
 * cadence and duty cycle. See TONE.md for the model. Keep the constants in sync
 * with the iOS version (AudioStreamLooper.swift).
 */
public class AudioStreamLooper {

    public static final int SAMPLE_RATE = 44100;
    private static final double TWO_PI = 2.0 * Math.PI;

    // ---- Tunable tone model (edit to taste; mirror in Swift) ----
    static final double BASE_FREQ = 700.0;   // Hz at 0 m/s
    static final double OCTAVE_PER = 6.0;    // m/s per octave
    static final double FREQ_MIN = 200.0;
    static final double FREQ_MAX = 1600.0;
    static final double CAD_MIN = 1.5;       // beeps/s near 0
    static final double CAD_MAX = 8.0;       // beeps/s at strong climb
    static final double CAD_SLOPE = 1.3;     // beeps/s per m/s
    static final double DUTY_MAX = 0.55;     // on-fraction near 0
    static final double DUTY_MIN = 0.30;     // on-fraction at strong climb
    static final double DUTY_SLOPE = 0.05;   // per m/s
    static final double AMPLITUDE = 0.45;    // 0..1 of full scale
    static final double VZ_SMOOTH = 0.0006;  // per-sample one-pole
    static final double EDGE_S = 0.006;      // attack/release seconds (anti-click)

    // ---- Weak-lift detector ("zérotage") ----
    // A soft, slow, distinct blip for when the air is lifting just enough to
    // offset the glider's own sink (net vz near zero, below the climb
    // threshold). The app turns it on inside that band; see TONE.md.
    static final double WEAK_CAD = 1.2;      // beeps/s (fixed, slow)
    static final double WEAK_DUTY = 0.22;    // short on-fraction
    static final double WEAK_AMP = 0.28;     // softer than the climb tone

    private volatile double targetSpeed = 0.0;
    private volatile boolean weakLift = false;
    private double currentSpeed = 0.0;
    private double phase = 0.0;     // sine phase, radians
    private double beepClock = 0.0; // seconds into the current beep cycle

    public void setSpeed(double v) {
        targetSpeed = v;
    }

    /** Enables the soft weak-lift sound, overriding the climb/sink tone. */
    public void setWeakLift(boolean w) {
        weakLift = w;
    }

    /** Resets the generator for a clean (click-free) start from silence. */
    public void reset() {
        phase = 0.0;
        beepClock = 0.0;
        currentSpeed = targetSpeed;
    }

    public void fill(short[] buffer) {
        for (int i = 0; i < buffer.length; i++) {
            currentSpeed += (targetSpeed - currentSpeed) * VZ_SMOOTH;

            double f = clamp(BASE_FREQ * Math.pow(2.0, currentSpeed / OCTAVE_PER),
                    FREQ_MIN, FREQ_MAX);
            phase += TWO_PI * f / SAMPLE_RATE;
            if (phase >= TWO_PI) phase -= TWO_PI;

            double amp;
            double level = AMPLITUDE;
            if (weakLift) {
                // Weak lift: soft, slow blip, overriding the sign-based tone.
                double period = 1.0 / WEAK_CAD;
                double onTime = period * WEAK_DUTY;
                beepClock += 1.0 / SAMPLE_RATE;
                if (beepClock >= period) beepClock -= period;
                amp = envelope(beepClock, onTime);
                level = WEAK_AMP;
            } else if (currentSpeed < 0.0) {
                // Sink: continuous tone.
                amp = 1.0;
                beepClock = 0.0;
            } else {
                // Climb: beeping, faster and crisper as the climb rate rises.
                double cadence =
                        clamp(CAD_MIN + CAD_SLOPE * currentSpeed, CAD_MIN, CAD_MAX);
                double period = 1.0 / cadence;
                double duty =
                        clamp(DUTY_MAX - DUTY_SLOPE * currentSpeed, DUTY_MIN, DUTY_MAX);
                double onTime = period * duty;

                beepClock += 1.0 / SAMPLE_RATE;
                if (beepClock >= period) beepClock -= period;
                amp = envelope(beepClock, onTime);
            }

            double sample = Math.sin(phase) * amp * level;
            buffer[i] = (short) Math.round(clamp(sample, -1.0, 1.0) * 32767.0);
        }
    }

    /** Trapezoidal beep envelope: attack, sustain, release, then silence. */
    private static double envelope(double t, double onTime) {
        if (t >= onTime) return 0.0;
        double edge = Math.min(EDGE_S, onTime / 2.0);
        if (t < edge) return t / edge;
        if (t > onTime - edge) return (onTime - t) / edge;
        return 1.0;
    }

    private static double clamp(double x, double lo, double hi) {
        return x < lo ? lo : (x > hi ? hi : x);
    }
}
