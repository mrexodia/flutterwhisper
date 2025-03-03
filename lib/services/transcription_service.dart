import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/transcription.dart';
import '../models/settings.dart';

class TranscriptionService {
  // Test audio file for API testing
  static const String testAudioBase64 =
      'UklGRiQAAABXQVZFZm10IBAAAAABAAEARKwAAIhYAQACABAAZGF0YQAAAAA=';

  static Future<TranscriptionResponse> transcribeAudio(
    String base64AudioData,
    WhisperSettings settings,
  ) async {
    try {
      final request = TranscriptionRequest(
        audioData: base64AudioData,
        suppressNonSpeech: settings.suppressNonSpeech,
        langcode: settings.langCode,
      );

      final response = await http.post(
        Uri.parse(settings.apiEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
        return TranscriptionResponse.fromJson(jsonResponse);
      } else {
        final errorMessage =
            'Failed to transcribe: ${response.statusCode} - ${response.body}';
        debugPrint(errorMessage);
        throw Exception(errorMessage);
      }
    } catch (e) {
      final errorMessage = 'Transcription failed: $e';
      debugPrint(errorMessage);
      throw Exception(errorMessage);
    }
  }

  // Test API endpoint by attempting a real transcription with a test audio file
  static Future<Map<String, dynamic>> testTranscription(
    String apiEndpoint,
  ) async {
    try {
      final testSettings = WhisperSettings(
        apiEndpoint: apiEndpoint,
        langCode: WhisperSettings.defaultLangCode,
        suppressNonSpeech: WhisperSettings.defaultSuppressNonSpeech,
        hotkeyCombo: WhisperSettings.defaultHotkeyCombo,
      );

      await transcribeAudio(testAudioBase64, testSettings);
      return {'success': true, 'message': 'Connection successful'};
    } catch (e) {
      debugPrint('API test failed: $e');
      String errorMessage = e.toString();

      // Extract HTTP status code if available
      final statusCodeMatch = RegExp(r'(\d{3})').firstMatch(errorMessage);
      final statusCode = statusCodeMatch?.group(1);

      if (statusCode != null) {
        return {
          'success': false,
          'message': 'HTTP Error: $statusCode',
          'statusCode': statusCode,
        };
      } else if (errorMessage.contains('SocketException') ||
          errorMessage.contains('Connection refused') ||
          errorMessage.contains('Connection timed out')) {
        return {
          'success': false,
          'message': 'Connection failed',
          'error': 'network',
        };
      } else {
        return {
          'success': false,
          'message': 'API Error',
          'error': errorMessage,
        };
      }
    }
  }
}
