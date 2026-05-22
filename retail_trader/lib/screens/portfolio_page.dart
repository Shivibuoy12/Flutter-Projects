import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../theme/trader_colors.dart';
import '../widgets/positions_table.dart';

class PortfolioPage extends StatelessWidget {
  const PortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pos = samplePositions();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Portfolio', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: const [
                  _StatCard(title: 'Total value', value: r'$128,420.11', sub: r'+$420.12 today'),
                  _StatCard(title: 'Cash', value: r'$32,110.00', sub: 'Settled'),
                  _StatCard(title: 'Margin used', value: r'$2,400.00', sub: 'Reg-T'),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                color: TraderColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: TraderColors.border.withValues(alpha: 0.75)),
                ),
                child: Padding(padding: const EdgeInsets.all(8), child: PositionsTable(rows: pos)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value, required this.sub});
  final String title;
  final String value;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        color: TraderColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: TraderColors.border.withValues(alpha: 0.55))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: TraderColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(sub, style: const TextStyle(fontSize: 11, color: TraderColors.up)),
            ],
          ),
        ),
      ),
    );
  }
}
