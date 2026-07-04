import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickAddScreen extends StatelessWidget {
  const QuickAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        title: 'مصروف جديد',
        subtitle: 'تسجيل مبلغ مصروف مع التفاصيل والتصنيف',
        icon: Icons.receipt_long_rounded,
        route: '/add-expense',
      ),
      _QuickAction(
        title: 'ماسح الفواتير',
        subtitle: 'تصوير فاتورة وتحويلها إلى مصروف',
        icon: Icons.document_scanner_rounded,
        route: '/invoice-scanner',
      ),
      _QuickAction(
        title: 'إيراد جديد',
        subtitle: 'تسجيل دخل أو وارد للمشروع',
        icon: Icons.trending_up_rounded,
        route: '/incomes',
      ),
      _QuickAction(
        title: 'عملية دورية',
        subtitle: 'مصروف أو إيراد يتكرر تلقائيًا',
        icon: Icons.repeat_rounded,
        route: '/recurring',
      ),
      _QuickAction(
        title: 'حركة صندوق',
        subtitle: 'إضافة إيداع أو سحب من الصندوق',
        icon: Icons.account_balance_wallet_rounded,
        route: '/treasury',
      ),
      _QuickAction(
        title: 'سلفة أو تسديد',
        subtitle: 'تسجيل سلفة لشخص أو تسديد جزء منها',
        icon: Icons.handshake_rounded,
        route: '/advances',
      ),
      _QuickAction(
        title: 'شخص جديد',
        subtitle: 'إضافة شخص داخل المشروع',
        icon: Icons.person_add_rounded,
        route: '/persons',
      ),
      _QuickAction(
        title: 'مشروع جديد',
        subtitle: 'إنشاء مشروع وإعداد ميزانيته',
        icon: Icons.create_new_folder_rounded,
        route: '/project-form',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('إضافة سريعة')),
      body: ListView.separated(
        padding: const EdgeInsets.all(18),
        itemCount: actions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final action = actions[index];

          return Card(
            child: ListTile(
              leading: CircleAvatar(child: Icon(action.icon)),
              title: Text(action.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(action.subtitle),
              trailing: const Icon(Icons.arrow_back_ios_new_rounded),
              onTap: () => context.go(action.route),
            ),
          );
        },
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}