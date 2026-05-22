import 'package:flutter/material.dart';

import '../data/sample_data.dart';
import '../models/models.dart';
import '../theme/trader_colors.dart';
import '../widgets/market_movers_table.dart';

class MoversScreenerPage extends StatelessWidget {
  const MoversScreenerPage({super.key, required this.watchlist});

  final List<WatchRow> watchlist;

  @override
  Widget build(BuildContext context) {
    final top = [...watchlist]..sort((a, b) => b.changePct.compareTo(a.changePct));
    final bot = [...watchlist]..sort((a, b) => a.changePct.compareTo(b.changePct));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.start,
            children: [
              SizedBox(width: 420, child: MarketMoversTable(title: 'Top gainers (mock)', rows: top.take(5).toList())),
              SizedBox(width: 420, child: MarketMoversTable(title: 'Top losers (mock)', rows: bot.take(5).toList())),
              SizedBox(width: 420, child: _NewsCard(items: kNewsFeed)),
              SizedBox(width: 420, child: _FundsCard()),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewsCard extends StatelessWidget {
  const _NewsCard({required this.items});
  final List<NewsItem> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: TraderColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: TraderColors.border.withValues(alpha: 0.7))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Breaking', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 12),
            ...items.map(
              (n) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(n.headline, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                subtitle: Text('${n.source} · ${n.age}', style: const TextStyle(color: TraderColors.textSecondary, fontSize: 11)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FundsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: TraderColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: TraderColors.border.withValues(alpha: 0.7))),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Account overview', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            SizedBox(height: 10),
            _Row(k: 'Net liq.', v: r'$412,892.71'),
            _Row(k: 'Day P/L', v: r'+$1,204.32', highlight: TraderColors.up),
            _Row(k: 'Unsettled funds', v: r'$4,820.15'),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.k, required this.v, this.highlight});
  final String k;
  final String v;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(k, style: const TextStyle(color: TraderColors.textSecondary, fontSize: 13)),
          const Spacer(),
          Text(v, style: TextStyle(fontWeight: FontWeight.w700, color: highlight ?? TraderColors.textPrimary)),
        ],
      ),
    );
  }
}
