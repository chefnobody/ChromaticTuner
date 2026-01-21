# ChromaticTuner

An iOS app that listens to musical instruments and detects chords in real-time.

## Features

- Real-time chord detection using FFT analysis
- Frequency spectrum visualization
- Support for Major and Minor chords
- Clean SwiftUI interface
- Protocol-based architecture with dependency injection

## Setup Instructions

### Option 1: Using XcodeGen (Recommended)

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```

2. Generate the Xcode project:
   ```bash
   cd /Users/aaron/workspace/ChromaticTuner
   xcodegen generate
   ```

3. Open the generated project:
   ```bash
   open ChromaticTuner.xcodeproj
   ```

### Option 2: Manual Xcode Setup

1. Open Xcode
2. Select "File" → "New" → "Project"
3. Choose "iOS" → "App"
4. Set:
   - Product Name: ChromaticTuner
   - Interface: SwiftUI
   - Language: Swift
   - Save location: `/Users/aaron/workspace/ChromaticTuner`
5. Delete the automatically created ContentView.swift and ChromaticTunerApp.swift
6. In Xcode, select "File" → "Add Files to ChromaticTuner"
7. Select the entire `ChromaticTuner` folder (not the root folder)
8. In the project settings:
   - Select the ChromaticTuner target
   - Go to "Info" tab
   - Set "Custom iOS Target Properties" and add Info.plist from ChromaticTuner/App/Info.plist
   - Go to "Build Settings" and set Info.plist File path to: ChromaticTuner/App/Info.plist

## Running the App

1. Connect an iOS device or select a simulator
2. Build and run (Cmd+R)
3. Grant microphone permissions when prompted
4. Tap "Start" to begin chord detection
5. Play a chord on your guitar or other instrument
6. The app will display the detected chord and frequency spectrum

## Architecture

```
UI Layer (SwiftUI Views)
    ↓
ViewModel (ChordDetectionViewModel)
    ↓
ChordDetectionService (Coordinator)
    ↓
├── AudioCaptureService (AVAudioEngine)
├── PitchDetector (FFT + Frequency Analysis)
└── ChordRecognizer (Pattern Matching)
```

## Technical Details

- **Sample Rate**: 44.1 kHz
- **FFT Size**: 4096 samples
- **Frequency Resolution**: ~10.8 Hz per bin
- **Detection Range**: 60-2000 Hz
- **Update Rate**: ~43 Hz (23ms intervals)
- **Supported Chords**: Major, Minor

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Physical device or simulator with microphone access

## Troubleshooting

### Microphone Permission Issues
- Go to Settings → Privacy & Security → Microphone
- Enable access for ChromaticTuner

### Build Errors
- Ensure all frameworks are linked (AVFoundation, Accelerate, Combine)
- Check that Info.plist path is correctly set in Build Settings
- Clean build folder (Cmd+Shift+K) and rebuild

## Future Enhancements

- Extended chord types (7ths, suspended, augmented, diminished)
- Single note tuner mode
- Chord progression recording
- Alternative tunings support
- Settings for sensitivity adjustment

## Fundamental Concepts and Tools

1. `AVFoundation` receives monophonic (single instrument) audio from on-device mic.
2. Fast Fourier Transform  converts audio data in Time series to frequencies.
   * Lots of math.
   * Espeically, [windowing functions](https://en.wikipedia.org/wiki/Window_function). These are mathmetical means of detecting information from data within a "window" of some other series of data.
   * Output is called a spectrogram which is a visual "comb" in which each "harmonic" can be seen.
     * **Question:** What is a harmonic? (see below)
3. [Harmonic Product Spectrum (HPS)](http://musicweb.ucsd.edu/~trsmyth/analysis/Harmonic_Product_Spectrum.html)
   * The process of detecting harmonics from the spectrum produced by the FFT.
   * Harmonics are composites (or groups) of sound vibrations ocurring at differing frequencies. Sometimes called "partials".
     * _"When a single key is pressed upon a piano, what we hear is not just one frequency of sound vibration, but a composite of multiple sound vibrations occurring at different mathematically related frequencies."_
     * _"The elements of this composite of vibrations at differing frequencies are referred to as harmonics or partials."_
4. [Pitch Detection](https://en.wikipedia.org/wiki/Transcription_(music)#Pitch_detection)
   * _"A 'pitch' is not a single vibration, such as a sine wave, but is a composite of multiple sound vibrations occurring at different mathematically related frequencies."_ ([Source](https://dsp.stackexchange.com/questions/25350/pitch-detection-harmonic-product-spectrum-whats-wrong))