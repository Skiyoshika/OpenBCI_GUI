# Modularized OpenBCI GUI Sources

This folder provides a lightweight view of the code for two areas:

* **core_signal** – acquisition, buffering, and waveform visualization.
* **extra_features** – impedance testing, packet-loss monitoring, and radio/Bluetooth connection helpers.

The files are direct copies of the Processing sources in `OpenBCI_GUI/`. They are not compiled separately, but they give you an
isolated view of the logic you can reuse when bringing the signal pipeline into another project such as QNMDsol.

### Core signal pipeline
The `core_signal` folder contains the classes that handle board abstractions (`Board*.pde`), data pipelines (`DataProcessing.pde`, `Buffer.pde`, `DataSource*.pde`), and UI widgets for time-domain and FFT displays (`W_TimeSeries.pde`, `W_FFT.pde`).

核心信号链包括板卡适配、数据读取/滤波，以及时间域和频域波形显示。你可以单独复制这些文件嵌入到其他 Processing/Java 项目里，只要确保依赖（Processing runtime、BrainFlow、Minim）可用即可。

### Extra features
The `extra_features` folder groups non-essential features like impedance measurement (`ImpedanceSettingsBoard.pde`, `CytonImpedanceEnums.pde`, `W_CytonImpedance.pde`, `W_GanglionImpedance.pde`), packet loss visualization (`W_PacketLoss.pde`), and connection utilities (`InterfaceSerial.pde`, `RadioConfig.pde`).

Because the files are copies, any changes here will not affect the main GUI unless you manually sync them back. This layout is meant to help you quickly explore or extract the relevant pieces while debugging crashes during acquisition in QNMDsol.

## How to embed in another app
1. Copy the files from `core_signal` into your Processing/Java project and keep the dependencies they rely on: BrainFlow, Minim (`ddf.minim`), and the Processing runtime.
2. Re-create the small set of globals the widgets expect (for example `currentBoard`, `nchan`, and the filter settings used in `DataProcessing`). Reviewing `OpenBCI_GUI/OpenBCI_GUI.pde` can help you mirror the initialization order.
3. Use `processNewData()` and the existing buffer helpers as the model for pulling frames from your board or simulator. The widgets read from `dataProcessingFilteredBuffer` and `fftBuff` once you keep them filled.
4. If you are embedding only the visuals, you can bypass the board layer by directly calling `W_TimeSeries.draw()` and `W_FFT.draw()` with your own data arrays after you set their buffers.

## One-call “universal port”
`core_signal/SignalEmbedPort.pde` is a thin bridge you can drop into another project. It exposes a minimal API:

* `beginStream()` / `endStream()` – start or stop your chosen `StreamController` (wraps a board, playback source, or your own data feeder).
* `pushTimeSeries(data, sampleRateHz)` – deliver a ready-to-plot time-domain block to your `SignalConsumer` (e.g., wired to `W_TimeSeries`).
* `pushFFT(magnitudes, sampleRateHz)` – deliver FFT magnitudes to your `SignalConsumer` (e.g., wired to `W_FFT`).
* `updateController(...)` / `updateConsumer(...)` – 热插拔底层采集源或输出端，不用重新实例化端口对象，便于在 QNMDsol 里切换“播放 → 实机 → 回放”。

Implement the `StreamController` and `SignalConsumer` interfaces to connect the existing OpenBCI classes to your host app. This gives you a single call site to start/stop streaming and to push data into the reused widgets without pulling in the rest of the GUI shell.

### Quick embed snippet (示例)
```java
// 在宿主应用里提前准备好控制器和消费者
SignalEmbedPort.StreamController controller = new SignalEmbedPort.StreamController() {
    public void start() { /* 打开板卡或启动回放 */ }
    public void stop()  { /* 关闭资源 */ }
};

SignalEmbedPort.SignalConsumer consumer = new SignalEmbedPort.SignalConsumer() {
    public void onTimeSeries(float[][] data_uV, float sampleRateHz) {
        // 将数据写入你的 W_TimeSeries 或自定义绘图逻辑
    }

    public void onFFT(float[][] fftMagnitudes, float sampleRateHz) {
        // 同理，将 FFT 数据送入 W_FFT 或其他分析模块
    }
};

SignalEmbedPort port = new SignalEmbedPort(controller, consumer);
port.beginStream();
// ……当你需要切换数据源或输出端时：
port.updateController(otherController);
port.updateConsumer(otherConsumer);
```
