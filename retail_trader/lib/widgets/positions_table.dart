import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/trader_colors.dart';

class PositionsTable extends StatelessWidget {
  const PositionsTable({super.key, required this.rows});

  final List<PositionRow> rows;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 36,
        dataRowMinHeight: 40,
        columns: const [
          DataColumn(label: Text('Symbol')),
          DataColumn(label: Text('Qty'), numeric: true),
          DataColumn(label: Text('Avg cost'), numeric: true),
          DataColumn(label: Text('Last'), numeric: true),
          DataColumn(label: Text("Day P&L"), numeric: true),
          DataColumn(label: Text('Total P&L'), numeric: true),
        ],
        rows: rows.map((p) {
          final dUp = p.dayPnl >= 0;
          final tUp = p.totalPnl >= 0;
          return DataRow(
            cells: [
              DataCell(Text(p.symbol, style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text('${p.qty}')),
              DataCell(Text(p.avgCost.toStringAsFixed(2))),
              DataCell(Text(p.market.toStringAsFixed(2))),
              DataCell(
                Text(
                  '${dUp ? "+" : ""}${p.dayPnl.toStringAsFixed(2)}',
                  style: TextStyle(color: dUp ? TraderColors.up : TraderColors.down, fontWeight: FontWeight.w600),
                ),
              ),
              DataCell(
                Text(
                  '${tUp ? "+" : ""}${p.totalPnl.toStringAsFixed(2)}',
                  style: TextStyle(color: tUp ? TraderColors.up : TraderColors.down, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
