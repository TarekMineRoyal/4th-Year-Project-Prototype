// lib/viewmodels/ocr_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/ocr_result.dart';
import '../services/api_service.dart';
import '../services/preference_service.dart'; // IMPORT THE NEW SERVICE

class OcrViewModel extends ChangeNotifier {
  // --- DEPENDENCIES ---
  final ApiService _apiService = ApiService();
  final PreferenceService _preferenceService =
      PreferenceService(); // ADD THE SERVICE

  // --- STATE ---
  OcrResult? _ocrResult;
  bool _isLoading = false;
  String? _errorMessage;

  // --- NEW: State for model selection ---
  String? _selectedModel;

  // --- GETTERS ---
  OcrResult? get ocrResult => _ocrResult;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedModel => _selectedModel;

  // --- CONSTRUCTOR ---
  OcrViewModel() {
    // Load saved preferences when the ViewModel is created
    _loadPreferences();
  }

  // --- PRIVATE METHODS ---
  Future<void> _loadPreferences() async {
    _selectedModel = await _preferenceService.getLastOcrModel();
    notifyListeners();
  }

  // --- PUBLIC METHODS ---

  // Called from the UI when the user selects a different model
  Future<void> setModel(String? model) async {
    _selectedModel = model;
    if (model != null) {
      await _preferenceService.setLastOcrModel(model);
    }
    notifyListeners();
  }

  // UPDATED: The method now uses the internal state for the model.
  Future<void> fetchOcrResult(String imagePath) async {
    if (_selectedModel == null) {
      _errorMessage = "Please select a model.";
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _ocrResult = null;
    notifyListeners();

    try {
      // Pass the selected model from the internal state to the ApiService.
      _ocrResult = await _apiService.getOcrResult(imagePath, _selectedModel!);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
