import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
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

  // Load settings using the enhanced WhisperSettings model
  final settings = await WhisperSettings.loadFromPrefs();

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
  late WhisperSettings _currentSettings;

  @override
  void initState() {
    appWindowListener = AppWindowListener();
    windowManager.addListener(appWindowListener);
    windowManager.addListener(this);
    super.initState();
    _currentSettings = widget.settings;
    _hotkeyManager = HotkeyManager(
      onHotkeyPressed: _handleHotkeyPressed,
    );
    _setupHotkey();
    
    // Set up system tray settings callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupSystemTraySettingsCallback();
    });
  }
  
  // Set up the system tray settings callback after the widget is built
  void _setupSystemTraySettingsCallback() {
    systemTray.setOnOpenSettings(() {
      if (_recordingScreen != null) {
        _recordingScreen!.navigateToSettings();
      }
    });
  }

  Future<void> _setupHotkey() async {
    await _hotkeyManager.setup();
    await _hotkeyManager.registerHotkey(_currentSettings.hotkeyCombo);
  }

  // Handle settings changes
  Future<void> _handleSettingsChanged(WhisperSettings newSettings) async {
    setState(() {
      _currentSettings = newSettings;
    });
    
    // Update hotkey if it changed
    if (newSettings.hotkeyCombo != _currentSettings.hotkeyCombo) {
      await _hotkeyManager.registerHotkey(newSettings.hotkeyCombo);
    }
  }

  void _handleHotkeyPressed(bool isWindowVisible) {
    if (_recordingScreen != null) {
      final recordingState = _recordingScreen!.getRecordingState();
      
      if (!isWindowVisible) {
        // If UI is hidden, show UI and immediately start recording
        _hotkeyManager.showWindow();
        
        // Reset to idle state if needed before starting a new recording
        _recordingScreen!.resetToIdle();
        
        // Start recording
        _recordingScreen!.toggleRecording();
      } else if (_recordingScreen!.isRecording()) {
        // If UI is visible and recording is running, stop recording but DO NOT hide the UI
        _recordingScreen!.toggleRecording();
        // We don't hide the window here
      } else {
        // If UI is visible but not recording
        // First reset to idle state if needed (e.g., if in done or error state)
        _recordingScreen!.resetToIdle();
        
        // Then start recording
        _recordingScreen!.toggleRecording();
      }
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
        value: _currentSettings,
        child: RecordingScreen(
          ref: (screen) => _recordingScreen = screen,
          settings: _currentSettings,
          onHideWindow: _hotkeyManager.hideWindow,
          onSettingsChanged: _handleSettingsChanged,
        ),
      ),
    );
  }
}
