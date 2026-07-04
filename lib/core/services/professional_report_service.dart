import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ProfessionalReportService {
  Future<File> createAccountStatementPdf({
    required String title,
    required String currencySymbol,
    required List<Map<String, Object?>> expenses,
    required List<Map<String, Object?>> incomes,
    required List<Map<String, Object?>> advances,
    required List<Map<String, Object?>> treasury,
  }) async {
    final pdf = pw.Document();

    final totalExpenses = _sum(expenses);
    final totalIncomes = _sum(incomes);
    final totalAdvances = _sum(advances.where((e) => e['type'] == 'advance').toList());
    final totalPayments = _sum(advances.where((e) => e['type'] == 'payment').toList());
    final net = totalIncomes - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(18),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green700,
                    borderRadius: pw.BorderRadius.circular(12),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('حساباتي', style: pw.TextStyle(color: PdfColors.white, fontSize: 26, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 6),
                      pw.Text(title, style: const pw.TextStyle(color: PdfColors.white, fontSize: 16)),
                      pw.Text('تاريخ التقرير: ${DateTime.now().toIso8601String().split('T').first}', style: const pw.TextStyle(color: PdfColors.white)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 18),
                _summaryGrid(currencySymbol, totalExpenses, totalIncomes, totalAdvances, totalPayments, net),
                pw.SizedBox(height: 18),
                _sectionTable(
                  title: 'المصروفات',
                  headers: ['التاريخ', 'الوصف', 'المبلغ'],
                  rows: expenses.map((e) => [
                    '${e['expense_date'] ?? ''}',
                    '${e['description'] ?? e['category_name'] ?? ''}',
                    '${e['amount'] ?? 0} ${e['currency_symbol'] ?? currencySymbol}',
                  ]).toList(),
                ),
                pw.SizedBox(height: 14),
                _sectionTable(
                  title: 'الإيرادات',
                  headers: ['التاريخ', 'المصدر', 'المبلغ'],
                  rows: incomes.map((e) => [
                    '${e['income_date'] ?? ''}',
                    '${e['source'] ?? e['description'] ?? ''}',
                    '${e['amount'] ?? 0} ${e['currency_symbol'] ?? currencySymbol}',
                  ]).toList(),
                ),
                pw.SizedBox(height: 14),
                _sectionTable(
                  title: 'السلف والتسديدات',
                  headers: ['التاريخ', 'النوع', 'المبلغ'],
                  rows: advances.map((e) => [
                    '${e['advance_date'] ?? ''}',
                    e['type'] == 'advance' ? 'سلفة' : 'تسديد',
                    '${e['amount'] ?? 0} ${e['currency_symbol'] ?? currencySymbol}',
                  ]).toList(),
                ),
                pw.SizedBox(height: 14),
                _sectionTable(
                  title: 'الصندوق',
                  headers: ['التاريخ', 'النوع', 'المبلغ'],
                  rows: treasury.map((e) => [
                    '${e['transaction_date'] ?? ''}',
                    e['type'] == 'deposit' ? 'إيداع' : 'سحب',
                    '${e['amount'] ?? 0} ${e['currency_symbol'] ?? currencySymbol}',
                  ]).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/hisabati_statement_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  Future<File> createAccountStatementExcel({
    required String currencySymbol,
    required List<Map<String, Object?>> expenses,
    required List<Map<String, Object?>> incomes,
    required List<Map<String, Object?>> advances,
    required List<Map<String, Object?>> treasury,
  }) async {
    final excel = Excel.createExcel();
    excel.delete('Sheet1');

    _writeRows(
      excel,
      'المصروفات',
      ['التاريخ', 'الوصف', 'الشخص', 'التصنيف', 'المبلغ'],
      expenses.map((e) => [
        '${e['expense_date'] ?? ''}',
        '${e['description'] ?? ''}',
        '${e['person_name'] ?? ''}',
        '${e['category_name'] ?? ''}',
        '${e['amount'] ?? 0} ${e['currency_symbol'] ?? currencySymbol}',
      ]).toList(),
    );

    _writeRows(
      excel,
      'الإيرادات',
      ['التاريخ', 'المصدر', 'الوصف', 'المبلغ'],
      incomes.map((e) => [
        '${e['income_date'] ?? ''}',
        '${e['source'] ?? ''}',
        '${e['description'] ?? ''}',
        '${e['amount'] ?? 0} ${e['currency_symbol'] ?? currencySymbol}',
      ]).toList(),
    );

    _writeRows(
      excel,
      'السلف',
      ['التاريخ', 'النوع', 'الشخص', 'المبلغ', 'ملاحظة'],
      advances.map((e) => [
        '${e['advance_date'] ?? ''}',
        e['type'] == 'advance' ? 'سلفة' : 'تسديد',
        '${e['person_name'] ?? ''}',
        '${e['amount'] ?? 0} ${e['currency_symbol'] ?? currencySymbol}',
        '${e['note'] ?? ''}',
      ]).toList(),
    );

    _writeRows(
      excel,
      'الصندوق',
      ['التاريخ', 'النوع', 'المبلغ', 'ملاحظة'],
      treasury.map((e) => [
        '${e['transaction_date'] ?? ''}',
        e['type'] == 'deposit' ? 'إيداع' : 'سحب',
        '${e['amount'] ?? 0} ${e['currency_symbol'] ?? currencySymbol}',
        '${e['note'] ?? ''}',
      ]).toList(),
    );

    final bytes = excel.encode();
    if (bytes == null) throw Exception('تعذر إنشاء ملف Excel');

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/hisabati_statement_${DateTime.now().millisecondsSinceEpoch}.xlsx');
    await file.writeAsBytes(bytes);
    return file;
  }

  num _sum(List<Map<String, Object?>> rows) {
    return rows.fold<num>(0, (sum, row) => sum + ((row['amount'] as num?) ?? 0));
  }

  pw.Widget _summaryGrid(String symbol, num expenses, num incomes, num advances, num payments, num net) {
    final items = [
      ['الإيرادات', '$incomes $symbol'],
      ['المصروفات', '$expenses $symbol'],
      ['الصافي', '$net $symbol'],
      ['السلف', '$advances $symbol'],
      ['التسديدات', '$payments $symbol'],
      ['متبقي السلف', '${advances - payments} $symbol'],
    ];

    return pw.Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        return pw.Container(
          width: 165,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(10),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(item[0], style: const pw.TextStyle(color: PdfColors.grey700)),
              pw.SizedBox(height: 4),
              pw.Text(item[1], style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ],
          ),
        );
      }).toList(),
    );
  }

  pw.Widget _sectionTable({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        if (rows.isEmpty)
          pw.Text('لا توجد بيانات')
        else
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows.take(80).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
            cellAlignment: pw.Alignment.centerRight,
          ),
      ],
    );
  }

  void _writeRows(Excel excel, String sheetName, List<String> headers, List<List<String>> rows) {
    final sheet = excel[sheetName];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    for (final row in rows) {
      sheet.appendRow(row.map((e) => TextCellValue(e)).toList());
    }
  }
}