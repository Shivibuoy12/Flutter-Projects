import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/trader_colors.dart';

class MarketTickerStrip extends StatelessWidget {
  const MarketTickerStrip({super.key, required this.quotes});

  final List<IndexQuote> quotes;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(color: TraderColors.surface, border: Border(bottom: BorderSide(color: TraderColors.border.withValues(alpha: 0.85)))),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: quotes.length + 8,
        separatorBuilder: (_, _) => const VerticalDivider(width: 1),
        itemBuilder: (ctx, i) {
          final q = quotes[i % quotes.length];
          final up = q.changePct >= 0;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(q.label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: TraderColors.textSecondary)),
                const SizedBox(width: 8),
                Text(q.price.toStringAsFixed(q.label == 'VIX' ? 2 : 2), style: const TextStyle(fontSize: 12.5)),
                const SizedBox(width: 6),
                Row(
                  children: [
                    Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: up ? TraderColors.up : TraderColors.down, size: 20),
                    Text(
                      '${up ? "+" : ""}${q.changePct.toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: up ? TraderColors.up : TraderColors.down),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
