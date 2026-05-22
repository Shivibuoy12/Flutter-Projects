/// Watchlist instrument row (display only; mock backend).
class WatchRow {
  const WatchRow({
    required this.symbol,
    required this.name,
    required this.last,
    required this.changePct,
    required this.volM,
    this.exchange = 'NASDAQ',
    this.instrumentId,
    this.tifLabel = '',
  });
  final String symbol;
  final String name;
  final double last;
  final double changePct;
  final double volM;
  final String exchange;
  /// Futures instrument id from `fmx_instruments.json` when known.
  final int? instrumentId;
  /// Optional display (e.g. current TIF) from live gateway.
  final String tifLabel;
}

class IndexQuote {
  const IndexQuote({
    required this.label,
    required this.price,
    required this.changePct,
  });
  final String label;
  final double price;
  final double changePct;
}

class OrderBlotRow {
  const OrderBlotRow({
    required this.orderId,
    required this.chainId,
    required this.symbol,
    required this.side,
    required this.liveQty,
    required this.avgPx,
    required this.tif,
    required this.status,
    required this.updated,
    this.instrumentId = 0,
  });
  final String orderId;
  final String chainId;
  final String symbol;
  final bool side; // true buy
  final int liveQty;
  final double avgPx;
  final String tif;
  final String status;
  final String updated;
  /// From Accepted when available.
  final int instrumentId;
}

class PositionRow {
  const PositionRow({
    required this.symbol,
    required this.qty,
    required this.avgCost,
    required this.market,
    required this.dayPnl,
    required this.totalPnl,
  });
  final String symbol;
  final int qty;
  final double avgCost;
  final double market;
  final double dayPnl;
  final double totalPnl;
}

class Candle {
  const Candle({
    required this.o,
    required this.h,
    required this.l,
    required this.c,
  });
  final double o;
  final double h;
  final double l;
  final double c;
}

class NewsItem {
  const NewsItem({required this.headline, required this.source, required this.age});
  final String headline;
  final String source;
  final String age;
}
