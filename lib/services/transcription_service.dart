import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transcription.dart';
import '../models/settings.dart';

class TranscriptionService {
  final WhisperSettings settings;

  TranscriptionService(this.settings);

  Future<TranscriptionResponse> transcribeAudio(String base64AudioData) async {
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
        throw Exception(
          'Failed to transcribe: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Transcription failed: $e');
    }
  }
}
