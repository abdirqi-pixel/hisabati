import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportExportService {
  Future<File> exportExpensesPdf({
    required String currencySymbol,
    required num total,
    required List<Map<String, Object?>> byCategory,
    required List<Map<String, Object?>> byPerson,
    required List<Map<String, Object?>> byDay,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('تقرير حساباتي',
                    style: pw.TextStyle(
                        fontSize: 26, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text(
                    'إجمالي المصروفات: ${total.toStringAsFixed(0)} $currencySymbol'),
                pw.SizedBox(height: 18),
                _table('حسب التصنيف', byCategory, currencySymbol),
                pw.SizedBox(height: 18),
                _table('حسب الشخص', byPerson, currencySymbol),
                pw.SizedBox(height: 18),
                _dayTable('حسب اليوم', byDay, currencySymbol),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/hisabati_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  pw.Widget _table(
      String title, List<Map<String, Object?>> rows, String symbol) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['الاسم', 'عدد العمليات', 'الإجمالي'],
          data: rows.map((row) {
            final total = (row['total'] as num?) ?? 0;
            return [
              row['name'].toString(),
              row['count'].toString(),
              '${total.toStringAsFixed(0)} $symbol',
            ];
          }).toList(),
        ),
      ],
    );
  }

  pw.Widget _dayTable(
      String title, List<Map<String, Object?>> rows, String symbol) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title,
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.TableHelper.fromTextArray(
          headers: ['اليوم', 'عدد العمليات', 'الإجمالي'],
          data: rows.map((row) {
            final total = (row['total'] as num?) ?? 0;
            return [
              row['date'].toString(),
              row['count'].toString(),
              '${total.toStringAsFixed(0)} $symbol',
            ];
          }).toList(),
        ),
      ],
    );
  }

  Future<File> exportExpensesExcel({
    required String currencySymbol,
    required num total,
    required List<Map<String, Object?>> byCategory,
    required List<Map<String, Object?>> byPerson,
    required List<Map<String, Object?>> byDay,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _writeSheet(excel, 'حسب التصنيف', byCategory, currencySymbol);
    _writeSheet(excel, 'حسب الشخص', byPerson, currencySymbol);
    _writeDaySheet(excel, 'حسب اليوم', byDay, currencySymbol);

    final summary = excel['الملخص'];
    summary.appendRow([
      TextCellValue('إجمالي المصروفات'),
      TextCellValue('${total.toStringAsFixed(0)} $currencySymbol'),
    ]);

    final bytes = excel.encode();
    if (bytes == null) throw Exception('تعذر إنشاء ملف Excel');

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/hisabati_report_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(bytes);
    return file;
  }

  void _writeSheet(Excel excel, String sheetName,
      List<Map<String, Object?>> rows, String symbol) {
    final sheet = excel[sheetName];
    sheet.appendRow([
      TextCellValue('الاسم'),
      TextCellValue('عدد العمليات'),
      TextCellValue('الإجمالي'),
    ]);

    for (final row in rows) {
      final total = (row['total'] as num?) ?? 0;
      sheet.appendRow([
        TextCellValue(row['name'].toString()),
        TextCellValue(row['count'].toString()),
        TextCellValue('${total.toStringAsFixed(0)} $symbol'),
      ]);
    }
  }

  void _writeDaySheet(Excel excel, String sheetName,
      List<Map<String, Object?>> rows, String symbol) {
    final sheet = excel[sheetName];
    sheet.appendRow([
      TextCellValue('اليوم'),
      TextCellValue('عدد العمليات'),
      TextCellValue('الإجمالي'),
    ]);

    for (final row in rows) {
      final total = (row['total'] as num?) ?? 0;
      sheet.appendRow([
        TextCellValue(row['date'].toString()),
        TextCellValue(row['count'].toString()),
        TextCellValue('${total.toStringAsFixed(0)} $symbol'),
      ]);
    }
  }
}
