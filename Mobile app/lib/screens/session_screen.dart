// lib/screens/session_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../viewmodels/session_viewmodel.dart';
import '../viewmodels/models_viewmodel.dart';

class SessionScreen extends StatefulWidget {
  const SessionScreen({super.key});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  CameraController? _cameraController;
  final TextEditingController _questionController = TextEditingController();

  late final SessionViewModel _viewModel;
  bool _isRecordingVideo = false;

  final List<String> _analysisModes = ['Brief', 'Thorough'];

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<SessionViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.initializeSession();
    });

    _initializeCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _questionController.dispose();
    _viewModel.stopRecording();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print("Error initializing camera: $e");
    }
  }

  Future<void> _captureFrame() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    try {
      final image = await _cameraController!.takePicture();
      await context.read<SessionViewModel>().processCapturedFrame(image.path);
    } catch (e) {
      print("Error capturing frame: $e");
    }
  }

  Future<void> _captureVideo() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isRecordingVideo)
      return;
    setState(() => _isRecordingVideo = true);
    try {
      await _cameraController!.startVideoRecording();
      await Future.delayed(const Duration(seconds: 5));
      final video = await _cameraController!.stopVideoRecording();
      await context.read<SessionViewModel>().processCapturedClip(video.path);
    } catch (e) {
      print("Error capturing video: $e");
    } finally {
      setState(() => _isRecordingVideo = false);
    }
  }

  void _submitQuestion() {
    if (_questionController.text.isNotEmpty) {
      _viewModel.askQuestion(_questionController.text);
      _questionController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SessionViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text("Live Session Q&A")),
      body: Column(
        children: [
          // The camera preview is purely visual, but we label it for context.
          Expanded(
            child: Semantics(
              label: "Live camera view. The controls are below.",
              excludeSemantics: true,
              child: _buildCameraPreview(),
            ),
          ),
          // All controls are in a single, scrollable panel.
          Container(
            color: Colors.grey[200],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusDisplay(viewModel),
                    const SizedBox(height: 16),
                    _buildModeSwitcher(viewModel),
                    const SizedBox(height: 16),
                    _buildRecordButton(viewModel),
                    const SizedBox(height: 24),
                    _buildModelSelectors(viewModel),
                    const SizedBox(height: 16),
                    _buildQuestionArea(viewModel),
                    const SizedBox(height: 16),
                    _buildAnswerDisplay(viewModel),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_cameraController!);
  }

  Widget _buildStatusDisplay(SessionViewModel viewModel) {
    // This live region ensures that any status update is announced immediately.
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          viewModel.statusMessage,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildModeSwitcher(SessionViewModel viewModel) {
    return Semantics(
      label:
          "Recording Mode Selector. Current mode is ${viewModel.currentMode.name}.",
      child: SegmentedButton<RecordingMode>(
        segments: const [
          ButtonSegment(value: RecordingMode.frames, label: Text("Frames")),
          ButtonSegment(value: RecordingMode.video, label: Text("Video")),
        ],
        selected: {viewModel.currentMode},
        onSelectionChanged: (newSelection) {
          viewModel.switchMode(newSelection.first);
        },
      ),
    );
  }

  Widget _buildRecordButton(SessionViewModel viewModel) {
    return Semantics(
      label:
          viewModel.isRecording
              ? "Stop Recording Button"
              : "Start Recording Button",
      button: true,
      excludeSemantics: true,
      child: ElevatedButton.icon(
        icon: Icon(viewModel.isRecording ? Icons.stop : Icons.play_arrow),
        label: Text(
          viewModel.isRecording ? "Stop Recording" : "Start Recording",
        ),
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
      ),
    );
  }

  Widget _buildModelSelectors(SessionViewModel sessionViewModel) {
    final modelsViewModel = context.watch<ModelsViewModel>();
    final vqaModels = modelsViewModel.models['VQA'] ?? [];

    if (modelsViewModel.isLoading || vqaModels.isEmpty) {
      return const SizedBox.shrink();
    }

    if (sessionViewModel.selectedModel == null && vqaModels.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sessionViewModel.setModel(vqaModels.first);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: sessionViewModel.selectedModel,
          decoration: const InputDecoration(
            labelText: 'AI Model',
            border: OutlineInputBorder(),
          ),
          items:
              vqaModels
                  .map(
                    (model) =>
                        DropdownMenuItem(value: model, child: Text(model)),
                  )
                  .toList(),
          onChanged: (value) => sessionViewModel.setModel(value),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: sessionViewModel.selectedMode?.replaceFirst(
            sessionViewModel.selectedMode![0],
            sessionViewModel.selectedMode![0].toUpperCase(),
          ),
          decoration: const InputDecoration(
            labelText: 'Mode',
            border: OutlineInputBorder(),
          ),
          items:
              _analysisModes
                  .map(
                    (mode) => DropdownMenuItem(value: mode, child: Text(mode)),
                  )
                  .toList(),
          onChanged: (value) => sessionViewModel.setMode(value?.toLowerCase()),
        ),
      ],
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
            onSubmitted: (_) => _submitQuestion(),
          ),
        ),
        const SizedBox(width: 8),
        Semantics(
          label: "Submit Question Button",
          button: true,
          child: IconButton(
            icon: const Icon(Icons.send),
            onPressed: viewModel.isAskingQuestion ? null : _submitQuestion,
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerDisplay(SessionViewModel viewModel) {
    if (viewModel.isAskingQuestion) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: CircularProgressIndicator(),
      );
    }

    // This live region ensures the answer is announced as soon as it's received.
    return Semantics(
      liveRegion: true,
      child:
          viewModel.currentAnswer != null
              ? Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Answer: ${viewModel.currentAnswer}",
                  textAlign: TextAlign.center,
                ),
              )
              : const SizedBox.shrink(),
    );
  }
}
