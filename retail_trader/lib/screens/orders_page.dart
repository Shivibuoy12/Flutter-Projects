import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/sample_data.dart';
import '../models/models.dart';
import '../services/gateway_service.dart';
import '../theme/trader_colors.dart';
import '../widgets/order_blotter_table.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context) {
    final gw = context.watch<GatewayService>();
    final blot = gw.blotRows;
    final sessionLive = gw.connected && gw.loggedIn;
    final useSampleFallback = blot.isEmpty && !sessionLive;
    final rows = blot.isNotEmpty ? blot : (useSampleFallback ? sampleBlotters() : const <OrderBlotRow>[]);
    final blotterHint = blot.isNotEmpty
        ? ''
        : sessionLive
            ? 'Live session — no blotter rows yet (or only “Sent — waiting for Accepted” until the gateway ACK parses).'
            : 'Offline — demo sample rows only.';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text('Order blotter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(width: 10),
                  if (sessionLive)
                    const Icon(Icons.link, size: 18, color: TraderColors.up)
                  else
                    Text(
                      '(offline — sample rows only)',
                      style: TextStyle(fontSize: 12, color: TraderColors.textSecondary.withValues(alpha: 0.85)),
                    ),
                  const Spacer(),
                  FilledButton.tonalIcon(onPressed: () {}, icon: const Icon(Icons.filter_list, size: 18), label: const Text('Filters')),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download_outlined, size: 18), label: const Text('Export CSV')),
                ],
              ),
              if (blotterHint.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  blotterHint,
                  style: TextStyle(fontSize: 12, color: TraderColors.textSecondary.withValues(alpha: 0.9)),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                color: TraderColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: TraderColors.border.withValues(alpha: 0.75)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: blot.isEmpty && sessionLive && rows.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No rows yet.\nPlace an order from Charts — you should see “Sent — waiting for Accepted”, then “Accepted” after the mock/gateway sends an Accepted message (or “Reject …” if declined).',
                            style: TextStyle(
                              height: 1.45,
                              color: TraderColors.textSecondary.withValues(alpha: 0.95),
                              fontSize: 13,
                            ),
                          ),
                        )
                      : OrderBlotterTable(rows: rows),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                sessionLive || gw.messageLog.isNotEmpty
                    ? 'Gateway message log'
                    : 'Demo log (not connected)',
                style: const TextStyle(color: TraderColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 6),
              if (sessionLive || gw.messageLog.isNotEmpty)
                for (final line in gw.messageLog.take(36)) _LogLine(text: line)
              else ...[
                const _LogLine(text: '10:22:01  J  X  Replace (order C318B1) — invalid price'),
                const _LogLine(text: '10:22:01  C  F  Cancelled C318B1 — failure to replace'),
                const _LogLine(text: '10:24:18  U  —  Replaced C318A1 → C318A2 (qty 80 @ 5002.00)'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: TraderColors.surfaceElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: TraderColors.border.withValues(alpha: 0.5)),
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'monospace', fontSize: 11.5)),
    );
  }
}
