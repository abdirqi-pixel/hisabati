import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/database_providers.dart';
import 'expense_details_screen.dart';

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenses = ref.watch(filteredExpensesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('العمليات')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/add-expense'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('عملية جديدة'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'بحث في العمليات',
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'ابحث بالاسم، التصنيف، التفاصيل، المبلغ، رقم العملية',
              ),
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: expenses.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('لا توجد عمليات مطابقة'));
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(18),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final e = items[index];
                    return Card(
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ExpenseDetailsScreen(
                                  expenseId: e['id'] as int),
                            ),
                          );
                        },
                        leading: const CircleAvatar(
                            child: Icon(Icons.receipt_long_rounded)),
                        title: Text(
                          '${e['amount']} ${e['currency_symbol']}',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${e['serial_number']} • ${e['category_name'] ?? 'بدون تصنيف'} • ${e['person_name'] ?? 'بدون شخص'}\n${e['description'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(e['expense_date'].toString()),
                            if (((e['attachment_count'] as int?) ?? 0) > 0)
                              const Icon(Icons.attach_file_rounded, size: 18),
                          ],
                        ),
                      ),
                    );
                  },
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
