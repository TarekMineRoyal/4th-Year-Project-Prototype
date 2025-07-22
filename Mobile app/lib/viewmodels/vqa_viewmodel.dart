// lib/viewmodels/vqa_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/vqa_result.dart';
import '../services/api_service.dart';

class VqaViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  VqaResult? _vqaResult;
  bool _isLoading = false;
  String? _errorMessage;
  // --- ADDED ---
  // State for the selected AI model. Defaults to Gemini.
  String _selectedModel = 'gemini-1.5-flash-latest';

  VqaResult? get vqaResult => _vqaResult;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedModel => _selectedModel; // <-- ADDED Getter

  // --- ADDED ---
  // Method to update the model from the UI.
  void setModel(String model) {
    _selectedModel = model;
    notifyListeners(); // Notify UI to rebuild if needed (e.g., to update a dropdown).
  }

  // --- MODIFIED ---
  // The 'fetchVqaResult' method now passes the selected model to the ApiService.
  Future<void> fetchVqaResult(String imagePath, String question) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Pass the currently selected model to the service.
      _vqaResult = await _apiService.getVqaResult(
        imagePath,
        question,
        _selectedModel,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
