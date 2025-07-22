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
    notifyListeners();

    try {
      _ocrResult = await _apiService.getOcrResult(imagePath, 'gemini-2.5-pro');
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
