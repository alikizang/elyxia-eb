import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileService {
  static bool _initialized = false;

  /// Initialise les permissions de sélection de fichier sur les OS de bureau (macOS / Windows)
  static Future<void> ensureInitialized() async {
    if (_initialized) return;
    _initialized = true;
    try {
      if (!kIsWeb && Platform.isMacOS) {
        // Indispensable sur macOS : désactive les vérifications d'entitlements Sandbox
        // qui bloquent l'ouverture des boîtes de dialogue de sélection/sauvegarde
        await FilePicker.skipEntitlementsChecks();
      }
    } catch (e) {
      debugPrint("FileService.ensureInitialized error: $e");
    }
  }

  /// Enregistre un fichier de manière sécurisée et garantie sur disque (Windows et macOS)
  static Future<String?> saveFile({
    required String dialogTitle,
    required String fileName,
    required Uint8List bytes,
  }) async {
    await ensureInitialized();

    try {
      final savedUri = await FilePicker.saveFile(
        dialogTitle: dialogTitle,
        fileName: fileName,
        bytes: bytes,
      );

      if (savedUri == null) return null;

      // Conversion de l'URI en chemin de fichier natif absolu (gère Windows C:\ et Mac /Users/)
      String filePath;
      try {
        filePath = savedUri.toFilePath();
      } catch (_) {
        filePath = savedUri.path;
      }

      final file = File(filePath);
      // Écriture forcée avec flush pour garantir la persistance physique sur le disque
      await file.writeAsBytes(bytes, flush: true);
      return filePath;
    } catch (e) {
      debugPrint("FileService.saveFile error: $e");
      // Secours : si la boîte de dialogue système échoue, sauvegarde automatique dans Téléchargements
      try {
        Directory? targetDir;
        if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          targetDir = await getDownloadsDirectory();
        }
        targetDir ??= await getApplicationDocumentsDirectory();

        final fallbackPath = p.join(targetDir.path, fileName);
        final file = File(fallbackPath);
        await file.writeAsBytes(bytes, flush: true);
        return fallbackPath;
      } catch (err) {
        debugPrint("FileService fallback save error: $err");
        return null;
      }
    }
  }

  /// Sélectionne un fichier et renvoie ses octets (bytes) de façon robuste sur tous les OS
  static Future<({String name, String? path, Uint8List bytes})?> pickFile({
    required List<String> allowedExtensions,
    String? dialogTitle,
  }) async {
    await ensureInitialized();

    try {
      final cleanExts = allowedExtensions
          .map((ext) => ext.replaceAll('.', '').trim().toLowerCase())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();

      List<PlatformFile> result = [];
      try {
        result = await FilePicker.pickFiles(
          dialogTitle: dialogTitle,
          type: FileType.custom,
          allowedExtensions: cleanExts,
        );
      } catch (customErr) {
        debugPrint("FilePicker.pickFiles custom error: $customErr, trying fallback any");
        result = await FilePicker.pickFiles(
          dialogTitle: dialogTitle,
          type: FileType.any,
        );
      }

      if (result.isEmpty) return null;
      final file = result.first;

      Uint8List? fileBytes;
      try {
        fileBytes = await file.readAsBytes();
      } catch (readErr) {
        debugPrint("file.readAsBytes error: $readErr");
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        if (file.path != null) {
          final ioFile = File(file.path!);
          if (await ioFile.exists()) {
            fileBytes = await ioFile.readAsBytes();
          }
        }
      }

      if (fileBytes == null || fileBytes.isEmpty) {
        return null;
      }

      return (
        name: file.name,
        path: file.path,
        bytes: fileBytes,
      );
    } catch (e) {
      debugPrint("FileService.pickFile error: $e");
      return null;
    }
  }

  /// Décode les octets d'un fichier texte en chaîne avec gestion automatique UTF-8 et Latin-1 (ISO-8859-1)
  static String decodeTextBytes(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } catch (_) {
      try {
        return latin1.decode(bytes);
      } catch (_) {
        return utf8.decode(bytes, allowMalformed: true);
      }
    }
  }
}
