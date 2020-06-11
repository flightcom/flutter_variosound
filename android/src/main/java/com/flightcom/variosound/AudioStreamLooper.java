package com.flightcom.variosound;

public class AudioStreamLooper {

    private static final String LOG_TAG = AudioStreamLooper.class.getSimpleName();

    // NOTE: this is hardcoded for simplicity,
    // you should get this value from AudioManager since it's device dependent
    public static final int SAMPLE_RATE = 44100;

    private static final double K = 2.0 * Math.PI / SAMPLE_RATE;

    private double f;
    private double l = 0.0;
    private double q = 0.0;

    private double _frequency = 440.0;
    private int _bufferSize = 8192;

    public void setBufferSize(int v){
        _bufferSize = v;
    }

    public void setFrequency(double v){
        _frequency = v;
    }

    /**
     *
     */
    public AudioStreamLooper(){
        resetCounters();
    }

    // -------------- privs

    private void resetCounters(){
        f = _frequency;
        l = 0.0;
        q = 0.0;
    }

    private void updateCounters(){
        f += (_frequency - f) / 4096.0;
        l += (16384.0 - 3*l) / 4096.0;
        q += (q < Math.PI) ? f * K : (f * K) - (2.0 * Math.PI);
    }

    private void updateCounters2(){
        f += (_frequency - f) / 4096.0;
        l -= 3*l / 4096.0;
        q += (q < Math.PI) ? f * K : (f * K) - (2.0 * Math.PI);
    }


    private short genSineSample(){
        return (short) Math.round(Math.sin(q) * l);
    }

    // -------------- publics

    public void reset(){
        resetCounters();
    }

    public short[] getSampleBuffer(boolean full){
        // short[] sampleBuffer = new short[_bufferSize*2];
        short[] sampleBuffer = new short[_bufferSize];

        int k = 0;
        for(int i = 0; i < _bufferSize; i++){

            if (i < _bufferSize/2 || full) {
                updateCounters();
            } else {
                updateCounters2();
            }
            short val = genSineSample();
            sampleBuffer[k] = val;
            // sampleBuffer[k+1] = val;
            // k += 2;
            k += 1;
        }

        return sampleBuffer;
    }
}
