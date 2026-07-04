import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class InvoiceOcrResult {
  const InvoiceOcrResult({
    required this.rawText,
    this.supplierName,
    this.invoiceNumber,
    this.date,
    this.amount,
    this.currency,
  });

  final String rawText;
  final String? supplierName;
  final String? invoiceNumber;
  final String? date;
  final double? amount;
  final String? currency;
}

class InvoiceOcrService {
  Future<InvoiceOcrResult> scanInvoice(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognized = await recognizer.processImage(inputImage);
      final rawText = recognized.text;

      return InvoiceOcrResult(
        rawText: rawText,
        supplierName: _extractSupplier(rawText),
        invoiceNumber: _extractInvoiceNumber(rawText),
        date: _extractDate(rawText),
        amount: _extractAmount(rawText),
        currency: _extractCurrency(rawText),
      );
    } finally {
      await recognizer.close();
    }
  }

  String? _extractSupplier(String text) {
    final lines = text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.length >= 3)
        .toList();

    if (lines.isEmpty) return null;

    final ignoredWords = [
      'invoice',
      'receipt',
      'فاتورة',
      'وصل',
      'tax',
      'total',
      'amount',
      'المجموع',
      'الاجمالي',
      'الإجمالي',
    ];

    for (final line in lines.take(6)) {
      final lower = line.toLowerCase();
      if (!ignoredWords.any((w) => lower.contains(w.toLowerCase()))) {
        return line;
      }
    }

    return lines.first;
  }

  String? _extractInvoiceNumber(String text) {
    final patterns = [
      RegExp(
          r'(invoice|receipt|bill)\s*(no|number|#)?\s*[:\-]?\s*([A-Za-z0-9\-\/]+)',
          caseSensitive: false),
      RegExp(r'(رقم\s*الفاتورة|رقم\s*الوصل)\s*[:\-]?\s*([A-Za-z0-9\-\/]+)',
          caseSensitive: false),
      RegExp(r'#\s*([A-Za-z0-9\-\/]{3,})'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(match.groupCount);
      }
    }

    return null;
  }

  String? _extractDate(String text) {
    final patterns = [
      RegExp(r'\b(\d{4}[-/]\d{1,2}[-/]\d{1,2})\b'),
      RegExp(r'\b(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})\b'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1);
    }

    return null;
  }

  double? _extractAmount(String text) {
    final amountLike =
        RegExp(r'(\d{1,3}(?:[,\s]\d{3})*(?:[.]\d{1,2})?|\d+(?:[.]\d{1,2})?)');
    final lines = text.split('\n');

    final priorityWords = [
      'total',
      'amount',
      'grand total',
      'net total',
      'المجموع',
      'الإجمالي',
      'الاجمالي',
      'المبلغ',
    ];

    final candidates = <double>[];

    for (final line in lines) {
      final lower = line.toLowerCase();
      final hasPriority =
          priorityWords.any((w) => lower.contains(w.toLowerCase()));
      final matches = amountLike.allMatches(line);

      for (final match in matches) {
        final parsed = _parseNumber(match.group(1));
        if (parsed != null) {
          if (hasPriority) return parsed;
          candidates.add(parsed);
        }
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort();
    return candidates.last;
  }

  double? _parseNumber(String? value) {
    if (value == null) return null;
    final normalized = value.replaceAll(',', '').replaceAll(' ', '');
    return double.tryParse(normalized);
  }

  String? _extractCurrency(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('د.ع') ||
        lower.contains('iqd') ||
        lower.contains('دينار')) return 'د.ع';
    if (lower.contains(r'$') ||
        lower.contains('usd') ||
        lower.contains('dollar')) return r'$';
    if (lower.contains('sar') || lower.contains('ر.س')) return 'ر.س';
    if (lower.contains('aed') || lower.contains('د.إ')) return 'د.إ';
    if (lower.contains('kwd') || lower.contains('د.ك')) return 'د.ك';
    if (lower.contains('egp') || lower.contains('ج.م')) return 'ج.م';
    if (lower.contains('try') || lower.contains('₺')) return '₺';
    return null;
  }
}
