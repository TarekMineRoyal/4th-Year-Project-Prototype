// lib/viewmodels/session_viewmodel.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/preference_service.dart'; // IMPORT THE NEW SERVICE

enum RecordingMode { frames, video }

class SessionViewModel extends ChangeNotifier {
  // --- DEPENDENCIES ---
  final ApiService _apiService = ApiService();
  final PreferenceService _preferenceService =
      PreferenceService(); // ADD THE SERVICE

  // --- STATE ---
  String? _sessionId;
  Timer? _recordingTimer;
  RecordingMode _currentMode = RecordingMode.frames;
  bool _isRecording = false;
  bool _isAskingQuestion = false;
  String _statusMessage = "Please start a session.";
  String? _currentAnswer;

  // --- Model and Mode State ---
  String? _selectedModel;
  String? _selectedMode;

  // --- GETTERS ---
  RecordingMode get currentMode => _currentMode;
  bool get isRecording => _isRecording;
  bool get isAskingQuestion => _isAskingQuestion;
  String get statusMessage => _statusMessage;
  String? get currentAnswer => _currentAnswer;
  String? get selectedModel => _selectedModel;
  String? get selectedMode => _selectedMode;

  // --- CONSTRUCTOR ---
  SessionViewModel() {
    // Load preferences when the ViewModel is first created.
    _loadPreferences();
  }

  // --- PRIVATE METHODS ---
  Future<void> _loadPreferences() async {
    _selectedModel = await _preferenceService.getLastSessionModel();
    // --- THIS LINE IS NOW CORRECTED ---
    _selectedMode = await _preferenceService.getLastAnalysisMode();
    notifyListeners();
  }

  // --- PUBLIC METHODS ---

  // Called from the UI to change the model
  Future<void> setModel(String? model) async {
    _selectedModel = model;
    if (model != null) {
      await _preferenceService.setLastSessionModel(model);
    }
    notifyListeners();
  }

  // Called from the UI to change the mode
  Future<void> setMode(String? mode) async {
    _selectedMode = mode;
    if (mode != null) {
      await _preferenceService.setLastAnalysisMode(mode);
    }
    notifyListeners();
  }

  Future<void> initializeSession() async {
    _statusMessage = "Initializing session...";
    _currentAnswer = null;
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

  Future<void> askQuestion(String question) async {
    if (_sessionId == null || question.isEmpty) return;
    if (_selectedModel == null || _selectedMode == null) {
      _currentAnswer = "Please select a model and mode first.";
      notifyListeners();
      return;
    }

    _isAskingQuestion = true;
    _currentAnswer = null;
    notifyListeners();

    try {
      final result = await _apiService.askQuestion(
        _sessionId!,
        question,
        _selectedModel!,
        _selectedMode!,
      );
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
