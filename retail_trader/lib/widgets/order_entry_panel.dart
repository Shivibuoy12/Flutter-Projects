import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/gateway_service.dart';
import '../theme/trader_colors.dart';

List<String> _orderTicketIssues({
  required GatewayService? gateway,
  required WatchRow watch,
  required int? qty,
  required double? limitPx,
}) {
  final parts = <String>[];
  if (gateway == null) {
    parts.add('Gateway not wired to this screen');
  } else {
    if (!gateway.connected) {
      parts.add('TCP not connected — tap the cloud icon and ensure the mock is listening on host/port');
    } else if (!gateway.loggedIn) {
      parts.add(
        'TCP open but LOGIN not accepted (mock must reply with acceptance). Open Orders tab → Gateway message log.',
      );
      final err = gateway.connectionError?.trim();
      if (err != null && err.isNotEmpty) {
        parts.add(err);
      }
    }
  }

  final inst = watch.instrumentId;
  if (inst == null || inst <= 0) {
    parts.add(
      'No instrument_id on this row — use symbols loaded from fmx_instruments.json, not Stocks quick-add demos',
    );
  }

  if (qty == null || qty <= 0) {
    parts.add('Quantity must be a positive whole number');
  }
  if (limitPx == null) {
    parts.add('Enter a numeric limit price');
  }

  return parts;
}

Color _ticketStatusColor(bool ok) {
  if (ok) {
    return TraderColors.up.withValues(alpha: 0.22);
  }
  return TraderColors.down.withValues(alpha: 0.18);
}

class OrderEntryPanel extends StatefulWidget {
  const OrderEntryPanel({
    super.key,
    required this.watch,
    this.gateway,
  });

  /// Optional TCP gateway (`Server_Side_Mock`). Orders send only when connected + logged in + [WatchRow.instrumentId] set.
  final WatchRow watch;
  final GatewayService? gateway;

  @override
  State<OrderEntryPanel> createState() => _OrderEntryPanelState();
}

class _OrderEntryPanelState extends State<OrderEntryPanel> {
  bool _buy = true;
  final TextEditingController _qty = TextEditingController(text: '100');
  final TextEditingController _limit = TextEditingController();
  String _orderType = 'Limit';
  String _tif = 'DAY';

  void _rebroadcastFormFromFields() => setState(() {});

  @override
  void initState() {
    super.initState();
    _limit.text = widget.watch.last.toStringAsFixed(2);
    _qty.addListener(_rebroadcastFormFromFields);
    _limit.addListener(_rebroadcastFormFromFields);
  }

