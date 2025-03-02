import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import '../models/settings.dart';
import '../models/transcription.dart';
import '../services/audio_recorder.dart';
import '../services/transcription_service.dart';
import '../widgets/recording_visualizer.dart';

class RecordingScreen extends StatefulWidget {
  final WhisperSettings settings;
  final VoidCallback onHideWindow;
  final Function(RecordingScreen)? ref;
  _RecordingScreenState? _state;

  RecordingScreen({
    super.key,
    required this.settings,
    required this.onHideWindow,
    this.ref,
  });

  void toggleRecording() => _state?.toggleRecording();

  static Future<void> handleWindowClose(BuildContext context) async {
    bool? isConfirmed = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Close'),
        content: const Text('Are you sure you want to exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (isConfirmed == true) {
      await windowManager.destroy();
    }
  }

  @override
  State<RecordingScreen> createState() {
    final state = _RecordingScreenState();
    _state = state;
    return state;
  }
}

class _RecordingScreenState extends State<RecordingScreen> {
  final _audioRecorder = AudioRecorder();
  late final TranscriptionService _transcriptionService;
  TranscriptionState _recordingState = TranscriptionState.idle;
  String _transcribedText = '';
  String? _errorMessage;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _transcriptionService = TranscriptionService(widget.settings);
    widget.ref?.call(widget);
  }

  Future<void> toggleRecording() async {
    if (_recordingState == TranscriptionState.idle) {
      setState(() {
        _isRecording = true;
      });
      await _startRecording();
    } else if (_recordingState == TranscriptionState.recording) {
      setState(() {
        _isRecording = false;
      });
      await _stopRecordingAndTranscribe();
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _recordingState = TranscriptionState.recording;
        _transcribedText = '';
        _errorMessage = null;
      });

      await _audioRecorder.startRecording();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start recording: $e';
        _recordingState = TranscriptionState.error;
        _isRecording = false;
      });
    }
  }

  Future<void> _stopRecordingAndTranscribe() async {
    try {
      setState(() => _recordingState = TranscriptionState.processing);
      
      final audioData = await _audioRecorder.stopRecording();
      
      final response = await _transcriptionService.transcribeAudio(audioData);
      
      setState(() {
        _transcribedText = response.text;
        _recordingState = TranscriptionState.done;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Transcription failed: $e';
        _recordingState = TranscriptionState.error;
      });
      print(e);
    }
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _transcribedText));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Copied to clipboard')),
      );
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_recordingState == TranscriptionState.recording) ...[
                    const Text(
                      'Recording...',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const SizedBox(height: 20),
                    RecordingVisualizer(
                      fftStream: _audioRecorder.fftStream,
                      isRecording: _isRecording,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: toggleRecording,
                      icon: const Icon(Icons.stop),
                      label: const Text('Stop Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ] else if (_recordingState == TranscriptionState.processing) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    const Text(
                      'Processing...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ] else if (_recordingState == TranscriptionState.done) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _transcribedText,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy to Clipboard'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _recordingState = TranscriptionState.idle;
                              _transcribedText = '';
                            });
                          },
                          icon: const Icon(Icons.mic),
                          label: const Text('New Recording'),
                        ),
                      ],
                    ),
                  ] else if (_recordingState == TranscriptionState.error && _errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _recordingState = TranscriptionState.idle;
                          _transcribedText = '';
                          _errorMessage = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reset'),
                    ),
                  ] else if (_recordingState == TranscriptionState.idle) ...[
                    ElevatedButton.icon(
                      onPressed: toggleRecording,
                      icon: const Icon(Icons.mic),
                      label: const Text('Start Recording'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Press ${widget.settings.hotkeyCombo} to ${_recordingState == TranscriptionState.recording ? 'stop' : 'start'} recording',
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
