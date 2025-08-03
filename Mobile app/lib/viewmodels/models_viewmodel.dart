import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

// A map to hold models, where the key is the feature (e.g., "VQA")
// and the value is a list of model names for that feature.
typedef ModelMap = Map<String, List<String>>;

class ModelsViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  ModelMap _models = {};
  ModelMap get models => _models;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Fetches the available models from the backend.
  Future<void> fetchModels() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _models = await _apiService.getModels();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
