// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/vqa_result.dart';
import '../models/ocr_result.dart';
import '../models/session_question_result.dart';
import '../models/video_processing_result.dart';
import '../models/user_init_response.dart';
import '../viewmodels/models_viewmodel.dart';
import 'settings_service.dart';
import 'user_service.dart';

class ApiService {
  final SettingsService _settingsService = SettingsService();
  final UserService _userService = UserService();

  Future<String> _getBaseUrl() async {
    final ip = _settingsService.getIpAddress();
    if (ip == null || ip.isEmpty) {
      throw Exception("Backend IP address has not been set for this session.");
    }
    return "http://$ip:8000/api/v1";
  }

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

  // --- PUBLIC API METHODS ---

  Future<ModelMap> getModels() async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl/models/');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final models = body.map((key, value) {
        final modelList = (value as List).cast<String>();
        return MapEntry(key, modelList);
      });
      return models;
    } else {
      throw Exception(
        'Failed to get models: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // --- UPDATED METHOD SIGNATURE ---
  Future<VqaResult> getVqaResult(
    String imagePath,
    String question,
    String modelOption, // ADDED
    String mode, // ADDED
  ) async {
    final baseUrl = await _getBaseUrl();
    final userId = await _userService.getUserId();
    if (userId == null) {
      throw Exception("User ID has not been initialized.");
    }
    var uri = Uri.parse('$baseUrl/vqa/');
    var request =
        http.MultipartRequest('POST', uri)
          ..headers['X-User-ID'] = userId
          ..fields['question'] = question
          // --- ADDED fields for model and mode ---
          ..fields['model_option'] = modelOption
          ..fields['mode'] = mode
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

  // --- UPDATED METHOD SIGNATURE ---
  Future<OcrResult> getOcrResult(String imagePath, String modelOption) async {
    final baseUrl = await _getBaseUrl();
    var uri = Uri.parse('$baseUrl/ocr/');
    var request =
        http.MultipartRequest('POST', uri)
          // --- ADDED field for model ---
          ..fields['model_option'] = modelOption
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

  Future<SessionQuestionResult> startSession() async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl/session/start');

    final response = await http.post(uri);

    if (response.statusCode == 201) {
      return SessionQuestionResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to start session: ${response.statusCode} - ${response.body}',
      );
    }
  }

  // --- UPDATED METHOD SIGNATURE ---
  Future<SessionQuestionResult> askQuestion(
    String sessionId,
    String question,
    String modelOption, // ADDED
    String mode, // ADDED
  ) async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl/session/query');

    // --- ADDED model and mode to the request body ---
    final requestBody = {
      'session_id': sessionId,
      'question': question,
      'model_option': modelOption,
      'mode': mode,
    };

    final response = await http.post(uri, body: requestBody);

    if (response.statusCode == 200) {
      return SessionQuestionResult.fromJson(jsonDecode(response.body));
    } else {
      throw Exception(
        'Failed to ask question: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<VideoProcessingResult> processFrame(
    String sessionId,
    String imagePath,
  ) async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl/session/process-frame');

    var request = http.MultipartRequest('POST', uri)
      ..fields['session_id'] = sessionId;

    final fileExt = imagePath.split('.').last.toLowerCase();
    final contentType = MediaType('image', fileExt == 'png' ? 'png' : 'jpeg');

    request.files.add(
      await http.MultipartFile.fromPath(
        'image_frame',
        imagePath,
        contentType: contentType,
      ),
    );
    var response = await request.send();

    if (response.statusCode == 202) {
      final responseBody = await response.stream.bytesToString();
      return VideoProcessingResult.fromJson(jsonDecode(responseBody));
    } else {
      final responseBody = await response.stream.bytesToString();
      throw Exception(
        'Failed to process frame: ${response.statusCode} - $responseBody',
      );
    }
  }

  Future<VideoProcessingResult> processClip(
    String sessionId,
    String videoPath,
  ) async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl/session/process-clip');

    var request = http.MultipartRequest('POST', uri)
      ..fields['session_id'] = sessionId;

    request.files.add(
      await http.MultipartFile.fromPath(
        'video_clip',
        videoPath,
        contentType: MediaType('video', 'mp4'),
      ),
    );

    var response = await request.send();

    if (response.statusCode == 202) {
      final responseBody = await response.stream.bytesToString();
      return VideoProcessingResult.fromJson(jsonDecode(responseBody));
    } else {
      final responseBody = await response.stream.bytesToString();
      throw Exception(
        'Failed to process clip: ${response.statusCode} - $responseBody',
      );
    }
  }

  Future<void> initializeUser() async {
    final existingUserId = await _userService.getUserId();
    if (existingUserId == null) {
      final baseUrl = await _getBaseUrl();
      final uri = Uri.parse('$baseUrl/users/init');
      try {
        final response = await http.post(uri);
        if (response.statusCode == 201) {
          final responseBody = UserInitResponse.fromJson(
            jsonDecode(response.body),
          );
          await _userService.setUserId(responseBody.userId);
        } else {
          throw Exception(
            'Failed to initialize user: ${response.statusCode} - ${response.body}',
          );
        }
      } catch (e) {
        throw Exception('Could not connect to the server to initialize user.');
      }
    }
  }
}
