import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/data/database_providers.dart';
import '../../../core/services/professional_report_service.dart';

class ProfessionalReportsScreen extends ConsumerStatefulWidget {
  const ProfessionalReportsScreen({super.key});

  @override
  ConsumerState<ProfessionalReportsScreen> createState() => _ProfessionalReportsScreenState();
}

class _ProfessionalReportsScreenState extends ConsumerState<ProfessionalReportsScreen> {
  bool working = false;

  Future<void> exportPdf({
    required bool printDirectly,
  }) async {
    setState(() => working = true);
    try {
      final settings = await ref.read(settingsProvider.future);
      final data = await ref.read(professionalReportDataProvider.future);
      final symbol = (settings?['currency_symbol'] ?? 'د.ع').toString();

      final file = await ProfessionalReportService().createAccountStatementPdf(
        title: 'كشف حساب شامل',
        currencySymbol: symbol,
        expenses: data['expenses'] ?? [],
        incomes: data['incomes'] ?? [],
        advances: data['advances'] ?? [],
        treasury: data['treasury'] ?? [],
      );

      if (printDirectly) {
        await Printing.layoutPdf(onLayout: (_) => file.readAsBytes());
      } else {
        await Share.shareXFiles([XFile(file.path)], text: 'كشف حساب من تطبيق حساباتي');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  Future<void> exportExcel() async {
    setState(() => working = true);
    try {
      final settings = await ref.read(settingsProvider.future);
      final data = await ref.read(professionalReportDataProvider.future);
      final symbol = (settings?['currency_symbol'] ?? 'د.ع').toString();

      final file = await ProfessionalReportService().createAccountStatementExcel(
        currencySymbol: symbol,
        expenses: data['expenses'] ?? [],
        incomes: data['incomes'] ?? [],
        advances: data['advances'] ?? [],
        treasury: data['treasury'] ?? [],
      );

      await Share.shareXFiles([XFile(file.path)], text: 'كشف حساب Excel من تطبيق حساباتي');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
      }
    } finally {
      if (mounted) setState(() => working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(professionalReportDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('التقارير الاحترافية')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF3B82F6)]),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 44),
                SizedBox(height: 12),
                Text(
                  'كشف حساب احترافي',
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'تصدير PDF وExcel وطباعة مباشرة لكامل بيانات التطبيق.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          data.when(
            data: (d) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('محتوى التقرير', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text('المصروفات: ${d['expenses']?.length ?? 0}'),
                      Text('الإيرادات: ${d['incomes']?.length ?? 0}'),
                      Text('السلف والتسديدات: ${d['advances']?.length ?? 0}'),
                      Text('حركات الصندوق: ${d['treasury']?.length ?? 0}'),
                    ],
                  ),
                ),
              );
            },
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('خطأ: $e'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: working ? null : () => exportPdf(printDirectly: false),
            icon: const Icon(Icons.share_rounded),
            label: const Text('تصدير ومشاركة PDF'),
          ),
          const SizedBox(height: 10),
          FilledButton.tonalIcon(
            onPressed: working ? null : exportExcel,
            icon: const Icon(Icons.table_chart_rounded),
            label: const Text('تصدير ومشاركة Excel'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: working ? null : () => exportPdf(printDirectly: true),
            icon: const Icon(Icons.print_rounded),
            label: const Text('طباعة PDF'),
          ),
          if (working)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}