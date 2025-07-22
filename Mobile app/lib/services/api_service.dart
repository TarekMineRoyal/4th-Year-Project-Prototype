// lib/services/api_service.dart

import 'dart:convert';
import '../models/video_analysis_result.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/vqa_result.dart';
import '../models/ocr_result.dart';
import 'settings_service.dart';

class ApiService {
  final SettingsService _settingsService = SettingsService();

  Future<String> _getBaseUrl() async {
    final ip = _settingsService.getIpAddress();
    if (ip == null || ip.isEmpty) {
      throw Exception("Backend IP address has not been set for this session.");
    }
    return "http://$ip:8000/api/v1";
  }

  // Helper method to create a multipart file with the correct content type
  Future<http.MultipartFile> _createImageFile(String path) async {
    final fileExt = path.split('.').last.toLowerCase();
    final contentType =
        fileExt == 'png'
            ? MediaType('image', 'png')
            : MediaType('image', 'jpeg');

    return await http.MultipartFile.fromPath(
      'image',
      path,
      contentType: contentType,
    );
  }

  // --- UPDATED VQA METHOD ---
  Future<VqaResult> getVqaResult(
    String imagePath,
    String question,
    // The "modelOption" parameter is REMOVED.
  ) async {
    final baseUrl = await _getBaseUrl();
    var uri = Uri.parse('$baseUrl/vqa/');
    var request =
        http.MultipartRequest('POST', uri)
          ..fields['question'] = question
          // The "option" field is REMOVED from the request.
          ..files.add(await _createImageFile(imagePath));

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return VqaResult.fromJson(jsonDecode(responseBody));
    } else {
      final responseBody = await response.stream.bytesToString();
      throw Exception(
        'Failed to get VQA result: ${response.statusCode} - $responseBody',
      );
    }
  }

  // --- OCR and Video Analysis methods are unchanged for now ---
  Future<OcrResult> getOcrResult(String imagePath) async {
    // The "modelOption" parameter is REMOVED.
    final baseUrl = await _getBaseUrl();
    var uri = Uri.parse('$baseUrl/ocr/');
    var request = http.MultipartRequest('POST', uri)
      // The "option" field is REMOVED from the request.
      ..files.add(await _createImageFile(imagePath));

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return OcrResult.fromJson(jsonDecode(responseBody));
    } else {
      final responseBody = await response.stream.bytesToString();
      throw Exception(
        'Failed to get OCR result: ${response.statusCode} - $responseBody',
      );
    }
  }

  Future<VideoAnalysisResult> getVideoAnalysisResult(
    String imagePath,
    String previousDescription,
    // The "modelOption" parameter is REMOVED.
  ) async {
    final baseUrl = await _getBaseUrl();
    var uri = Uri.parse('$baseUrl/video/');
    var request =
        http.MultipartRequest('POST', uri)
          ..fields['previous_scene_description'] = previousDescription
          // The "option" field is REMOVED from the request.
          ..files.add(await _createImageFile(imagePath));

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      return VideoAnalysisResult.fromJson(jsonDecode(responseBody));
    } else {
      final responseBody = await response.stream.bytesToString();
      throw Exception(
        'Failed to get Video Analysis result: ${response.statusCode} - $responseBody',
      );
    }
  }
}
