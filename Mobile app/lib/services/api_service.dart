// lib/services/api_service.dart

import 'dart:convert';
import '../models/video_analysis_result.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/vqa_result.dart';
import '../models/ocr_result.dart';
import '../models/session_question_result.dart';
import '../models/video_processing_result.dart';
import '../models/user_init_response.dart';
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

  // Helper method to create a multipart file with the correct content type
  Future<http.MultipartFile> _createImageFile(String path) async {
    final fileExt = path.split('.').last.toLowerCase();
    final contentType = // MediaType('image', fileExt);
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
  // These are the methods that the ViewModels will call.
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

  Future<SessionQuestionResult> askQuestion(
    String sessionId,
    String question,
  ) async {
    final baseUrl = await _getBaseUrl();
    final uri = Uri.parse('$baseUrl/session/query');

    // The backend expects 'x-www-form-urlencoded' data because it uses Form(...).
    // To send this, we create a Map of the fields.
    final requestBody = {'session_id': sessionId, 'question': question};

    // When you pass a Map<String, String> directly to the body of http.post,
    // the http package automatically encodes it as form data and sets the
    // correct 'Content-Type' header. We do NOT use jsonEncode here.
    final response = await http.post(uri, body: requestBody);

    // The rest of the logic for handling the response is the same.
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

    // 1. Determine the file extension.
    final fileExt = imagePath.split('.').last.toLowerCase();
    // 2. Create the correct MediaType. This handles both jpg and jpeg.
    final contentType = MediaType('image', fileExt == 'png' ? 'png' : 'jpeg');

    // 3. Add the file with the EXPLICIT content type.
    request.files.add(
      await http.MultipartFile.fromPath(
        'image_frame',
        imagePath,
        contentType: contentType, // Set the content type here
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

  // This method is called once when the app starts to get a user ID.
  Future<void> initializeUser() async {
    // First, check if a user ID already exists.
    final existingUserId = await _userService.getUserId();
    if (existingUserId == null) {
      // If no ID exists, fetch a new one from the backend.
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
          // Handle cases where the server fails to provide an ID.
          throw Exception(
            'Failed to initialize user: ${response.statusCode} - ${response.body}',
          );
        }
      } catch (e) {
        // Handle network errors or other exceptions.
        throw Exception('Could not connect to the server to initialize user.');
      }
    }
  }
}
