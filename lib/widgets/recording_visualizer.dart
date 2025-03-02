import 'dart:math';
import 'package:flutter/material.dart';

class RecordingVisualizer extends StatefulWidget {
  final Stream<List<double>> fftStream;
  final bool isRecording;

  const RecordingVisualizer({
    super.key,
    required this.fftStream,
    required this.isRecording,
  });

  @override
  State<RecordingVisualizer> createState() => _RecordingVisualizerState();
}

class _RecordingVisualizerState extends State<RecordingVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final List<double> _amplitudes = List.filled(30, 0.0);
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    widget.fftStream.listen((frequencies) {
      if (mounted) {
        setState(() {
          // Update all bars directly with frequency data
          for (int i = 0; i < _amplitudes.length && i < frequencies.length; i++) {
            _amplitudes[i] = frequencies[i];
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RecordingVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _animationController.repeat(reverse: true);
      } else {
        _animationController.stop();
        _animationController.reset();
        if (mounted) {
          setState(() {
            _amplitudes.fillRange(0, _amplitudes.length, 0.0);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(
          _amplitudes.length,
          (index) {
            // Dynamic bar height with minimum value
            final barHeight = max(4.0, _amplitudes[index] * 100);
            
            // Color gradient based on frequency and amplitude
            final hue = (200 - (180 * index / _amplitudes.length)).clamp(0, 200).toDouble();
            final saturation = min(1.0, 0.3 + _amplitudes[index] * 0.7);
            final value = min(1.0, 0.5 + _amplitudes[index] * 0.5);
            final color = HSVColor.fromAHSV(0.9, hue, saturation, value).toColor();
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: 3,
                height: barHeight,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
