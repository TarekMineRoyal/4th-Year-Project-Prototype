// Mobile app/lib/viewmodels/vqa_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/vqa_result.dart';
import '../services/api_service.dart';
// The import for feature_config.dart is REMOVED as it's no longer needed.

class VqaViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  VqaResult? _vqaResult;
  bool _isLoading = false;
  String? _errorMessage;

  VqaResult? get vqaResult => _vqaResult;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // This is the only public method needed now.
  Future<void> fetchVqaResult(String imagePath, String question) async {
    _isLoading = true;
    _errorMessage = null;
    _vqaResult = null;
    notifyListeners();

    try {
      // The logic is now direct and simple.
      // It calls the simplified getVqaResult method from the ApiService.
      _vqaResult = await _apiService.getVqaResult(imagePath, question);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
