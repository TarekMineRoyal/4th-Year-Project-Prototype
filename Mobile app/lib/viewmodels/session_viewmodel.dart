import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

// An enumeration to represent the two possible recording modes.
enum RecordingMode { frames, video }

class SessionViewModel extends ChangeNotifier {
  // --- Dependencies ---
  final ApiService _apiService = ApiService();

  // --- Private State Properties ---
  String? _sessionId;
  Timer? _recordingTimer;

  // --- Publicly Readable State ---

  RecordingMode _currentMode = RecordingMode.frames;
  RecordingMode get currentMode => _currentMode;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isAskingQuestion = false;
  bool get isAskingQuestion => _isAskingQuestion;

  String _statusMessage = "Please start a session.";
  String get statusMessage => _statusMessage;

  // THIS IS THE CORRECTED PART: We only store the most recent answer.
  String? _currentAnswer;
  String? get currentAnswer => _currentAnswer;

  // --- Public Methods (Use Cases) ---

  Future<void> initializeSession() async {
    _statusMessage = "Initializing session...";
    _currentAnswer = null; // Clear any previous answer
    notifyListeners();

    try {
      final result = await _apiService.startSession();
      _sessionId = result.sessionId;
      _statusMessage = "Session started. Ready to record.";
    } catch (e) {
      _statusMessage = "Error: Could not start session. Please try again.";
    }
    notifyListeners();
  }

  void switchMode(RecordingMode newMode) {
    if (_isRecording) {
      stopRecording();
    }
    _currentMode = newMode;
    _statusMessage = "Mode switched to ${_currentMode.name}. Ready to record.";
    notifyListeners();
  }

  void startRecording({
    required Function() onCaptureFrame,
    required Function() onCaptureVideo,
  }) {
    if (_sessionId == null) {
      _statusMessage = "Error: Session not initialized.";
      notifyListeners();
      return;
    }

    _isRecording = true;
    _statusMessage = "Recording started...";
    notifyListeners();

    final duration =
        _currentMode == RecordingMode.frames
            ? const Duration(seconds: 5)
            : const Duration(seconds: 5);

    _recordingTimer = Timer.periodic(duration, (timer) {
      if (!_isRecording) {
        timer.cancel();
        return;
      }
      if (_currentMode == RecordingMode.frames) {
        onCaptureFrame();
      } else {
        onCaptureVideo();
      }
    });
  }

  void stopRecording() {
    if (_recordingTimer?.isActive ?? false) {
      _recordingTimer!.cancel();
    }
    _recordingTimer = null;
    _isRecording = false;
    _statusMessage = "Recording paused.";
    notifyListeners();
    print(
      "Recording stopped and timer cancelled.",
    ); // Add a print statement for debugging
  }

  Future<void> processCapturedFrame(String imagePath) async {
    if (_sessionId == null) return;
    try {
      await _apiService.processFrame(_sessionId!, imagePath);
    } catch (e) {
      print("Failed to send frame: $e");
    }
  }

  Future<void> processCapturedClip(String videoPath) async {
    if (_sessionId == null) return;
    try {
      await _apiService.processClip(_sessionId!, videoPath);
    } catch (e) {
      print("Failed to send clip: $e");
    }
  }

  // THIS METHOD IS NOW SIMPLER
  Future<void> askQuestion(String question) async {
    if (_sessionId == null || question.isEmpty) return;

    _isAskingQuestion = true;
    _currentAnswer = null; // Clear the old answer while waiting for the new one
    notifyListeners();

    try {
      final result = await _apiService.askQuestion(_sessionId!, question);
      _currentAnswer = result.answer ?? "No answer received.";
    } catch (e) {
      _currentAnswer = "Error: Could not get answer.";
    }

    _isAskingQuestion = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    super.dispose();
  }
}
