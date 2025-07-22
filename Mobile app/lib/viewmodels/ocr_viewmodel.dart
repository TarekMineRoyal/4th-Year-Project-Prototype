// lib/viewmodels/ocr_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/ocr_result.dart';
import '../services/api_service.dart';

class OcrViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  OcrResult? _ocrResult;
  bool _isLoading = false;
  String? _errorMessage;

  OcrResult? get ocrResult => _ocrResult;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOcrResult(String imagePath) async {
    _isLoading = true;
    _errorMessage = null;
    _ocrResult = null; // Clear previous results before the new request
    notifyListeners();

    try {
      // The call is now simplified and no longer sends a model name.
      _ocrResult = await _apiService.getOcrResult(imagePath);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
