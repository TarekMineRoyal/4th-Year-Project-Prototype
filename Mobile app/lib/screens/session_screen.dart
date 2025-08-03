// lib/screens/session_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import '../viewmodels/session_viewmodel.dart';
import '../viewmodels/models_viewmodel.dart'; // Import ModelsViewModel

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
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    try {
      final image = await _cameraController!.takePicture();
      context.read<SessionViewModel>().processCapturedFrame(image.path);
    } catch (e) {
      print("Error capturing frame: $e");
    }
  }

  Future<void> _captureVideo() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isRecordingVideo) {
      return;
    }

    setState(() => _isRecordingVideo = true);

    try {
      await _cameraController!.startVideoRecording();
      await Future.delayed(const Duration(seconds: 5));
      final video = await _cameraController!.stopVideoRecording();
      context.read<SessionViewModel>().processCapturedClip(video.path);
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
          Expanded(flex: 3, child: _buildCameraPreview()),
          Expanded(flex: 2, child: _buildControlPanel(viewModel)),
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
            const SizedBox(height: 24),
            _buildModelSelectors(viewModel),
            const SizedBox(height: 16),
            _buildQuestionArea(viewModel),
            const SizedBox(height: 16),
            _buildAnswerDisplay(viewModel),
          ],
        ),
      ),
    );
  }

  // --- UPDATED WIDGET: Driven by SessionViewModel state ---
  Widget _buildModelSelectors(SessionViewModel sessionViewModel) {
    final modelsViewModel = context.watch<ModelsViewModel>();
    final vqaModels = modelsViewModel.models['VQA'] ?? [];

    if (modelsViewModel.isLoading) {
      return const Center(child: Text("Loading AI models..."));
    }
    if (modelsViewModel.errorMessage != null) {
      return Center(
        child: Text(
          "Error: ${modelsViewModel.errorMessage}",
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (vqaModels.isEmpty) {
      return const Center(child: Text("No QA models available from server."));
    }

    // Set default model in the ViewModel if it's not set
    if (sessionViewModel.selectedModel == null && vqaModels.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        sessionViewModel.setModel(vqaModels.first);
      });
    }

    return Row(
      children: [
        // Model Dropdown
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: sessionViewModel.selectedModel,
            decoration: const InputDecoration(
              labelText: 'AI Model',
              border: OutlineInputBorder(),
            ),
            items:
                vqaModels.map((model) {
                  return DropdownMenuItem(value: model, child: Text(model));
                }).toList(),
            onChanged: (value) => sessionViewModel.setModel(value),
          ),
        ),
        const SizedBox(width: 16),
        // Mode Dropdown
        Expanded(
          flex: 1,
          child: DropdownButtonFormField<String>(
            value: sessionViewModel.selectedMode?.replaceFirst(
              sessionViewModel.selectedMode![0],
              sessionViewModel.selectedMode![0].toUpperCase(),
            ),
            decoration: const InputDecoration(
              labelText: 'Mode',
              border: OutlineInputBorder(),
            ),
            items:
                _analysisModes.map((mode) {
                  return DropdownMenuItem(value: mode, child: Text(mode));
                }).toList(),
            onChanged:
                (value) => sessionViewModel.setMode(value?.toLowerCase()),
          ),
        ),
      ],
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
            onSubmitted: (_) => _submitQuestion(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: viewModel.isAskingQuestion ? null : _submitQuestion,
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
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
