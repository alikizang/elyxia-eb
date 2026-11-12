import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

/// Service natif ultra-léger pour maximiser la fenêtre principale au démarrage
/// sans aucune dépendance tierce complexe sur Windows et macOS.
class WindowService {
  static bool _hasMaximized = false;

  static void maximizeOnStartup() {
    if (_hasMaximized || kIsWeb || Platform.environment.containsKey('FLUTTER_TEST')) return;
    _hasMaximized = true;

    try {
      if (Platform.isMacOS) {
        _maximizeMacOS();
      } else if (Platform.isWindows) {
        _maximizeWindows();
      }
    } catch (e) {
      debugPrint("WindowService error: $e");
    }
  }

  static void _maximizeMacOS() {
    // Sur macOS, la taille et le cadrage maximal sur l'écran (NSScreen.main.visibleFrame)
    // sont garantis nativement dès l'initialisation dans MainFlutterWindow.swift.
    // Aucun appel destructif ou bascule de zoom n'est nécessaire.
  }

  static void _maximizeWindows() {
    try {
      final user32 = DynamicLibrary.open('user32.dll');
      final findWindow = user32.lookupFunction<
          IntPtr Function(Pointer<Utf8>, Pointer<Utf8>),
          int Function(Pointer<Utf8>, Pointer<Utf8>)>('FindWindowA');
      final showWindow = user32.lookupFunction<
          Int32 Function(IntPtr, Int32),
          int Function(int, int)>('ShowWindow');

      // SW_MAXIMIZE = 3
      final titles = ['elyxia_eb', 'Elyxia EB', 'ELYXIA EB'];
      for (final title in titles) {
        final hwnd = findWindow(nullptr, title.toNativeUtf8());
        if (hwnd != 0) {
          showWindow(hwnd, 3);
          break;
        }
      }
    } catch (_) {}
  }
}
