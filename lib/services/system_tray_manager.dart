import 'dart:io';
import 'package:flutter/material.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

class SystemTrayManager {
  final SystemTray _systemTray = SystemTray();
  final Menu _menu = Menu();
  final VoidCallback onQuit;

  SystemTrayManager({required this.onQuit});

  Future<void> initialize() async {
    try {
      await _systemTray.initSystemTray(
        title: "Whisper Recorder",
        iconPath: Platform.isWindows ? './assets/app_icon.ico' : './assets/app_icon.png',
      );
    } catch (e) {
      debugPrint('Failed to initialize system tray: $e');
      rethrow;
    }

    // Create context menu
    await _menu.buildFrom([
      MenuItemLabel(
        label: 'Show',
        onClicked: (_) async => await windowManager.show(),
      ),
      MenuItemLabel(
        label: 'Hide',
        onClicked: (_) async => await windowManager.hide(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Quit',
        onClicked: (_) => onQuit(),
      ),
    ]);

    // Set up click handlers
    await _systemTray.setContextMenu(_menu);

    // Handle left click to toggle window
    _systemTray.registerSystemTrayEventHandler((eventName) {
      debugPrint("System tray event: $eventName");
      if (eventName == kSystemTrayEventClick) {
        _toggleWindow();
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });
  }

  Future<void> _toggleWindow() async {
    if (await windowManager.isVisible()) {
      await windowManager.hide();
    } else {
      await windowManager.show();
    }
  }

  Future<void> dispose() async {
    await _systemTray.destroy();
  }
}
