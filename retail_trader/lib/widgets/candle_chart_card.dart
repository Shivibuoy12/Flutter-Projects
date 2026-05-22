import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/models.dart';
import '../theme/trader_colors.dart';

class CandleChartCard extends StatelessWidget {
  const CandleChartCard({
    super.key,
    required this.symbol,
    required this.name,
    required this.price,
    required this.dayChangePct,
    required this.candles,
  });

  final String symbol;
  final String name;
  final double price;
  final double dayChangePct;
  final List<Candle> candles;

  @override
  Widget build(BuildContext context) {
    final up = dayChangePct >= 0;
    return Container(
      decoration: BoxDecoration(
        color: TraderColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TraderColors.border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(symbol, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    Text(name, style: const TextStyle(color: TraderColors.textSecondary, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price.toStringAsFixed(price < 999 ? 2 : 2), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 10),
                    Icon(up ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded, color: up ? TraderColors.up : TraderColors.down, size: 28),
                    Text(
                      '${up ? "+" : ""}${dayChangePct.toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: up ? TraderColors.up : TraderColors.down),
                    ),
                    const SizedBox(width: 20),
                    const Text('DAY', style: TextStyle(fontSize: 11, color: TraderColors.textSecondary)),
                    const SizedBox(width: 8),
                    const Text('1W', style: TextStyle(fontSize: 11, color: TraderColors.textSecondary)),
                    const SizedBox(width: 8),
                    const Text('1M', style: TextStyle(fontSize: 11, color: TraderColors.accent)),
                    const SizedBox(width: 8),
                    const Text('1Y', style: TextStyle(fontSize: 11, color: TraderColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 200, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), child: CustomPaint(painter: _CandlePainter(candles: candles)))),
          const Padding(padding: EdgeInsets.only(bottom: 10), child: Divider(height: 1)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Wrap(
              spacing: 8,
              children: ['Depth', 'Option', 'Finance', 'News', 'Forecast']
                  .map(
                    (e) => Chip(
                      label: Text(e, style: const TextStyle(fontSize: 11)),
                      backgroundColor: TraderColors.surfaceElevated,
                      side: BorderSide(color: TraderColors.border.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _CandlePainter extends CustomPainter {
  _CandlePainter({required this.candles});
  final List<Candle> candles;

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;
    final minL = candles.map((c) => c.l).reduce(math.min);
    final maxH = candles.map((c) => c.h).reduce(math.max);
    final span = (maxH - minL).abs() < 1e-6 ? 1.0 : (maxH - minL);
    final n = candles.length;
    final gap = 1.0;
    final cw = (size.width - gap * (n + 1)) / n;
    var x = gap;
    for (final c in candles) {
      final yH = size.height * (1 - (c.h - minL) / span);
      final yL = size.height * (1 - (c.l - minL) / span);
      final yO = size.height * (1 - (c.o - minL) / span);
      final yC = size.height * (1 - (c.c - minL) / span);
      final up = c.c >= c.o;
      final col = up ? TraderColors.up : TraderColors.down;
      final px = Paint()..strokeWidth = 1;
      final bodyLeft = x + cw * 0.25;
      final bodyRight = x + cw * 0.75;
      canvas.drawLine(Offset(x + cw / 2, yH), Offset(x + cw / 2, yL), px..color = col.withValues(alpha: 0.75));
      final top = math.min(yO, yC);
      final bot = math.max(yO, yC);
      final rect = RRect.fromLTRBR(bodyLeft, top, bodyRight, bot.clamp(0.0, size.height), const Radius.circular(1));
      final fill = Paint()
        ..color = col.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(rect, fill);
      x += cw + gap;
    }
    final grid = Paint()
      ..strokeWidth = 0.5
      ..color = TraderColors.border.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < 5; i++) {
      final y = size.height * i / 5;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _CandlePainter oldDelegate) => oldDelegate.candles != candles;
}
