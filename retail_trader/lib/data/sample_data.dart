import 'dart:math';

import '../models/models.dart';

final Random _r = Random(42);

final List<IndexQuote> kIndexStrip = [
  IndexQuote(label: 'S&P500', price: 5124.53, changePct: 0.42),
  IndexQuote(label: 'Nasdaq100', price: 18102.71, changePct: 0.78),
  IndexQuote(label: 'Dow Jones', price: 38912.41, changePct: 0.19),
  IndexQuote(label: 'VIX', price: 14.22, changePct: -3.61),
];

List<WatchRow> get watchDefaults => [
  WatchRow(symbol: 'AAPL', name: 'Apple Inc.', last: 227.82, changePct: 1.06, volM: 58.4),
  WatchRow(symbol: 'NVDA', name: 'NVIDIA Corp.', last: 128.93, changePct: -0.94, volM: 202.7),
  WatchRow(symbol: 'TSLA', name: 'Tesla Inc.', last: 242.81, changePct: 2.73, volM: 112.9),
  WatchRow(symbol: 'MSFT', name: 'Microsoft', last: 428.91, changePct: 0.31, volM: 21.9),
  WatchRow(symbol: 'AMZN', name: 'Amazon', last: 206.73, changePct: 0.55, volM: 43.8),
];

List<OrderBlotRow> sampleBlotters() => [
  OrderBlotRow(
    orderId: 'C318A2',
    chainId: 'C318…',
    symbol: 'GOOGL',
    side: true,
    liveQty: 80,
    avgPx: 5002.00,
    tif: 'GTC',
    status: 'Working',
    updated: '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
    instrumentId: 0,
  ),
  OrderBlotRow(
    orderId: 'HX9921',
    chainId: 'HX9921',
    symbol: 'SPY',
    side: false,
    liveQty: 25,
    avgPx: 512.41,
    tif: 'DAY',
    status: 'Partial',
    updated: '--:--',
    instrumentId: 0,
  ),
];

List<PositionRow> samplePositions() => [
  PositionRow(symbol: 'VTI', qty: 120, avgCost: 244.62, market: 251.10, dayPnl: 184.56, totalPnl: 777.66),
  PositionRow(symbol: 'IBIT', qty: 200, avgCost: 36.92, market: 35.71, dayPnl: -242.0, totalPnl: 128.44),
];

List<Candle> buildCandles({int n = 64, double start = 100}) {
  var p = start;
  final out = <Candle>[];
  for (var i = 0; i < n; i++) {
    final o = p;
    final move = (_r.nextDouble() - 0.46) * 2.8;
    final c = (o + move).clamp(10.0, double.infinity).toDouble();
    final hi = max(o, c) + _r.nextDouble() * 2;
    final lo = min(o, c) - _r.nextDouble() * 2;
    out.add(Candle(o: o, h: hi, l: lo, c: c));
    p = c;
  }
  return out;
}

final List<NewsItem> kNewsFeed = [
  NewsItem(headline: 'Futures grind higher ahead of CPI revision', source: 'Wire', age: '12m'),
  NewsItem(headline: 'Semis strength continues as capex chatter builds', source: 'Desk', age: '28m'),
];
