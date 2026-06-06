# Variosound tone model

Single source of truth for how the variometer sound behaves. The Android
(`AudioStreamLooper.java`) and iOS (`AudioStreamLooper.swift`) generators must
implement **exactly** this model — keep the constants below in sync.

## Principle

The plugin runs a **continuous real-time generator**: a free-running sample
clock fills small fixed buffers (1024 frames ≈ 23 ms). Every sample, the current
vertical speed (`vz`, m/s, smoothed) drives:

- **Pitch** — an exponential/musical mapping, so each m/s adds a constant
  musical interval (what the ear hears as "linear"):

  ```
  f(vz) = clamp(BASE_FREQ * 2^(vz / OCTAVE_PER), FREQ_MIN, FREQ_MAX)
  ```

- **Climb (vz ≥ 0) → beeping.** Cadence and duty cycle both rise with the climb
  rate, giving the familiar accelerating "ti…ti..ti.ti.tt":

  ```
  cadence(vz) = clamp(CAD_MIN + CAD_SLOPE * vz, CAD_MIN, CAD_MAX)   // beeps/s
  duty(vz)    = clamp(DUTY_MAX - DUTY_SLOPE * vz, DUTY_MIN, DUTY_MAX)
  period = 1 / cadence ;  onTime = period * duty
  ```

  A trapezoidal envelope (attack/release = `EDGE_S`) shapes each beep to avoid
  clicks.

- **Sink (vz < 0) → continuous tone**, pitch dropping with the sink rate (same
  `f(vz)`, no beeping).

`vz` is smoothed per-sample with a one-pole filter (`VZ_SMOOTH`) so changes are
glide, not jumps. The sine phase is accumulated continuously (never reset
mid-stream) so there are no discontinuities.

The **silent dead-band around 0** is handled by the app (it only calls
`play()`/`stop()` outside the user's climb/sink thresholds), so the generator
itself always produces a tone while playing.

## Weak-lift detector ("zérotage")

When the air rises just enough to offset the glider's own sink, the net `vz`
sits near zero — below the climb threshold — yet it marks usable lift. The app
detects this band (from a floor up to the climb threshold) and calls
`setWeakLift(true)`; the generator then **overrides** the sign-based tone with a
soft, slow, distinct blip (so it is never mistaken for a climb or a sink). Pitch
still follows `f(vz)`, so it rises gently as you approach climbing. The app
calls `setWeakLift(false)` outside the band.

| Constant    | Value | Meaning                                   |
|-------------|-------|-------------------------------------------|
| `WEAK_CAD`  | 1.2   | beeps/s (fixed, slow)                     |
| `WEAK_DUTY` | 0.22  | on-fraction (short blips)                 |
| `WEAK_AMP`  | 0.28  | output level (softer than the climb tone) |

## Constants (tune by ear)

| Constant      | Value  | Meaning                                   |
|---------------|--------|-------------------------------------------|
| `BASE_FREQ`   | 700    | Hz at 0 m/s                               |
| `OCTAVE_PER`  | 6.0    | m/s per octave (pitch doubles)            |
| `FREQ_MIN`    | 200    | Hz clamp (strong sink)                    |
| `FREQ_MAX`    | 1600   | Hz clamp (strong climb)                   |
| `CAD_MIN`     | 1.5    | beeps/s near 0                            |
| `CAD_MAX`     | 8.0    | beeps/s at strong climb                   |
| `CAD_SLOPE`   | 1.3    | beeps/s added per m/s                     |
| `DUTY_MAX`    | 0.55   | on-fraction near 0 (longer beeps)         |
| `DUTY_MIN`    | 0.30   | on-fraction at strong climb (crisp beeps) |
| `DUTY_SLOPE`  | 0.05   | on-fraction removed per m/s               |
| `AMPLITUDE`   | 0.45   | output level, 0..1 of full scale          |
| `VZ_SMOOTH`   | 0.0006 | per-sample one-pole coefficient (~38 ms)  |
| `EDGE_S`      | 0.006  | beep attack/release seconds (anti-click)  |

Sample rate is 44100 Hz on both platforms.
