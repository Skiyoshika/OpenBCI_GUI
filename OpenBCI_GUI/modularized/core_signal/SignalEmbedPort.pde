// Universal entry point for embedding the core OpenBCI signal pipeline.
// This file is intentionally small and dependency-free so it can be copied
// into another Processing/Java project as a thin bridge. Wire it up to the
// existing Board / DataProcessing / Widget classes by feeding data into the
// callbacks below.

class SignalEmbedPort {
    public interface SignalConsumer {
        // Called whenever a block of time-domain data is available (in microvolts).
        void onTimeSeries(float[][] data_uV, float sampleRateHz);

        // Called whenever an FFT block is ready. Magnitude is expected.
        void onFFT(float[][] fftMagnitudes, float sampleRateHz);
    }

    public interface StreamController {
        // Start the underlying board or data replay.
        void start();
        // Stop the underlying board or data replay and release resources.
        void stop();
    }

    private StreamController controller;
    private SignalConsumer consumer;
    private boolean running = false;

    SignalEmbedPort(StreamController controller, SignalConsumer consumer) {
        this.controller = controller;
        this.consumer = consumer;
    }

    // Swap the controller at runtime (e.g., from playback to live board) without
    // changing the calling code that owns the port instance.
    public void updateController(StreamController controller) {
        this.controller = controller;
    }

    // Swap the consumer at runtime (e.g., route output to another widget).
    public void updateConsumer(SignalConsumer consumer) {
        this.consumer = consumer;
    }

    // Expose a single place to start streaming from another application.
    public void beginStream() {
        if (controller != null && !running) {
            controller.start();
            running = true;
        }
    }

    // Expose a single place to stop streaming from another application.
    public void endStream() {
        if (controller != null && running) {
            controller.stop();
            running = false;
        }
    }

    // Push a block of new samples (time-domain) into the consumer.
    public void pushTimeSeries(float[][] data_uV, float sampleRateHz) {
        if (consumer != null) consumer.onTimeSeries(data_uV, sampleRateHz);
    }

    // Push FFT magnitudes into the consumer (e.g., from W_FFT). Use this if
    // you compute the FFT elsewhere but want to reuse the visualization.
    public void pushFFT(float[][] fftMagnitudes, float sampleRateHz) {
        if (consumer != null) consumer.onFFT(fftMagnitudes, sampleRateHz);
    }
}
