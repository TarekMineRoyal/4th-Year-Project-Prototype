// lib/viewmodels/vqa_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/vqa_result.dart';
import '../services/api_service.dart';
import '../services/preference_service.dart'; // IMPORT THE NEW SERVICE

class VqaViewModel extends ChangeNotifier {
  // --- DEPENDENCIES ---
  final ApiService _apiService = ApiService();
  final PreferenceService _preferenceService =
      PreferenceService(); // ADD THE SERVICE

  // --- STATE ---
  VqaResult? _vqaResult;
  bool _isLoading = false;
  String? _errorMessage;

  // --- NEW: State for model and mode selection ---
  String? _selectedModel;
  String? _selectedMode;

  // --- GETTERS ---
  VqaResult? get vqaResult => _vqaResult;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedModel => _selectedModel;
  String? get selectedMode => _selectedMode;

  // --- CONSTRUCTOR ---
  VqaViewModel() {
    // Load saved preferences when the ViewModel is created
    _loadPreferences();
  }

  // --- PRIVATE METHODS ---
  Future<void> _loadPreferences() async {
    _selectedModel = await _preferenceService.getLastVqaModel();
    _selectedMode = await _preferenceService.getLastAnalysisMode();
    notifyListeners();
  }

  // --- PUBLIC METHODS ---

  // Called from the UI when the user selects a different model
  Future<void> setModel(String? model) async {
    _selectedModel = model;
    if (model != null) {
      await _preferenceService.setLastVqaModel(model);
    }
    notifyListeners();
  }

  // Called from the UI when the user selects a different mode
  Future<void> setMode(String? mode) async {
    _selectedMode = mode;
    if (mode != null) {
      await _preferenceService.setLastAnalysisMode(mode);
    }
    notifyListeners();
  }

  // UPDATED: The method now uses the internal state for model and mode.
  Future<void> fetchVqaResult(String imagePath, String question) async {
    if (_selectedModel == null || _selectedMode == null) {
      _errorMessage = "Please select a model and mode.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _vqaResult = null;
    notifyListeners();

    try {
      // Pass the selected model and mode from the internal state.
      _vqaResult = await _apiService.getVqaResult(
        imagePath,
        question,
        _selectedModel!,
        _selectedMode!,
      );
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
