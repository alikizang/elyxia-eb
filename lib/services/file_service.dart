import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileService {
  /// Enregistre un fichier de manière sécurisée et garantie sur disque (Windows et macOS)
  static Future<String?> saveFile({
    required String dialogTitle,
    required String fileName,
    required Uint8List bytes,
  }) async {
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
    try {
      // Ajout des extensions minuscules et majuscules pour compatibilité totale (Windows et macOS)
      final exts = <String>{};
      for (final ext in allowedExtensions) {
        final clean = ext.replaceAll('.', '').trim();
        exts.add(clean.toLowerCase());
        exts.add(clean.toUpperCase());
      }

      final result = await FilePicker.pickFiles(
        dialogTitle: dialogTitle,
        type: FileType.custom,
        allowedExtensions: exts.toList(),
      );

      if (result.isEmpty) return null;
      final file = result.first;

      Uint8List? fileBytes;
      try {
        fileBytes = await file.readAsBytes();
      } catch (_) {}

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
