import 'package:shared_preferences/shared_preferences.dart';

class WhisperSettings {
  String apiEndpoint;
  String langCode;
  bool suppressNonSpeech;
  String hotkeyCombo;

  static const String defaultApiEndpoint = 'http://localhost:5001/api/extra/transcribe';
  static const String defaultLangCode = 'en';
  static const bool defaultSuppressNonSpeech = false;
  static const String defaultHotkeyCombo = 'Control+Alt+L';

  // List of supported languages
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

  // List of supported hotkey modifiers
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

  // Load settings from SharedPreferences
  static Future<WhisperSettings> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return WhisperSettings(
        apiEndpoint: prefs.getString('apiEndpoint') ?? defaultApiEndpoint,
        langCode: prefs.getString('langCode') ?? defaultLangCode,
        suppressNonSpeech: prefs.getBool('suppressNonSpeech') ?? defaultSuppressNonSpeech,
        hotkeyCombo: prefs.getString('hotkeyCombo') ?? defaultHotkeyCombo,
      );
    } catch (e) {
      print('Error loading settings: $e');
      return WhisperSettings();
    }
  }

  // Save settings to SharedPreferences
  Future<bool> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('apiEndpoint', apiEndpoint);
      await prefs.setString('langCode', langCode);
      await prefs.setBool('suppressNonSpeech', suppressNonSpeech);
      await prefs.setString('hotkeyCombo', hotkeyCombo);
      return true;
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }

  // Validate API endpoint
  bool isValidApiEndpoint() {
    try {
      final uri = Uri.parse(apiEndpoint);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Validate hotkey combo
  bool isValidHotkeyCombo() {
    final parts = hotkeyCombo.split('+');
    if (parts.length < 2) return false; // Must have at least one modifier and one key
    
    // Check if the last part is a single character (the key)
    final key = parts.last;
    if (key.length != 1) return false;
    
    // Check if all modifiers are valid
    for (int i = 0; i < parts.length - 1; i++) {
      if (!supportedModifiers.contains(parts[i])) {
        return false;
      }
    }
    
    return true;
  }

  // Create a copy of the settings
  WhisperSettings copy() {
    return WhisperSettings(
      apiEndpoint: apiEndpoint,
      langCode: langCode,
      suppressNonSpeech: suppressNonSpeech,
      hotkeyCombo: hotkeyCombo,
    );
  }
}
