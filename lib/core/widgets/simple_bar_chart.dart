import 'package:flutter/material.dart';

class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({
    super.key,
    required this.title,
    required this.items,
    required this.valueLabelBuilder,
  });

  final String title;
  final List<ChartItem> items;
  final String Function(num value) valueLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.isEmpty
        ? 1
        : items.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            if (items.isEmpty)
              const Text('لا توجد بيانات')
            else
              ...items.map((item) {
                final percent = maxValue == 0 ? 0.0 : (item.value / maxValue).clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(item.label, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text(
                            valueLabelBuilder(item.value),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: percent,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class ChartItem {
  const ChartItem({
    required this.label,
    required this.value,
  });

  final String label;
  final num value;
}