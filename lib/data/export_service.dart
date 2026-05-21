import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class ExportService {
  Future<String> exportCsv({
    required String fileName,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    final csv = CsvEncoder().convert([headers, ...rows]);
    await file.writeAsString(csv);
    return file.path;
  }

  Future<String> exportPdf({
    required String fileName,
    required String title,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (_) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(headers: headers, data: rows),
        ],
      ),
    );
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await doc.save());
    return file.path;
  }
}
