package com.flightcom.variosound;

import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTrack;
import android.util.Log;

public class ToneGenerator {

    private static final String LOG_TAG = ToneGenerator.class.getSimpleName();

    private Thread mThread;
    private short[] mBuffer;
    private int duration = 1000; // ms
    private AudioTrack mAudioTrack;
    private AudioStreamLooper looper;
    private boolean shouldPlay = false;
    private double speed;
    private int mBufferSize;

    public void setFrequency(double v){
        looper.setFrequency(v);
    }

    public void setDuration(int v){
        duration = v;
    }

    public void setSpeed(double v) {
        speed = v;
        double frequency = 3 * Math.pow(v + 10, 2) + 200;
        duration = (int) (v >= 0.0 ? 200 + 400 / (v + 1) : 200);
        looper.setFrequency(frequency);

        mBufferSize = AudioStreamLooper.SAMPLE_RATE * duration / 1000;
        mAudioTrack.setBufferSizeInFrames(mBufferSize);
        looper.setBufferSize(mBufferSize);
    }

    /**
     *
     */
    public ToneGenerator(){
        looper = new AudioStreamLooper();
        initAudioTrack();
    }

    // -------- privs

    private void initAudioTrack(){

        mBufferSize = AudioStreamLooper.SAMPLE_RATE * duration / 1000;

        mAudioTrack = new AudioTrack(
            AudioManager.STREAM_MUSIC,
            AudioStreamLooper.SAMPLE_RATE,
            AudioFormat.CHANNEL_OUT_MONO,
            // AudioFormat.CHANNEL_OUT_STEREO,
            AudioFormat.ENCODING_PCM_16BIT,
            mBufferSize,
            AudioTrack.MODE_STREAM
        );

        looper.setBufferSize(mBufferSize);
    }

    private synchronized void resumePlay(){
        try {
            wait(500);
            play();
        }
        catch (Exception e){
            Log.v(LOG_TAG, "error waiting process: " +e.toString());
        }
    }

    private void play(){

        Log.v(LOG_TAG, "Starting tone");
        looper.reset();

        while (shouldPlay) {
            short[] buffer = looper.getSampleBuffer(speed < 0);

            for(int i = 0; i < mBufferSize; i++){
                mAudioTrack.write(buffer, i, 1);
            }
            // mAudioTrack.write(buffer, 0, buffer.length);

        }
    }

    // -------- publics

    public boolean playing() {
        return mThread != null;
    }

    public void startPlayback(){
        if (mThread != null || mAudioTrack.getState() != AudioTrack.STATE_INITIALIZED) return;

        mAudioTrack.flush();

        // Start streaming in a thread
        shouldPlay = true;
        mThread = new Thread(new Runnable() {
            @Override
            public void run() {
                play();
            }
        });

        mThread.start();
        mAudioTrack.play();
    }

    public void stopPlayback() {

        if (mThread == null) return;

        shouldPlay = false;
        mThread = null;

        mAudioTrack.pause();  // pause() stops the playback immediately.
        mAudioTrack.stop();   // Unblock mAudioTrack.write() to avoid deadlocks.
        mAudioTrack.flush();  // just in case...
    }

    public Boolean stopIfPlaying(){

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

