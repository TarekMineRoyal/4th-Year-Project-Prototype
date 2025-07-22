// lib/screens/video_analysis_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../viewmodels/video_analysis_viewmodel.dart';

class VideoAnalysisScreen extends StatefulWidget {
  const VideoAnalysisScreen({super.key});

  @override
  _VideoAnalysisScreenState createState() => _VideoAnalysisScreenState();
}

class _VideoAnalysisScreenState extends State<VideoAnalysisScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  Timer? _timer;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // This logic is purely for the UI, so it stays in the View.
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await _controller!.initialize();
      if (mounted) {
        setState(() {}); // Update UI once camera is initialized
      }
    }
  }

  void _toggleAnalysis() {
    // This is UI-specific state management
    if (_isAnalyzing) {
      // Stop the timer and analysis
      _timer?.cancel();
      // Use context.read to call the reset method
      context.read<VideoAnalysisViewModel>().resetSceneMemory();
      setState(() {
        _isAnalyzing = false;
      });
    } else {
      // Start the analysis
      setState(() {
        _isAnalyzing = true;
      });
      // This is the simple timer-based trigger we discussed.
      // It can be replaced later with a motion-based trigger.
      _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _captureAndAnalyzeFrame();
      });
    }
  }

  Future<void> _captureAndAnalyzeFrame() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    // Prevents starting a new analysis if one is already in progress
    if (context.read<VideoAnalysisViewModel>().isLoading) return;

    try {
      final image = await _controller!.takePicture();
      // Call the ViewModel method with the captured image path
      context.read<VideoAnalysisViewModel>().analyzeNextFrame(image.path);
    } catch (e) {
      print("Error capturing frame: $e");
    }
  }

  @override
  void dispose() {
    // CRITICAL: Clean up resources when the screen is closed.
    _timer?.cancel();
    _controller?.dispose();
    // Reset the ViewModel state when leaving the screen
    // We use a post-frame callback to ensure the widget tree is no longer building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoAnalysisViewModel>().resetSceneMemory();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state changes from the ViewModel.
    final viewModel = context.watch<VideoAnalysisViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Scene Analysis"),
        backgroundColor: Colors.purple,
      ),
      body: Column(
        children: [
          // --- Camera Preview ---
          Expanded(
            child:
                _controller == null || !_controller!.value.isInitialized
                    ? const Center(child: CircularProgressIndicator())
                    : CameraPreview(_controller!),
          ),

          // --- Control and Status Panel ---
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black.withOpacity(0.7),
            child: Column(
              children: [
                // --- Reactive Result Display ---
                SizedBox(
                  height: 60,
                  child: Center(
                    child:
                        viewModel.isLoading &&
                                !_isAnalyzing // Show loading only on first analysis
                            ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                            : Text(
                              viewModel.analysisResult?.descriptionOfChange ??
                                  "Press 'Start Analysis' to begin.",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                  ),
                ),
                const SizedBox(height: 20),
                // --- Action Button ---
                ElevatedButton(
                  onPressed: _toggleAnalysis,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAnalyzing ? Colors.red : Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    _isAnalyzing ? "Stop Analysis" : "Start Analysis",
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
