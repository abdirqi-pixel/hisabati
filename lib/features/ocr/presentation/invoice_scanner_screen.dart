import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/attachment_service.dart';
import '../../../core/services/invoice_ocr_service.dart';

class InvoiceScannerScreen extends StatefulWidget {
  const InvoiceScannerScreen({super.key});

  @override
  State<InvoiceScannerScreen> createState() => _InvoiceScannerScreenState();
}

class _InvoiceScannerScreenState extends State<InvoiceScannerScreen> {
  bool loading = false;

  Future<void> scanFromCamera() async {
    final file = await AttachmentService().captureInvoiceImage();
    if (file != null) await scan(file);
  }

  Future<void> scanFromGallery() async {
    final file = await AttachmentService().pickInvoiceImageFromGallery();
    if (file != null) await scan(file);
  }

  Future<void> scan(File file) async {
    setState(() => loading = true);

    try {
      final result = await InvoiceOcrService().scanInvoice(file);
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InvoiceReviewScreen(
            imagePath: file.path,
            result: result,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر قراءة الفاتورة: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ماسح الفواتير'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.document_scanner_rounded,
                    color: Colors.white, size: 48),
                SizedBox(height: 12),
                Text(
                  'قراءة الفاتورة تلقائيًا',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'صوّر الفاتورة أو اخترها من المعرض، ثم راجع البيانات قبل الحفظ.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.camera_alt_rounded),
              title: const Text('تصوير فاتورة'),
              subtitle: const Text('فتح الكاميرا وقراءة الصورة'),
              trailing: const Icon(Icons.arrow_back_ios_new_rounded),
              onTap: loading ? null : scanFromCamera,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.image_rounded),
              title: const Text('اختيار من المعرض'),
              subtitle: const Text('اختيار صورة فاتورة محفوظة'),
              trailing: const Icon(Icons.arrow_back_ios_new_rounded),
              onTap: loading ? null : scanFromGallery,
            ),
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          const SizedBox(height: 14),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'ملاحظة: دقة القراءة تعتمد على وضوح الصورة والإضاءة وجودة الفاتورة. يمكنك تعديل البيانات يدويًا قبل الحفظ.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class InvoiceReviewScreen extends StatefulWidget {
  const InvoiceReviewScreen({
    super.key,
    required this.imagePath,
    required this.result,
  });

  final String imagePath;
  final InvoiceOcrResult result;

  @override
  State<InvoiceReviewScreen> createState() => _InvoiceReviewScreenState();
}

class _InvoiceReviewScreenState extends State<InvoiceReviewScreen> {
  late final TextEditingController supplier;
  late final TextEditingController invoiceNumber;
  late final TextEditingController date;
  late final TextEditingController amount;
  late final TextEditingController currency;
  late final TextEditingController notes;

  @override
  void initState() {
    super.initState();
    supplier = TextEditingController(text: widget.result.supplierName ?? '');
    invoiceNumber =
        TextEditingController(text: widget.result.invoiceNumber ?? '');
    date = TextEditingController(
        text: widget.result.date ??
            DateTime.now().toIso8601String().split('T').first);
    amount = TextEditingController(
        text: widget.result.amount?.toStringAsFixed(0) ?? '');
    currency = TextEditingController(text: widget.result.currency ?? '');
    notes = TextEditingController(text: widget.result.rawText);
  }

  @override
  void dispose() {
    supplier.dispose();
    invoiceNumber.dispose();
    date.dispose();
    amount.dispose();
    currency.dispose();
    notes.dispose();
    super.dispose();
  }

  void goToExpense() {
    final parsedAmount = double.tryParse(amount.text.trim());

    context.go(
      Uri(
        path: '/add-expense',
        queryParameters: {
          if (parsedAmount != null) 'amount': parsedAmount.toString(),
          if (supplier.text.trim().isNotEmpty)
            'description': supplier.text.trim(),
          if (notes.text.trim().isNotEmpty)
            'notes':
                'رقم الفاتورة: ${invoiceNumber.text.trim()}\n${notes.text.trim()}',
          'attachment': widget.imagePath,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageFile = File(widget.imagePath);

    return Scaffold(
      appBar: AppBar(title: const Text('مراجعة الفاتورة')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          if (imageFile.existsSync())
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.file(imageFile),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: supplier,
            decoration: const InputDecoration(
              labelText: 'اسم المورد',
              prefixIcon: Icon(Icons.store_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: invoiceNumber,
            decoration: const InputDecoration(
              labelText: 'رقم الفاتورة',
              prefixIcon: Icon(Icons.tag_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: date,
            decoration: const InputDecoration(
              labelText: 'التاريخ',
              prefixIcon: Icon(Icons.date_range_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'المبلغ',
              prefixIcon: Icon(Icons.payments_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: currency,
            decoration: const InputDecoration(
              labelText: 'العملة',
              prefixIcon: Icon(Icons.attach_money_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: notes,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'النص المقروء / الملاحظات',
              prefixIcon: Icon(Icons.notes_rounded),
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: goToExpense,
            icon: const Icon(Icons.save_rounded),
            label: const Text('تحويل إلى مصروف'),
          ),
        ],
      ),
    );
  }
}
