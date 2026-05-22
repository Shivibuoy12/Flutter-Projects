import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/trader_colors.dart';

String formatBlotterPrice(double px) {
  if (px.isNaN || px.isInfinite) {
    return '—';
  }
  var s = px.toStringAsFixed(5);
  if (!s.contains('.')) {
    return s;
  }
  while (s.endsWith('0')) {
    s = s.substring(0, s.length - 1);
  }
  if (s.endsWith('.')) {
    s = s.substring(0, s.length - 1);
  }
  return s.isEmpty ? '0' : s;
}

class OrderBlotterTable extends StatelessWidget {
  const OrderBlotterTable({super.key, required this.rows});

  final List<OrderBlotRow> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 40,
        dataRowMaxHeight: 44,
        columns: const [
          DataColumn(label: Text('Order ID')),
          DataColumn(label: Text('Chain')),
          DataColumn(label: Text('Symbol')),
          DataColumn(label: Text('Instr id'), numeric: true),
          DataColumn(label: Text('Side')),
          DataColumn(label: Text('Qty'), numeric: true),
          DataColumn(label: Text('Avg / Lmt'), numeric: true),
          DataColumn(label: Text('TIF')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Updated')),
        ],
        rows: rows
            .map(
              (r) => DataRow(
                cells: [
                  DataCell(Text(r.orderId, style: const TextStyle(fontWeight: FontWeight.w600))),
                  DataCell(Text(r.chainId, style: const TextStyle(color: TraderColors.textSecondary, fontSize: 12))),
                  DataCell(Text(r.symbol)),
                  DataCell(Text(r.instrumentId == 0 ? '—' : '${r.instrumentId}')),
                  DataCell(
                    Text(
                      r.side ? 'BUY' : 'SELL',
                      style: TextStyle(color: r.side ? TraderColors.up : TraderColors.down, fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                  DataCell(Text('${r.liveQty}')),
                  DataCell(Text(formatBlotterPrice(r.avgPx))),
                  DataCell(Text(r.tif)),
                  DataCell(_StatusPill(text: r.status)),
                  DataCell(Text(r.updated, style: const TextStyle(fontSize: 12, color: TraderColors.textSecondary))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    Color c = TraderColors.textSecondary;
    if (text == 'Working') c = TraderColors.accent;
    if (text == 'Partial') c = TraderColors.warn;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.45)),
      ),
      child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }
}
