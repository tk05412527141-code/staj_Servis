import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';

class DesktopExportService {
  static Future<String?> exportToCSV(
    String fileName,
    List<String> headers,
    List<List<dynamic>> rows,
  ) async {
    try {
      // CSV içeriğini oluştur
      String csvData = '${headers.join(',')}\n';
      for (var row in rows) {
        csvData +=
            '${row.map((e) => '"${e.toString().replaceAll('"', '""')}"').join(',')}\n';
      }

      // Kayıt yerini belirle (Masaüstü veya İndirilenler)
      Directory? directory;
      if (Platform.isWindows) {
        directory = await getDownloadsDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) return null;

      final path = '${directory.path}/$fileName.csv';
      final file = File(path);
      await file.writeAsString(csvData, encoding: utf8);

      return path;
    } catch (e) {
      debugPrint('Dışa aktarma hatası: $e');
      return null;
    }
  }
}
