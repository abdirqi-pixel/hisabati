import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class GlobalSearchScreen extends ConsumerWidget {
  const GlobalSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(globalSearchProvider);
    final query = ref.watch(globalSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('البحث الذكي')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'ابحث في حساباتي',
                hintText: 'مشروع، شخص، مبلغ، تصنيف، رقم عملية، ملاحظة...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (value) => ref.read(globalSearchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: query.trim().isEmpty
                ? const Center(child: Text('اكتب كلمة للبحث في كل بيانات التطبيق'))
                : results.when(
                    data: (data) {
                      final total = data.values.fold<int>(0, (sum, list) => sum + list.length);
                      if (total == 0) {
                        return const Center(child: Text('لا توجد نتائج مطابقة'));
                      }

                      return ListView(
                        padding: const EdgeInsets.all(18),
                        children: [
                          _Section(title: 'المشاريع', icon: Icons.folder_rounded, items: data['projects'] ?? [], builder: (item) {
                            return '${item['name']} • ${item['currency_symbol'] ?? ''}';
                          }),
                          _Section(title: 'الأشخاص', icon: Icons.person_rounded, items: data['persons'] ?? [], builder: (item) {
                            return '${item['name']} • ${item['project_name'] ?? 'بدون مشروع'}';
                          }),
                          _Section(title: 'المصروفات', icon: Icons.receipt_long_rounded, items: data['expenses'] ?? [], builder: (item) {
                            return '${item['serial_number']} • ${item['amount']} ${item['currency_symbol']} • ${item['person_name'] ?? 'بدون شخص'} • ${item['category_name'] ?? 'بدون تصنيف'}';
                          }),
                          _Section(title: 'الإيرادات', icon: Icons.trending_up_rounded, items: data['incomes'] ?? [], builder: (item) {
                            return '${item['amount']} ${item['currency_symbol']} • ${item['source'] ?? 'بدون مصدر'} • ${item['project_name'] ?? ''}';
                          }),
                          _Section(title: 'الديون والسلف', icon: Icons.handshake_rounded, items: data['advances'] ?? [], builder: (item) {
                            final type = item['type'] == 'advance' ? 'سلفة' : 'تسديد';
                            return '$type • ${item['amount']} ${item['currency_symbol']} • ${item['person_name'] ?? 'بدون شخص'}';
                          }),
                          _Section(title: 'الصندوق', icon: Icons.account_balance_wallet_rounded, items: data['treasury'] ?? [], builder: (item) {
                            final type = item['type'] == 'deposit' ? 'إيداع' : 'سحب';
                            return '$type • ${item['amount']} ${item['currency_symbol']} • ${item['project_name'] ?? ''}';
                          }),
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('خطأ: $e')),
                  ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.icon,
    required this.items,
    required this.builder,
  });

  final String title;
  final IconData icon;
  final List<Map<String, Object?>> items;
  final String Function(Map<String, Object?> item) builder;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$title (${items.length})', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...items.map((item) {
          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(icon)),
              title: Text(builder(item), style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('ID: ${item['id']}'),
            ),
          );
        }),
        const SizedBox(height: 18),
      ],
    );
  }
}