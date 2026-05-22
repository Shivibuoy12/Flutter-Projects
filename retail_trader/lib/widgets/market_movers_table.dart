import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/trader_colors.dart';

class MarketMoversTable extends StatelessWidget {
  const MarketMoversTable({super.key, required this.title, required this.rows});

  final String title;
  final List<WatchRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: TraderColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: TraderColors.border.withValues(alpha: 0.7))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 8),
            ...rows.map(
              (r) {
                final up = r.changePct >= 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(width: 56, child: Text(r.symbol, style: const TextStyle(fontWeight: FontWeight.w800))),
                      Expanded(child: Text(r.name, style: const TextStyle(color: TraderColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis)),
                      Text(r.last.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 64,
                        child: Text(
                          '${up ? "+" : ""}${r.changePct.toStringAsFixed(2)}%',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: up ? TraderColors.up : TraderColors.down, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
