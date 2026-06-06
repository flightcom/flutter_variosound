package com.flightcom.variosound;

import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;

/**
 * Streams the {@link AudioStreamLooper} output to an {@link AudioTrack} from a
 * background thread. Setting the speed only updates a target value — the running
 * generator picks it up smoothly, so there is no restart or buffer resizing.
 */
public class ToneGenerator {

    private static final int BUFFER_FRAMES = 1024; // ~23 ms at 44.1 kHz

    private Thread mThread;
    private AudioTrack mAudioTrack;
    private final AudioStreamLooper looper = new AudioStreamLooper();
    private volatile boolean shouldPlay = false;

    public ToneGenerator() {
        initAudioTrack();
    }

    public void setSpeed(double v) {
        looper.setSpeed(v);
    }

    public void setWeakLift(boolean w) {
        looper.setWeakLift(w);
    }

    private void initAudioTrack() {
        int minBuffer = AudioTrack.getMinBufferSize(
                AudioStreamLooper.SAMPLE_RATE,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT);
        int bufferBytes = Math.max(minBuffer, BUFFER_FRAMES * 2 * 2);

        mAudioTrack = new AudioTrack(
                AudioManager.STREAM_MUSIC,
                AudioStreamLooper.SAMPLE_RATE,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT,
                bufferBytes,
                AudioTrack.MODE_STREAM);
    }

    private void play() {
        short[] buffer = new short[BUFFER_FRAMES];
        while (shouldPlay) {
            looper.fill(buffer);
            mAudioTrack.write(buffer, 0, buffer.length);
        }
    }

    public boolean playing() {
        return mThread != null;
    }

    public void startPlayback() {
        if (mThread != null
                || mAudioTrack.getState() != AudioTrack.STATE_INITIALIZED) {
            return;
        }
        mAudioTrack.flush();
        looper.reset();
        shouldPlay = true;
        mThread = new Thread(this::play);
        mThread.start();
        mAudioTrack.play();
    }

    public void stopPlayback() {
        if (mThread == null) return;
        shouldPlay = false;
        mThread = null;
        mAudioTrack.pause(); // stops playback immediately
        mAudioTrack.stop();  // unblocks a pending write()
        mAudioTrack.flush();
    }

    public Boolean stopIfPlaying() {
        if (playing()) {
            stopPlayback();
            return true;
        }
        return false;
    }

    public void release() {
        mAudioTrack.release();
    }
}
