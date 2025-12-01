//! Rust rewrite of the OpenBCI "modelize" signal pipeline.
//!
//! The crate keeps the responsibilities small so it can be embedded directly into another
//! Rust GUI: feed it batched samples, ask for a rolling window of time-domain data, request
//! an FFT spectrum, and optionally render lightweight PNG plots for quick previews.

pub mod buffer;
pub mod error;
pub mod fft;
pub mod pipeline;
pub mod plot;
pub mod source;

pub use buffer::{SignalBuffer, TimeSeriesFrame};
pub use error::ModelizeError;
pub use fft::{FrequencySpectrum, SpectrumBuilder};
pub use pipeline::SignalPipeline;
pub use plot::{PlotStyle, render_spectrum_png, render_waveform_png};
pub use source::{ManualSource, SignalBatch, SignalSource};
