import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../services/transcription_service.dart';

class SettingsScreen extends StatefulWidget {
  final WhisperSettings settings;
  final Function(WhisperSettings) onSettingsChanged;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiEndpointController;
  late String _selectedLanguage;
  late bool _suppressNonSpeech;
  late TextEditingController _hotkeyComboController;
  bool _isSaving = false;
  String? _apiEndpointError;
  String? _hotkeyComboError;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current settings
    _apiEndpointController = TextEditingController(
      text: widget.settings.apiEndpoint,
    );
    _selectedLanguage = widget.settings.langCode;
    _suppressNonSpeech = widget.settings.suppressNonSpeech;
    _hotkeyComboController = TextEditingController(
      text: widget.settings.hotkeyCombo,
    );
  }

  @override
  void dispose() {
    _apiEndpointController.dispose();
    _hotkeyComboController.dispose();
    super.dispose();
  }

  // Validate the API endpoint
  Future<bool> _validateApiEndpoint() async {
    try {
      final uri = Uri.parse(_apiEndpointController.text);
      if (!uri.isAbsolute || (uri.scheme != 'http' && uri.scheme != 'https')) {
        setState(() {
          _apiEndpointError = 'Please enter a valid HTTP or HTTPS URL';
        });
        return false;
      }

      // Test API endpoint with a real transcription
      setState(() {
        _apiEndpointError = 'Testing API with transcription...';
      });

      final result = await TranscriptionService.testTranscription(
        _apiEndpointController.text,
      );

      if (result['success'] != true) {
        setState(() {
          _apiEndpointError =
              result['message'] ??
              'API test failed. Check console for details.';
        });
        return false;
      }

      setState(() {
        _apiEndpointError = null;
      });
      return true;
    } catch (e) {
      setState(() {
        _apiEndpointError = 'Invalid URL format';
      });
      return false;
    }
  }

  // Validate the hotkey combo
  bool _validateHotkeyCombo() {
    final hotkeyCombo = _hotkeyComboController.text;
    final parts = hotkeyCombo.split('+');

    if (parts.length < 2) {
      setState(() {
        _hotkeyComboError = 'Must include at least one modifier and one key';
      });
      return false;
    }

    // Check if the last part is a single character (the key)
    final key = parts.last;
    if (key.length != 1) {
      setState(() {
        _hotkeyComboError = 'The key must be a single character';
      });
      return false;
    }

    // Check if all modifiers are valid
    for (int i = 0; i < parts.length - 1; i++) {
      if (!WhisperSettings.supportedModifiers.contains(parts[i])) {
        setState(() {
          _hotkeyComboError = 'Invalid modifier: ${parts[i]}';
        });
        return false;
      }
    }

    setState(() {
      _hotkeyComboError = null;
    });
    return true;
  }

  // Save settings and return to previous screen
  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    // Validate inputs
    final isApiEndpointValid = await _validateApiEndpoint();
    final isHotkeyComboValid = _validateHotkeyCombo();

    if (!isApiEndpointValid || !isHotkeyComboValid) {
      setState(() {
        _isSaving = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create updated settings
      final updatedSettings = WhisperSettings(
        apiEndpoint: _apiEndpointController.text,
        langCode: _selectedLanguage,
        suppressNonSpeech: _suppressNonSpeech,
        hotkeyCombo: _hotkeyComboController.text,
      );

      // Save to SharedPreferences
      final success = await updatedSettings.saveToPrefs();

      if (success) {
        // Notify parent about settings change
        widget.onSettingsChanged(updatedSettings);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings saved successfully')),
          );
          Navigator.of(context).pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save settings')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body:
          _isSaving
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // API Endpoint
                    const Text(
                      'API Endpoint',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiEndpointController,
                      decoration: InputDecoration(
                        hintText: 'Enter API endpoint URL',
                        errorText: _apiEndpointError,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        // Clear error when user types
                        if (_apiEndpointError != null) {
                          setState(() {
                            _apiEndpointError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Language Selection
                    const Text(
                      'Language',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedLanguage,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      items:
                          WhisperSettings.supportedLanguages.entries.map((
                            entry,
                          ) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLanguage = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Suppress Non-Speech
                    SwitchListTile(
                      title: const Text(
                        'Suppress Non-Speech Sounds',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: const Text(
                        'Filter out non-speech sounds like [MUSIC], [LAUGHTER], etc.',
                      ),
                      value: _suppressNonSpeech,
                      onChanged: (value) {
                        setState(() {
                          _suppressNonSpeech = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Hotkey Combo
                    const Text(
                      'Hotkey Combination',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _hotkeyComboController,
                      decoration: InputDecoration(
                        hintText: 'e.g. Control+Alt+L',
                        errorText: _hotkeyComboError,
                        helperText:
                            'Format: Modifier+Modifier+Key (e.g. Control+Alt+L)',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        // Clear error when user types
                        if (_hotkeyComboError != null) {
                          setState(() {
                            _hotkeyComboError = null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        const Text('Available modifiers:'),
                        ...WhisperSettings.supportedModifiers.map((modifier) {
                          return Chip(
                            label: Text(modifier),
                            backgroundColor: Colors.blue.withValues(alpha: 0.2),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Settings'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
