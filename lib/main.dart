import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'models/settings.dart';
import 'screens/recording_screen.dart';
import 'services/hotkey_manager.dart';
import 'services/window_handler.dart';
import 'services/system_tray_manager.dart';

late final SystemTrayManager systemTray;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await hotKeyManager.unregisterAll();

  await windowManager.waitUntilReadyToShow();

  // Set up window behavior first
  await windowManager.setSize(const Size(600, 400));
  await windowManager.setMinimumSize(const Size(400, 300));
  await windowManager.setAlwaysOnTop(true);
  await windowManager.setSkipTaskbar(true);
  await windowManager.setPreventClose(true);
  await windowManager.setTitle('Whisper Recorder');

  // Add window listener for handling close/minimize
  final appWindowListener = AppWindowListener();
  windowManager.addListener(appWindowListener);

  try {
    // Initialize system tray with error handling
    systemTray = SystemTrayManager(
      onQuit: () async {
        await hotKeyManager.unregisterAll();
        await systemTray.dispose();
        await windowManager.destroy();
        print('<user exit>');
      },
    );
    await systemTray.initialize();
  } catch (e) {
    debugPrint('Failed to initialize system tray, continuing without it: $e');
  }

  // Hide window on start
  await windowManager.hide();

  // Load settings
  // TODO: handle this properly
  final prefs = await SharedPreferences.getInstance();
  final settings = WhisperSettings(
    apiEndpoint: prefs.getString('apiEndpoint') ?? 'http://localhost:5001/api/extra/transcribe',
    langCode: prefs.getString('langCode') ?? 'en',
    suppressNonSpeech: prefs.getBool('suppressNonSpeech') ?? false,
    hotkeyCombo: prefs.getString('hotkeyCombo') ?? 'Control+Alt+L',
  );

  runApp(WhisperApp(settings: settings));
}

class WhisperApp extends StatefulWidget {
  final WhisperSettings settings;

  const WhisperApp({super.key, required this.settings});

  @override
  State<WhisperApp> createState() => _WhisperAppState();
}

class _WhisperAppState extends State<WhisperApp> with WindowListener {
  late HotkeyManager _hotkeyManager;
  RecordingScreen? _recordingScreen;
  late AppWindowListener appWindowListener;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    appWindowListener = AppWindowListener();
    windowManager.addListener(appWindowListener);
    windowManager.addListener(this);
    super.initState();
    _hotkeyManager = HotkeyManager(
      onHotkeyPressed: _handleHotkeyPressed,
    );
    _setupHotkey();
  }

  Future<void> _setupHotkey() async {
    await _hotkeyManager.setup();
    await _hotkeyManager.registerHotkey(widget.settings.hotkeyCombo);
  }

  void _handleHotkeyPressed() {
    if (_recordingScreen != null) {
      _recordingScreen!.toggleRecording();
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _hotkeyManager.dispose();
    systemTray.dispose();
    super.dispose();
  }

  @override
  void onWindowClose() async {
    final context = _navigatorKey.currentContext;
    if (context != null) {
      await RecordingScreen.handleWindowClose(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [
        Locale('en', ''), // English
      ],
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.black87,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      home: Provider.value(
        value: widget.settings,
        child: RecordingScreen(
          ref: (screen) => _recordingScreen = screen,
          settings: widget.settings,
          onHideWindow: _hotkeyManager.hideWindow,
        ),
      ),
    );
  }
}
