import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

class HotkeyManager {
  final VoidCallback onHotkeyPressed;
  HotKey? _registeredHotkey;
  bool _isWindowVisible = false;

  HotkeyManager({required this.onHotkeyPressed});

  Future<void> setup() async {
    // Configure window properties
    await windowManager.setSize(const Size(600, 400));
    await windowManager.setMinimumSize(const Size(400, 300));
    await windowManager.setAlwaysOnTop(true);
    await windowManager.setSkipTaskbar(true);

    // Initially hide the window
    await hideWindow();
  }

  Future<void> registerHotkey(String keyCombo) async {
    // Unregister existing hotkey if any
    if (_registeredHotkey != null) {
      await hotKeyManager.unregister(_registeredHotkey!);
    }

    // Parse key combo (e.g., "Control+Alt+L")
    final keys = keyCombo.split('+');
    final lastKey = keys.last.toUpperCase();
    
    final modifiers = <HotKeyModifier>[];
    for (final mod in keys.sublist(0, keys.length - 1)) {
      switch (mod.toLowerCase()) {
        case 'control':
          modifiers.add(HotKeyModifier.control);
          break;
        case 'alt':
          modifiers.add(HotKeyModifier.alt);
          break;
        case 'shift':
          modifiers.add(HotKeyModifier.shift);
          break;
        case 'meta':
          modifiers.add(HotKeyModifier.meta);
          break;
      }
    }

    var key = LogicalKeyboardKey.keyL;
    // Convert string key to LogicalKeyboardKey
    if (lastKey == 'L') {
      key = LogicalKeyboardKey.keyL;
    }

    _registeredHotkey = HotKey(
      key: key,
      modifiers: modifiers,
      scope: HotKeyScope.system,
    );

    await hotKeyManager.register(
      _registeredHotkey!,
      keyDownHandler: (_) async {
        await _handleHotkeyPressed();
      },
    );
  }

  Future<void> _handleHotkeyPressed() async {
    try {
      if (_isWindowVisible) {
        await hideWindow();
      } else {
        await showWindow();
      }
      onHotkeyPressed();
    } catch (e) {
      debugPrint('Error handling hotkey: $e');
    }
  }

  Future<void> showWindow() async {
    try {
      final windowSize = await windowManager.getSize();
      final frame = await windowManager.getBounds();
      await windowManager.setPosition(Offset(
        (frame.width - windowSize.width) / 2,
        0, // Position at top of screen
      ));
    } catch (e) {
      // Default position if we can't get screen size
      await windowManager.setPosition(const Offset(100, 0));
    }
    
    await windowManager.show();
    await windowManager.focus();
    _isWindowVisible = true;
  }

  Future<void> hideWindow() async {
    await windowManager.hide();
    _isWindowVisible = false;
  }

  Future<void> dispose() async {
    if (_registeredHotkey != null) {
      await hotKeyManager.unregister(_registeredHotkey!);
    }
  }

  bool get isWindowVisible => _isWindowVisible;
}
