import 'dart:async';
import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class VideoAnalysisScreen extends StatefulWidget {
  const VideoAnalysisScreen({super.key});

  @override
  State<VideoAnalysisScreen> createState() => _VideoAnalysisScreenState();
}

class _VideoAnalysisScreenState extends State<VideoAnalysisScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  bool _isProcessingFrame = false;

  // --- NEW: State management for TTS and scene memory ---
  bool _isSpeaking = false;
  String _previousSceneDescription =
      "This is the first frame, descripe everything.";

  Timer? _analysisTimer;
  final FlutterTts _flutterTts = FlutterTts();
  final TextEditingController _ipController =
      TextEditingController()..text = '10.0.2.2';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _setupTts();
  }

  // --- NEW: Setup TTS handlers ---
  void _setupTts() {
    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _flutterTts.setErrorHandler((msg) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _initializeCamera() async {
    // (Camera initialization logic remains the same)
    _cameras = await availableCameras();
    if (_cameras != null && _cameras!.isNotEmpty) {
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras![0],
      );
      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller!
          .initialize()
          .then((_) {
            if (!mounted) return;
            setState(() => _isCameraInitialized = true);
          })
          .catchError((e) => print('Error initializing camera: $e'));
    }
  }

  void _toggleAnalysis() {
    if (_isAnalyzing) {
      _analysisTimer?.cancel();
      if (mounted) setState(() => _isAnalyzing = false);
    } else {
      // Reset previous description when starting a new session
      _previousSceneDescription = "";
      if (mounted) setState(() => _isAnalyzing = true);
      _analysisTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        // The timer now only triggers the analysis
        _analyzeFrame();
      });
    }
  }

  Future<void> _analyzeFrame() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessingFrame ||
        _isSpeaking) {
      return;
    }

    if (mounted) setState(() => _isProcessingFrame = true);

    try {
      final XFile imageFile = await _controller!.takePicture();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://${_ipController.text}:8000/api/v1/video/'),
      );
      request.fields['previous_scene_description'] = _previousSceneDescription;
      request.fields['option'] = 'gemini-2.5-flash-preview-05-20';
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'),
        ),
      );

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody);
        final String answer = jsonResponse['answer'].trim();

        // --- CORRECTED LOGIC ---
        // Only speak and update memory if the response is NOT the keyword.
        if (answer != 'NO_CHANGE' && answer.isNotEmpty) {
          _flutterTts.speak(answer);
          // This now only happens when there is a new description.
          _previousSceneDescription = answer;
        }
      }
    } catch (e) {
      print("Error analyzing frame: $e");
    } finally {
      if (mounted) {
        setState(() => _isProcessingFrame = false);
      }
    }
  }

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // (The build method for the UI remains largely the same)
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: CameraPreview(_controller!)),
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _ipController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Server IP',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: InputBorder.none,
                      prefixIcon: Icon(Icons.network_wifi, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _toggleAnalysis,
                  icon: Icon(
                    _isAnalyzing
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline,
                  ),
                  label: Text(
                    _isAnalyzing ? 'Stop Analysis' : 'Start Analysis',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isAnalyzing ? Colors.red : Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                if (_isProcessingFrame || _isSpeaking)
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          _isSpeaking ? 'Speaking...' : 'Processing...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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
