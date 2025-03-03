import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fftea/fftea.dart';

class AudioRecorder {
  final _audioRecorder = Record();
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  String? _currentRecordingPath;
  final _fftController = StreamController<List<double>>.broadcast();
  final _amplitudeController = StreamController<double>.broadcast();

  // FFT configuration
  static const int fftSize = 128; // Smaller size for faster updates
  static const int sampleRate = 16000;
  final _fft = FFT(fftSize);
  final _window = Window.hanning(fftSize);
  final _frequencies = List<double>.filled(30, 0.0);
  final _amplitudeHistory = List<double>.filled(fftSize, 0.0);
  final _smoothedFrequencies = List<double>.filled(30, 0.0);
  int _historyIndex = 0;

  Stream<List<double>> get fftStream => _fftController.stream;
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  Future<bool> checkPermission() async {
    if (Platform.isMacOS) {
      return await Permission.microphone.request().isGranted;
    }

    final status = await Permission.microphone.status;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  Future<void> startRecording() async {
    if (!await checkPermission()) {
      throw Exception('Microphone permission not granted');
    }

    // Get temporary directory for storing recording
    final tempDir = await getTemporaryDirectory();
    _currentRecordingPath = '${tempDir.path}/temp_recording.wav';

    // Configure recording
    await _audioRecorder.start(
      path: _currentRecordingPath,
      encoder: AudioEncoder.wav,
      samplingRate: sampleRate,
      numChannels: 1,
      bitRate: 128000,
    );

    // Start monitoring amplitude
    _amplitudeSubscription = _audioRecorder
        .onAmplitudeChanged(const Duration(milliseconds: 30))
        .listen((amp) {
          _amplitudeController.add(amp.current);
          _processAmplitude(amp.current);
        });
  }

  Future<String> stopRecording() async {
    _amplitudeSubscription?.cancel();
    await _audioRecorder.stop();

    if (_currentRecordingPath == null) {
      throw Exception('No recording found');
    }

    final file = File(_currentRecordingPath!);
    if (!await file.exists()) {
      throw Exception('Recording file not found');
    }

    // Read file and convert to base64
    final bytes = await file.readAsBytes();
    final base64Audio = base64Encode(bytes);

    // Clean up
    await file.delete();
    _currentRecordingPath = null;

    return base64Audio;
  }

  void _processAmplitude(double amplitude) {
    // Add amplitude to history buffer
    // Scale amplitude for better visualization
    _amplitudeHistory[_historyIndex] = amplitude * 2.0;
    _historyIndex = (_historyIndex + 1) % fftSize;

    // When we have enough samples, perform FFT
    if (_historyIndex == 0) {
      // Create samples and apply window
      final samples = Float64List(fftSize);
      for (int i = 0; i < fftSize; i++) {
        samples[i] = _amplitudeHistory[i] * _window[i];
      }

      // Perform FFT
      final spectrum = _fft.realFft(samples);

      // Process frequency bands
      for (int i = 0; i < _frequencies.length; i++) {
        // Calculate magnitude for this frequency band
        var sum = 0.0;
        final bandSize = spectrum.length ~/ (2 * _frequencies.length);
        final startBin = i * bandSize;
        final endBin = startBin + bandSize;

        for (
          var bin = startBin;
          bin < endBin && bin < spectrum.length ~/ 2;
          bin++
        ) {
          final value = spectrum[bin];
          sum += sqrt(value.x * value.x + value.y * value.y);
        }

        // Apply stronger smoothing for more stable visualization
        _smoothedFrequencies[i] =
            _smoothedFrequencies[i] * 0.6 + (sum / bandSize) * 0.4;
        _frequencies[i] = _smoothedFrequencies[i];
      }

      // Normalize with enhanced low frequency response
      final maxValue = _frequencies.reduce(max);
      if (maxValue > 0) {
        final normalizedFrequencies = List<double>.filled(30, 0.0);
        for (int i = 0; i < _frequencies.length; i++) {
          // Apply frequency-dependent scaling
          // Enhanced frequency scaling
          double freqScale;
          if (i < 5) {
            freqScale = 1.4; // Bass boost
          } else if (i < 15) {
            freqScale = 1.2;
          } // Mid boost
          else {
            freqScale = 1.0;
          }

          // Apply non-linear scaling for better dynamics
          final value = _frequencies[i] / maxValue;
          normalizedFrequencies[i] = min(1.0, pow(value, 0.7) * freqScale);
        }
        _fftController.add(normalizedFrequencies);
      }
    }
  }

  Future<void> dispose() async {
    _amplitudeSubscription?.cancel();
    _amplitudeController.close();
    _fftController.close();
    _audioRecorder.dispose();
  }

  Future<bool> get isRecording => _audioRecorder.isRecording();
}
