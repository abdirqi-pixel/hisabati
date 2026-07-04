import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickAddFab extends StatelessWidget {
  const QuickAddFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => context.go('/quick-add'),
      icon: const Icon(Icons.add_rounded),
      label: const Text('إضافة'),
    );
  }
}
