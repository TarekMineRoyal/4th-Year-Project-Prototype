// lib/services/preference_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class PreferenceService {
  // Keys for storing the preferences
  static const String _vqaModelKey = 'last_vqa_model';
  static const String _ocrModelKey = 'last_ocr_model';
  static const String _sessionModelKey = 'last_session_model';
  static const String _analysisModeKey = 'last_analysis_mode';

  // --- VQA Model ---
  Future<String?> getLastVqaModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vqaModelKey);
  }

  Future<void> setLastVqaModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_vqaModelKey, model);
  }

  // --- OCR Model ---
  Future<String?> getLastOcrModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_ocrModelKey);
  }

  Future<void> setLastOcrModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ocrModelKey, model);
  }

  // --- Session Model ---
  Future<String?> getLastSessionModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionModelKey);
  }

  Future<void> setLastSessionModel(String model) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionModelKey, model);
  }

  // --- Analysis Mode ---
  Future<String?> getLastAnalysisMode() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to 'brief' if no mode has been saved yet
    return prefs.getString(_analysisModeKey) ?? 'brief';
  }

  Future<void> setLastAnalysisMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_analysisModeKey, mode);
  }
}