  @override
  void didUpdateWidget(covariant OrderEntryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.watch.symbol != widget.watch.symbol) {
      _limit.text = widget.watch.last.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _qty.removeListener(_rebroadcastFormFromFields);
    _limit.removeListener(_rebroadcastFormFromFields);
    _qty.dispose();
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gw = widget.gateway;
    final qtyTry = int.tryParse(_qty.text.trim());
    final pxTry = double.tryParse(_limit.text.trim());
    final issues = _orderTicketIssues(
      gateway: gw,
      watch: widget.watch,
      qty: qtyTry,
      limitPx: pxTry,
    );
    final canSend = issues.isEmpty;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: TraderColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TraderColors.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Row(
              children: [
                const Expanded(child: Text('Order ticket', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                Text(widget.watch.symbol, style: const TextStyle(color: TraderColors.textSecondary)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: _ticketStatusColor(canSend),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: TraderColors.border.withValues(alpha: 0.55)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          canSend
                              ? 'Gateway ready — tap Buy/Sell to send (Futures extended enter).'
                              : 'Cannot send yet:',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        if (!canSend) ...[
                          const SizedBox(height: 4),
                          for (final p in issues)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('• ', style: TextStyle(fontSize: 10.5)),
                                  Expanded(child: Text(p, style: const TextStyle(fontSize: 10.5, height: 1.35))),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quote is display-only (${widget.watch.last.toStringAsFixed(3)}) — '
                  '`fmx_instruments.json` has multipliers/state, not a live last-trade feed.',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: TraderColors.textSecondary.withValues(alpha: 0.95),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ToggleButtons(
              isSelected: [_buy, !_buy],
              onPressed: (i) => setState(() => _buy = i == 0),
              borderRadius: BorderRadius.circular(8),
              constraints: const BoxConstraints(minHeight: 40, minWidth: 140),
              color: TraderColors.textSecondary,
              selectedColor: Colors.black,
              fillColor: _buy ? TraderColors.up.withValues(alpha: 0.92) : TraderColors.down.withValues(alpha: 0.92),
              children: const [Text('Buy', style: TextStyle(fontWeight: FontWeight.w800)), Text('Sell', style: TextStyle(fontWeight: FontWeight.w800))],
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _orderType,
                    decoration: const InputDecoration(labelText: 'Type'),
                    items: const [
                      DropdownMenuItem(value: 'Limit', child: Text('Limit')),
                      DropdownMenuItem(value: 'Market', child: Text('Market')),
                      DropdownMenuItem(value: 'Stop', child: Text('Stop Limit')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _orderType = v);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _tif,
                    decoration: const InputDecoration(labelText: 'TIF'),
                    items: const [
                      DropdownMenuItem(value: 'DAY', child: Text('DAY')),
                      DropdownMenuItem(value: 'GTC', child: Text('GTC')),
                      DropdownMenuItem(value: 'IOC', child: Text('IOC')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _tif = v);
                        widget.gateway?.applyUiTif(v);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _qty,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              controller: _limit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Limit price'),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final g = widget.gateway;
                      final working = g?.lastAcceptedOrderId?.trim();
                      if (g == null ||
                          !g.connected ||
                          !g.loggedIn ||
                          working == null ||
                          working.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Cancel: connect + accept an order first (waiting list uses last Accepted id)',
                              ),
                            ),
                          );
                        }
                        return;
                      }
                      final ok = await g.submitCancelWorkingOrder(brokerOrderId: working);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok ? 'Cancel sent ($working)' : 'Cancel failed (see gateway log)',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      final g = widget.gateway;
                      final orig = g?.lastAcceptedOrderId?.trim();
                      final qty = int.tryParse(_qty.text.trim());
                      final px = double.tryParse(_limit.text.trim());
                      final inst = widget.watch.instrumentId ?? g?.lastInstrumentId;
                      if (g == null ||
                          !g.connected ||
                          !g.loggedIn ||
                          orig == null ||
                          orig.isEmpty ||
                          inst == null ||
                          inst <= 0 ||
                          qty == null ||
                          qty <= 0 ||
                          px == null) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Modify: accepted order required + instrument row + qty/price — check connection',
                              ),
                            ),
                          );
                        }
                        return;
                      }
                      final newOid =
                          'RP_${(DateTime.now().microsecondsSinceEpoch % 899999999990).toString()}';
                      final ok = await g.submitReplaceModifyOrder(
                        originatingOrderId: orig,
                        replacementOrderId: newOid,
                        instrumentId: inst,
                        qty: qty,
                        limitPriceDisplay: px,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? 'Replace sent → $newOid (orig=$orig)'
                                  : 'Replace failed (see gateway log)',
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text('Modify (replace)'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _buy ? TraderColors.up : TraderColors.down,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final g = widget.gateway;
                      final qty = int.tryParse(_qty.text.trim());
                      final px = double.tryParse(_limit.text.trim());
                      final sendIssues = _orderTicketIssues(
                        gateway: g,
                        watch: widget.watch,
                        qty: qty,
                        limitPx: px,
                      );
                      if (sendIssues.isNotEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(sendIssues.join('\n')),
                              duration: const Duration(seconds: 8),
                            ),
                          );
                        }
                        return;
                      }
                      final inst = widget.watch.instrumentId!;
                      final oid = 'FL_${(DateTime.now().microsecondsSinceEpoch % 899999999990).toString()}';
                      final ok = await g!.submitLimitOrder(
                        orderId: oid,
                        instrumentId: inst,
                        qty: qty!,
                        priceDisplay: px!,
                        sideBuy: _buy,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              ok
                                  ? '${_buy ? "Buy" : "Sell"} sent $oid (${widget.watch.symbol})'
                                  : 'Order not sent (check Orders tab gateway log)',
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(_buy ? 'Buy' : 'Sell', style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              r'Buying power — est. $128,240.12',
              style: TextStyle(fontSize: 11, color: TraderColors.textSecondary),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
