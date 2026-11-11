import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

typedef _ObjcMsgSend = Pointer<Void> Function(Pointer<Void>, Pointer<Void>);
typedef _ObjcMsgSend1 = Pointer<Void> Function(Pointer<Void>, Pointer<Void>, Pointer<Void>);

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
    try {
      final objc = DynamicLibrary.process();
      final objcGetClass = objc.lookupFunction<
          Pointer<Void> Function(Pointer<Utf8>),
          Pointer<Void> Function(Pointer<Utf8>)>('objc_getClass');
      final selRegisterName = objc.lookupFunction<
          Pointer<Void> Function(Pointer<Utf8>),
          Pointer<Void> Function(Pointer<Utf8>)>('sel_registerName');
      final objcMsgSend = objc.lookupFunction<_ObjcMsgSend, _ObjcMsgSend>('objc_msgSend');
      final objcMsgSend1 = objc.lookupFunction<_ObjcMsgSend1, _ObjcMsgSend1>('objc_msgSend');

      final nsAppClass = objcGetClass('NSApplication'.toNativeUtf8());
      final selSharedApp = selRegisterName('sharedApplication'.toNativeUtf8());
      final app = objcMsgSend(nsAppClass, selSharedApp);

      final selWindows = selRegisterName('windows'.toNativeUtf8());
      final windows = objcMsgSend(app, selWindows);

      final selFirstObject = selRegisterName('firstObject'.toNativeUtf8());
      final window = objcMsgSend(windows, selFirstObject);

      if (window.address != 0) {
        final selZoom = selRegisterName('zoom:'.toNativeUtf8());
        objcMsgSend1(window, selZoom, nullptr);
      } else {
        // Fallback osascript
        Process.run('osascript', [
          '-e',
          'tell application "System Events" to tell process "elyxia_eb" to click button 3 of window 1',
        ]);
      }
    } catch (_) {
      try {
        Process.run('osascript', [
          '-e',
          'tell application "System Events" to tell process "elyxia_eb" to click button 3 of window 1',
        ]);
      } catch (_) {}
    }
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
