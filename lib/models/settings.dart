class WhisperSettings {
  String apiEndpoint;
  String langCode;
  bool suppressNonSpeech;
  String hotkeyCombo;

  static const String defaultApiEndpoint = 'http://localhost:5001/api/extra/transcribe';
  static const String defaultLangCode = 'en';
  static const bool defaultSuppressNonSpeech = false;
  static const String defaultHotkeyCombo = 'Control+Alt+L';

  WhisperSettings({
    this.apiEndpoint = defaultApiEndpoint,
    this.langCode = defaultLangCode,
    this.suppressNonSpeech = defaultSuppressNonSpeech,
    this.hotkeyCombo = defaultHotkeyCombo,
  });

  factory WhisperSettings.fromJson(Map<String, dynamic> json) {
    return WhisperSettings(
      apiEndpoint: json['apiEndpoint'] as String? ?? defaultApiEndpoint,
      langCode: json['langCode'] as String? ?? defaultLangCode,
      suppressNonSpeech: json['suppressNonSpeech'] as bool? ?? defaultSuppressNonSpeech,
      hotkeyCombo: json['hotkeyCombo'] as String? ?? defaultHotkeyCombo,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiEndpoint': apiEndpoint,
        'langCode': langCode,
        'suppressNonSpeech': suppressNonSpeech,
        'hotkeyCombo': hotkeyCombo,
      };
}
