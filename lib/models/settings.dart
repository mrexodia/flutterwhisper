import 'package:shared_preferences/shared_preferences.dart';

class WhisperSettings {
  String apiEndpoint;
  String langCode;
  bool suppressNonSpeech;
  String hotkeyCombo;

  static const String defaultApiEndpoint =
      'http://localhost:5001/api/extra/transcribe';
  static const String defaultLangCode = 'en';
  static const bool defaultSuppressNonSpeech = false;
  static const String defaultHotkeyCombo = 'Control+Alt+L';

  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'de': 'German',
    'it': 'Italian',
    'pt': 'Portuguese',
    'nl': 'Dutch',
    'ru': 'Russian',
    'zh': 'Chinese',
    'ja': 'Japanese',
    'ko': 'Korean',
    'ar': 'Arabic',
    'hi': 'Hindi',
    'auto': 'Auto Detect',
  };

  static const List<String> supportedModifiers = [
    'Control',
    'Alt',
    'Shift',
    'Meta',
  ];

  WhisperSettings({
    this.apiEndpoint = defaultApiEndpoint,
    this.langCode = defaultLangCode,
    this.suppressNonSpeech = defaultSuppressNonSpeech,
    this.hotkeyCombo = defaultHotkeyCombo,
  });

  static Future<WhisperSettings> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return WhisperSettings(
      apiEndpoint: prefs.getString('apiEndpoint') ?? defaultApiEndpoint,
      langCode: prefs.getString('langCode') ?? defaultLangCode,
      suppressNonSpeech:
          prefs.getBool('suppressNonSpeech') ?? defaultSuppressNonSpeech,
      hotkeyCombo: prefs.getString('hotkeyCombo') ?? defaultHotkeyCombo,
    );
  }

  Future<bool> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('apiEndpoint', apiEndpoint);
    await prefs.setString('langCode', langCode);
    await prefs.setBool('suppressNonSpeech', suppressNonSpeech);
    await prefs.setString('hotkeyCombo', hotkeyCombo);
    return true;
  }

  bool isValidApiEndpoint() {
    try {
      final uri = Uri.parse(apiEndpoint);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  bool isValidHotkeyCombo() {
    final parts = hotkeyCombo.split('+');
    if (parts.length < 2) return false;

    final key = parts.last;
    if (key.length != 1) return false;

    for (int i = 0; i < parts.length - 1; i++) {
      if (!supportedModifiers.contains(parts[i])) return false;
    }

    return true;
  }
}
