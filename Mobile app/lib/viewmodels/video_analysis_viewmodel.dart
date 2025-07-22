// lib/viewmodels/video_analysis_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/video_analysis_result.dart';
import '../services/api_service.dart';

class VideoAnalysisViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  VideoAnalysisResult? _analysisResult;
  bool _isLoading = false;
  String? _errorMessage;
  String _previousSceneDescription = ""; // State for AI memory

  VideoAnalysisResult? get analysisResult => _analysisResult;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Method to fetch the next scene analysis
  Future<void> analyzeNextFrame(String imagePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.getVideoAnalysisResult(
        imagePath,
        _previousSceneDescription,
        'gemini-2.5-flash-lite-preview-06-17',
      );

      _analysisResult = result;

      // CRITICAL STEP: Update the memory only if a significant change was described.
      if (result.hasChanged && result.descriptionOfChange.isNotEmpty) {
        _previousSceneDescription = result.descriptionOfChange;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to clear the memory when the user stops the live analysis
  void resetSceneMemory() {
    _previousSceneDescription = "";
    _analysisResult = null;
    _errorMessage = null;
    notifyListeners();
    print("Scene memory has been reset.");
  }
}
