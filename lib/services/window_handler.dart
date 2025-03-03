import 'package:window_manager/window_manager.dart';

class AppWindowListener extends WindowListener {
  @override
  void onWindowClose() async {
    // This method will be overridden in _WhisperAppState to pass the context
  }

  @override
  void onWindowMinimize() async {
    await windowManager.hide();
  }

  @override
  void onWindowFocus() {
    // Bring window to front when focused
    windowManager.focus();
  }
}
