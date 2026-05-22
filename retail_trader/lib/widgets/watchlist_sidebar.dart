import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/trader_colors.dart';

class WatchlistSidebar extends StatelessWidget {
  const WatchlistSidebar({
    super.key,
    required this.rows,
    required this.selected,
    required this.onSelect,
  });

  final List<WatchRow> rows;
  final WatchRow selected;
  final ValueChanged<WatchRow> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TraderColors.surface,
        border: Border(right: BorderSide(color: TraderColors.border.withValues(alpha: 0.85))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                const Expanded(child: Text('Watchlists', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                IconButton(icon: const Icon(Icons.add, size: 20), constraints: const BoxConstraints(minWidth: 36, minHeight: 36), onPressed: () {}),
              ],
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: _ListChip(active: true, label: 'Favorites')),
          const SizedBox(height: 6),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: _ListChip(active: false, label: 'Tech')),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: _ListChip(active: false, label: 'Crypto')),
          const Divider(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: const [
                Expanded(flex: 3, child: Text('Symbol', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TraderColors.textSecondary))),
                Expanded(flex: 2, child: Text('Last', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TraderColors.textSecondary))),
                Expanded(flex: 2, child: Text('Chg%', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: TraderColors.textSecondary))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rows.length,
              padding: EdgeInsets.zero,
              itemBuilder: (_, i) {
                final row = rows[i];
                final sel = row.symbol == selected.symbol;
                final up = row.changePct >= 0;
                return Material(
                  color: sel ? TraderColors.surfaceElevated : Colors.transparent,
                  child: InkWell(
                    onTap: () => onSelect(row),
                    hoverColor: TraderColors.surfaceElevated.withValues(alpha: 0.85),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(row.symbol, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                if (row.instrumentId != null)
                                  Text(
                                    'id ${row.instrumentId}',
                                    style: const TextStyle(fontSize: 10, color: TraderColors.textSecondary),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(row.last.toStringAsFixed(row.last < 60 ? 2 : 2), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13)),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              '${row.changePct >= 0 ? "+" : ""}${row.changePct.toStringAsFixed(2)}%',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: up ? TraderColors.up : TraderColors.down),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ListChip extends StatelessWidget {
  const _ListChip({required this.active, required this.label});
  final bool active;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: active ? TraderColors.surfaceElevated : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? TraderColors.border : TraderColors.surface),
      ),
      child: Align(alignment: Alignment.centerLeft, child: Text(label, style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500))),
    );
  }
}
