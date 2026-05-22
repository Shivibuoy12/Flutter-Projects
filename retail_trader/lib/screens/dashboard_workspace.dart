import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../models/models.dart';
import '../services/gateway_service.dart';
import '../theme/trader_colors.dart';
import '../widgets/candle_chart_card.dart';
import '../widgets/order_entry_panel.dart';
import '../widgets/watchlist_sidebar.dart';

/// Main Webull-like workspace: left watchlist · center quote+chart · right ticket.
class DashboardWorkspace extends StatefulWidget {
  const DashboardWorkspace({
    super.key,
    required this.watchlist,
    this.initialSymbol,
    this.detailHeight,
  });

  final List<WatchRow> watchlist;
  final String? initialSymbol;
  final double? detailHeight;

  @override
  State<DashboardWorkspace> createState() => _DashboardWorkspaceState();
}

class _DashboardWorkspaceState extends State<DashboardWorkspace> {
  late WatchRow _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.watchlist.firstWhere(
      (w) => w.symbol == (widget.initialSymbol ?? widget.watchlist.first.symbol),
      orElse: () => widget.watchlist.first,
    );
  }

  @override
  void didUpdateWidget(covariant DashboardWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.watchlist, oldWidget.watchlist)) {
      final exists = widget.watchlist.any((w) => w.symbol == _selected.symbol);
      if (!exists) _selected = widget.watchlist.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final candles = buildCandles(n: 96, start: _selected.last * 0.92);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 980;
        if (wide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 280, child: WatchlistSidebar(rows: widget.watchlist, selected: _selected, onSelect: (w) => setState(() => _selected = w))),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Expanded(
                        child: CandleChartCard(
                          symbol: _selected.symbol,
                          name: _selected.name,
                          price: _selected.last,
                          dayChangePct: _selected.changePct,
                          candles: candles,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _DepthBookMock(symbol: _selected.symbol),
                    ],
                  ),
                ),
              ),
SizedBox(
                  width: 320,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 12, 12),
                    child: SingleChildScrollView(
                      child: OrderEntryPanel(
                        watch: _selected,
                        gateway: context.watch<GatewayService>(),
                      ),
                    ),
                  ),
                ),
            ],
          );
        }
        return ListView(
          padding: const EdgeInsets.all(10),
          children: [
            SizedBox(height: 320, child: WatchlistSidebar(rows: widget.watchlist, selected: _selected, onSelect: (w) => setState(() => _selected = w))),
            const SizedBox(height: 12),
            CandleChartCard(symbol: _selected.symbol, name: _selected.name, price: _selected.last, dayChangePct: _selected.changePct, candles: candles),
            const SizedBox(height: 12),
            OrderEntryPanel(
              watch: _selected,
              gateway: context.watch<GatewayService>(),
            ),
          ],
        );
      },
    );
  }
}

class _DepthBookMock extends StatelessWidget {
  const _DepthBookMock({required this.symbol});
  final String symbol;

  @override
  Widget build(BuildContext context) {
    final bids = ['228.41', '228.38', '228.34', '228.31', '228.29'];
    final asks = ['228.45', '228.48', '228.53', '228.56', '228.61'];
    return Container(
      height: 148,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TraderColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TraderColors.border.withValues(alpha: 0.55)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Bid book', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TraderColors.up)),
                const Divider(height: 12),
                ...bids.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Text('×${4200 - e.key * 300}', style: const TextStyle(fontSize: 11, color: TraderColors.textSecondary)),
                        const Spacer(),
                        Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ]),
                    )),
              ],
            ),
          ),
          const VerticalDivider(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Ask book', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: TraderColors.down)),
                const Divider(height: 12),
                ...asks.asMap().entries.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(children: [
                        Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('×${3900 + e.key * 250}', style: const TextStyle(fontSize: 11, color: TraderColors.textSecondary)),
                      ]),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
