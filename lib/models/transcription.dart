class TranscriptionRequest {
  final String prompt;
  final bool suppressNonSpeech;
  final String langcode;
  final String audioData;

  TranscriptionRequest({
    this.prompt = '',
    this.suppressNonSpeech = false,
    this.langcode = 'en',
    required this.audioData,
  });

  Map<String, dynamic> toJson() => {
    'prompt': prompt,
    'suppress_non_speech': suppressNonSpeech,
    'langcode': langcode,
    'audio_data': audioData,
  };
}

class TranscriptionResponse {
  final String text;

  TranscriptionResponse({required this.text});

  factory TranscriptionResponse.fromJson(Map<String, dynamic> json) {
    return TranscriptionResponse(text: json['text'] as String? ?? '');
  }
}

enum TranscriptionState { idle, recording, processing, done, error }
