import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../viewmodels/session_viewmodel.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  CameraController? _cameraController;
  final TextEditingController _questionController = TextEditingController();

  // --- SOLUTION PART 1: Add a member variable for the ViewModel ---
  // We use 'late final' because we promise to initialize it in initState
  // and it will never be changed afterwards.
  late final SessionViewModel _viewModel;

  bool _isRecordingVideo = false;

  @override
  void initState() {
    super.initState();

    // --- SOLUTION PART 2: Initialize the ViewModel reference here ---
    // The context is safe to use inside initState.
    _viewModel = context.read<SessionViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Now use the safe, stored reference to call the method.
      _viewModel.initializeSession();
    });

    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _questionController.dispose();

    // --- SOLUTION PART 3: Use the safe reference in dispose ---
    // We are no longer using the unsafe 'context' here.
    _viewModel.stopRecording();

    super.dispose();
  }

  /// Finds an available camera and sets up the CameraController.
  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;

    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    try {
      await _cameraController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  /// The function that will be passed to the ViewModel to handle frame capture.
  Future<void> _captureFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final image = await _cameraController!.takePicture();
      // It's fine to use context.read here because this method is only called
      // while the widget is active and recording.
      context.read<SessionViewModel>().processCapturedFrame(image.path);
    } catch (e) {
      print("Error capturing frame: $e");
    }
  }

  /// The function that will be passed to the ViewModel to handle video capture.
  Future<void> _captureVideo() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isRecordingVideo) {
      return;
    }

    setState(() {
      _isRecordingVideo = true;
    });

    try {
      await _cameraController!.startVideoRecording();
      await Future.delayed(const Duration(seconds: 5));
      final video = await _cameraController!.stopVideoRecording();
      context.read<SessionViewModel>().processCapturedClip(video.path);
    } catch (e) {
      print("Error capturing video: $e");
    } finally {
      setState(() {
        _isRecordingVideo = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // context.watch is the correct way to listen to changes in the build method.
    final viewModel = context.watch<SessionViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Live Session Q&A")),
      body: Column(
        children: [
          Expanded(flex: 3, child: _buildCameraPreview()),
          Expanded(flex: 2, child: _buildControlPanel(viewModel)),
        ],
      ),
    );
  }

  // --- Builder Methods (unchanged) ---

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_cameraController!);
  }

  Widget _buildControlPanel(SessionViewModel viewModel) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusDisplay(viewModel),
            const SizedBox(height: 16),
            _buildModeSwitcher(viewModel),
            const SizedBox(height: 16),
            _buildRecordButton(viewModel),
            const SizedBox(height: 16),
            _buildQuestionArea(viewModel),
            const SizedBox(height: 16),
            _buildAnswerDisplay(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDisplay(SessionViewModel viewModel) {
    return Text(
      viewModel.statusMessage,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildModeSwitcher(SessionViewModel viewModel) {
    return SegmentedButton<RecordingMode>(
      segments: const [
        ButtonSegment(value: RecordingMode.frames, label: Text("Frames")),
        ButtonSegment(value: RecordingMode.video, label: Text("Video")),
      ],
      selected: {viewModel.currentMode},
      onSelectionChanged: (newSelection) {
        viewModel.switchMode(newSelection.first);
      },
      style: ButtonStyle(
        foregroundColor: MaterialStateProperty.resolveWith<Color?>(
          (states) =>
              states.contains(MaterialState.disabled) ? Colors.grey : null,
        ),
      ),
    );
  }

  Widget _buildRecordButton(SessionViewModel viewModel) {
    return ElevatedButton.icon(
      icon: Icon(viewModel.isRecording ? Icons.stop : Icons.play_arrow),
      label: Text(viewModel.isRecording ? "Stop Recording" : "Start Recording"),
      onPressed: () {
        if (viewModel.isRecording) {
          viewModel.stopRecording();
        } else {
          viewModel.startRecording(
            onCaptureFrame: _captureFrame,
            onCaptureVideo: _captureVideo,
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: viewModel.isRecording ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
      ),
    );
  }

  Widget _buildQuestionArea(SessionViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _questionController,
            decoration: const InputDecoration(
              hintText: "Ask a question...",
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submitQuestion(viewModel),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed:
              viewModel.isAskingQuestion
                  ? null
                  : () => _submitQuestion(viewModel),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  void _submitQuestion(SessionViewModel viewModel) {
    if (_questionController.text.isNotEmpty) {
      viewModel.askQuestion(_questionController.text);
      _questionController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  Widget _buildAnswerDisplay(SessionViewModel viewModel) {
    if (viewModel.isAskingQuestion) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(),
      );
    }
    if (viewModel.currentAnswer != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          "Answer: ${viewModel.currentAnswer}",
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
