/// Loads `fmx_instruments.json`: **Downloads folder first** (desktop), then
/// bundled [assets/data/fmx_instruments.json] fallback (same artifact as Python mock).

library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/models.dart';
import 'downloads_fmx_instruments_stub.dart'
    if (dart.library.io) 'downloads_fmx_instruments_io.dart'
        as downloads_fmx;

class InstrumentCatalog extends ChangeNotifier {
  InstrumentCatalog();

  List<WatchRow> _watchSeed = [];
  final Map<int, String> symbolByInstrumentId = {};
  bool loading = false;
  String? error;
  bool ready = false;

  /// `downloads`, `bundle`, or `none` before first successful load.
  String lastJsonSource = 'none';

  List<WatchRow> get seedWatchRows => List.unmodifiable(_watchSeed);

  Future<void> loadFromAssets() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final fromDownloads =
          await downloads_fmx.readDownloadsFmxInstrumentsJsonString();

      late final String raw;
      if (fromDownloads != null &&
          fromDownloads.trim().startsWith('{') &&
          fromDownloads.contains('instruments')) {
        raw = fromDownloads;
        lastJsonSource = 'downloads';
        debugPrint(
          'InstrumentCatalog: using Downloads/fmx_instruments.json (${fromDownloads.length} chars)',
        );
      } else {
        raw =
            await rootBundle.loadString('assets/data/fmx_instruments.json');
        lastJsonSource = 'bundle';
        debugPrint(
          'InstrumentCatalog: Downloads copy missing or unreadable → bundle asset',
        );
      }
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final instruments = decoded['instruments'] as List<dynamic>? ?? [];
      symbolByInstrumentId.clear();
      final rows = <WatchRow>[];

      const maxRows = 500;
      var count = 0;
      for (final e in instruments) {
        final m = e as Map<String, dynamic>;
        final idRaw = m['instrument_id'];
        final id =
            idRaw is int ? idRaw : idRaw == null ? 0 : (idRaw as num).toInt();
        if (id == 0 || count >= maxRows) {
          continue;
        }
        final sym = (m['symbol'] ?? '') as String;
        final state = (m['trading_state'] ?? '-') as String;
        symbolByInstrumentId[id] = sym;
        final px = deriveDisplaySnapshotPrice(map: m, instrumentId: id, ordinal: count);
        rows.add(
          WatchRow(
            symbol: sym,
            name: '$sym · $state',
            last: px.last,
            changePct: px.changePct,
            volM: 1.2 + (id.abs() % 900) / 100.0,
            instrumentId: id,
          ),
        );
        count++;
      }
      _watchSeed = rows;
      ready = true;
    } catch (e, st) {
      error = '$e';
      debugPrint('$e\n$st');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  String symbolForId(int instrumentId, {String fallback = '—'}) =>
      symbolByInstrumentId[instrumentId] ?? fallback;
}

/// JSON has `price_multiplier` / `price_type`, not a streaming last trade.
/// Use any numeric reference fields if present; otherwise a **stable stub** from [instrumentId]
/// (display only — wire prices still use your limit field).
({double last, double changePct}) deriveDisplaySnapshotPrice({
  required Map<String, dynamic> map,
  required int instrumentId,
  required int ordinal,
}) {
  for (final k in [
    'last_px',
    'last_price',
    'reference_px',
    'theoretical_px',
    'close_px',
    'settle_px',
  ]) {
    final v = map[k];
    if (v is num && v.toDouble() > 0) {
      return (last: v.toDouble(), changePct: 0.03 * (ordinal.isEven ? 1 : -1));
    }
  }
  final h = instrumentId.abs() % 1_000_003;
  final last =
      97.25 + (h % 18_750) / 250.0; // ~97–172, bond-future-ish band
  final changePct = (((h ~/ 101) % 17) - 8) / 160.0;
  return (last: last, changePct: changePct);
}
