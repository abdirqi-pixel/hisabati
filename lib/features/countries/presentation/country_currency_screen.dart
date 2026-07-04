import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database_providers.dart';

class CountryCurrencyScreen extends ConsumerWidget {
  const CountryCurrencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countries = ref.watch(countriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('اختيار البلد والعملة')),
      body: countries.when(
        data: (items) => ListView.separated(
          padding: const EdgeInsets.all(18),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final c = items[index];
            return Card(
              child: ListTile(
                leading: const Icon(Icons.public_rounded),
                title: Text(c['name_ar'] as String),
                subtitle: Text('${c['currency_code']} - ${c['currency_symbol']}'),
                trailing: const Icon(Icons.arrow_back_ios_new_rounded),
                onTap: () async {
                  final db = await ref.read(appDatabaseProvider).database;
                  await db.update(
                    'app_settings',
                    {
                      'country_code': c['code'],
                      'currency_code': c['currency_code'],
                      'currency_symbol': c['currency_symbol'],
                    },
                    where: 'id = ?',
                    whereArgs: [1],
                  );
                  ref.invalidate(settingsProvider);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('خطأ: $e')),
      ),
    );
  }
}