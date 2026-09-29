import 'dart:io' show Platform;
import 'package:flutter/services.dart';

/// Blocks screenshots and screen recording while the user is in-game.
///
/// Android: uses FLAG_SECURE via the native `quizzapp/security` MethodChannel
/// (see `MainActivity.kt`). FLAG_SECURE blocks both screenshots and video
/// capture for the entire window.
///
/// iOS / desktop / web: no-op. iOS has no public API to block screenshots —
/// the closest fallback is observing `UIScreen.capturedDidChangeNotification`
/// to overlay the screen during active recording. Not implemented here.
class ScreenSecurity {
  ScreenSecurity._();
  static const _channel = MethodChannel('quizzapp/security');
  static bool _enabled = false;

  static Future<void> enable() async {
    if (_enabled) return;
    if (!Platform.isAndroid) {
      _enabled = true;
      return;
    }
    try {
      await _channel.invokeMethod('enableSecure');
      _enabled = true;
    } on PlatformException {
      // Channel not registered (e.g. running before MainActivity wires up).
    }
  }

  static Future<void> disable() async {
    if (!_enabled) return;
    if (!Platform.isAndroid) {
      _enabled = false;
      return;
    }
    try {
      await _channel.invokeMethod('disableSecure');
      _enabled = false;
    } on PlatformException {
      // Best-effort.
    }
  }
}
