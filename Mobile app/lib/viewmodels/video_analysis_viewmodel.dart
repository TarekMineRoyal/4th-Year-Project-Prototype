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

  Future<void> analyzeNextFrame(String imagePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // The API call is simplified, as intended.
      final result = await _apiService.getVideoAnalysisResult(
        imagePath,
        _previousSceneDescription,
      );

      _analysisResult = result;

      // CORRECTED LOGIC: This uses the fields from your actual VideoAnalysisResult model.
      // It updates the memory only when a significant change is reported by the backend.
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

  void resetSceneMemory() {
    _previousSceneDescription = "";
    _analysisResult = null;
    _errorMessage = null;
    notifyListeners();
    print("Scene memory has been reset.");
  }
}
