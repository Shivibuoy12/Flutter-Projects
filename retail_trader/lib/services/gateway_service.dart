import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../fmx/bop_codec.dart';
import '../fmx/fmx_reject_reference.dart';
import '../fmx/gateway_parse.dart';
import '../models/models.dart';
import 'instrument_catalog.dart';

/// Extended Futures order payloads (Enter/Cancel/Replace) use this outer ASCII type.
/// Must match Python `Server_Side_Mock` / `pack_transport(first='u', ...)`.
const String kGatewayFuturesOrderEnvelopeAscii = 'u';

const Map<int, String> gatewayTifLabels = {
  0: 'DAY',
  1: 'GTC',
  3: 'IOC',
  4: 'FOK',
};

class GatewayService extends ChangeNotifier {
  GatewayService({
    required this.catalog,
    this.host = '127.0.0.1',
    this.port = 12345,
    this.username = 'Shivansh',
    this.password = 'Sh12@nsh',
    this.session = '1022',
    this.account = 'ABCacct123',
    this.senderLocation = 'USNY',
    this.clientTrader = 'TRDR1',
    String? origTrader,
    this.tifDefault = 1,
    this.smpCode = 0,
  }) : origTrader8 = (origTrader ?? username).padRight(8).substring(0, 8);

  final InstrumentCatalog catalog;
  String host;
  int port;
  String username;
  String password;
  String session;
  String account;
  String senderLocation;
  String clientTrader;
  String origTrader8;
  int tifDefault;
  int smpCode;

  Socket? _sock;
  StreamSubscription<Uint8List>? _sub;
  Timer? _hbTimer;
  final List<int> _rxBuf = [];

  bool connected = false;
  bool loggedIn = false;
  String? connectionError;
  int _nextSeq = 1;

  /// Last Accepted / Replace parent hint (extended Replaced lacks old oid).
  String? lastAcceptedOrderId;
  int lastInstrumentId = 0;
  bool lastBuySide = true;

  final Map<int, double> lastPriceHintByInstrumentId = {};

  final List<String> messageLog = [];
  final Map<String, OrderBlotRow> blotByOrderId = {};

  /// Latest limit enter key (client order id); used to clear **Sent …** when **`A`** echoes a different broker id.
  String? _pendingClientEnterOrderKey;

  List<OrderBlotRow> get blotRows {
    final l = blotByOrderId.values.toList();
    l.sort((a, b) => b.updated.compareTo(a.updated));
    return l;
  }

  void _trimLog() {
    if (messageLog.length > 220) {
      messageLog.removeRange(220, messageLog.length);
    }
  }

  /// Match server-reported ids to blot keys (30-char ASCII pad differences).
  String? _findBlotKeyForOrderId(String rawOid) {
    final cleaned = rawOid.trimRight();
    if (blotByOrderId.containsKey(rawOid)) {
      return rawOid;
    }
    if (cleaned.isNotEmpty && blotByOrderId.containsKey(cleaned)) {
      return cleaned;
    }
    for (final k in blotByOrderId.keys) {
      if (k.trimRight() == cleaned) {
        return k;
      }
    }
    return null;
  }

  void _info(String line) {
    messageLog.insert(0, line);
    _trimLog();
  }

  Future<void> connect() async {
    await disconnect(clearRows: false);
    connectionError = null;
    notifyListeners();
    try {
      _sock = await Socket.connect(host, port, timeout: const Duration(seconds: 8));
      connected = true;
      _sock!.setOption(SocketOption.tcpNoDelay, true);
      _info('CONNECTED $host:$port');
      _sock!.add(encodeLoginFrame(
        user8: username,
        password10: password,
        session10: session,
        seq: _nextSeq,
      ));
      await _sock!.flush();

      _hbTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
        final s = _sock;
        if (s != null && connected) {
          try {
            s.add(encodeHeartbeat());
          } catch (e) {
            debugPrint('heartbeat: $e');
          }
        }
      });

      _sub = _sock!.listen(_onRx,         onDone: () {
          _info('SOCKET CLOSED');
          Future.microtask(() => disconnect(clearRows: false));
        }, onError: (e, st) {
        connectionError = '$e';
        _info('SOCK ERROR $e');
        notifyListeners();
      });
      notifyListeners();
    } catch (e, st) {
      connected = false;
      connectionError = '$e';
      _info('CONNECT FAILED $e');
      debugPrint('$st');
      notifyListeners();
    }
  }

  Future<void> disconnect({bool clearRows = true}) async {
    await _sub?.cancel();
    _sub = null;
    _hbTimer?.cancel();
    _hbTimer = null;
    _rxBuf.clear();
    try {
      await _sock?.close();
    } catch (_) {}
    _sock = null;
    connected = false;
    loggedIn = false;
    if (clearRows) {
      blotByOrderId.clear();
      messageLog.clear();
      lastAcceptedOrderId = null;
      lastInstrumentId = 0;
      lastPriceHintByInstrumentId.clear();
    }
    _pendingClientEnterOrderKey = null;
    notifyListeners();
  }

  void _onRx(Uint8List chunk) {
    _rxBuf.addAll(chunk);
    while (_drainOneFrame()) {}
    notifyListeners();
  }

  bool _drainOneFrame() {
    if (_rxBuf.length < 2) {
      return false;
    }
    final tmp = Uint8List.fromList(_rxBuf);
    final plen = ByteData.sublistView(tmp).getUint16(0, Endian.little);
    final need = 2 + plen;
    if (_rxBuf.length < need) {
      return false;
    }
    final payload = Uint8List.fromList(_rxBuf.sublist(2, need));
    _rxBuf.removeRange(0, need);
    _handleOuterPayload(payload);
    return true;
  }

  void _handleOuterPayload(Uint8List p) {
    if (p.isEmpty) {
      return;
    }
    final w = latin1Ascii(p[0]);

    switch (w) {
      case 'A':
        _loginOk(p);
        break;
      case 'J':
        if (loggedIn) {
          final r = parseRejected(innerForGatewayView(p));
          if (r != null) {
            _info(
              'REJECT oid=${r.orderId.trim()} reason=${r.reason}: ${fmxRejectReasonCaption(r.reason)} '
              '| req=${r.reqType}: ${fmxRejectedRequestTypeCaption(r.reqType)}',
            );
            final bk = _findBlotKeyForOrderId(r.orderId);
            if (bk != null) {
              _markRejected(bk, r.reason, r.reqType);
            }
          }
        } else {
          connectionError = 'LOGIN REJECT';
          notifyListeners();
        }
        break;
      case 'H':
        _sock?.add(encodeHeartbeat());
        break;
      case 'S':
        if (p.length > 1) {
          _gatewayInner(p.sublist(1));
        }
        break;
      case 's':
      case 'u':
        if (p.length <= 1) {
          break;
        }
        try {
          for (final inner in splitExtendedMessages(p.sublist(1))) {
            _gatewayInner(inner);
          }
        } catch (e) {
          _info('EXT-s/u FAIL $e');
        }
        break;
      case 't':
        if (p.length <= 1) {
          break;
        }
        try {
          for (final inner in splitExtendedMessages(p.sublist(1))) {
            _gatewayInner(inner);
          }
        } catch (e) {
          _info('EXT-t FAIL $e');
        }
        break;
      default:
        _info('FRAME $w (${p.length}B)');
        break;
    }
  }

  static String latin1Ascii(int b) => String.fromCharCode(b.clamp(0, 127));

  void _loginOk(Uint8List payload) {
    try {
      final r = decodeLoginAccepted(payload);
      _nextSeq = r.nextSeq;
      loggedIn = true;
      _info('LOGIN OK ${r.sessionName} next=$_nextSeq');
      _sock?.add(encodeAccountRequest(trader8: username.padRight(8).substring(0, 8)));
    } catch (e) {
      _info('LOGIN DECODE $e');
    }
  }

  void _gatewayInner(Uint8List inner) {
    // Order lifecycle messages may arrive on **`s`**, **`u`**, or **`t`** extended wrappers interchangeably.

    final ia = parseAccepted(inner);
    if (ia != null) {
      final ackKey = ia.orderId.trimRight();
      for (final k in List<String>.from(blotByOrderId.keys)) {
        if (k.trimRight() == ackKey) {
          blotByOrderId.remove(k);
        }
      }
      /// Server may ACK with a broker id **`!=`** client blot key — drop lingering **Sent …** row.
      final pendRaw = _pendingClientEnterOrderKey;
      _pendingClientEnterOrderKey = null;
      if (pendRaw != null) {
        final pend = pendRaw.trimRight();
        if (pend.isNotEmpty && pend != ackKey) {
          final pk = _findBlotKeyForOrderId(pend);
          if (pk != null) {
            final pendingRow = blotByOrderId[pk];
            if (pendingRow != null && pendingRow.status.startsWith('Sent')) {
              blotByOrderId.remove(pk);
            }
          }
        }
      }

      final px = ia.priceScaled / kPriceScalingFactor;
      final sym = catalog.symbolForId(ia.instrumentId, fallback: 'id:${ia.instrumentId}');
      lastAcceptedOrderId = ackKey;
      lastInstrumentId = ia.instrumentId;
      lastBuySide = ia.buySide;
      lastPriceHintByInstrumentId[ia.instrumentId] = px;
      blotByOrderId[ackKey] = OrderBlotRow(
        orderId: ackKey,
        chainId:
            ackKey.length <= 6 ? ackKey : ackKey.substring(0, 6),
        symbol: sym,
        side: ia.buySide,
        liveQty: ia.qty,
        avgPx: px,
        tif: gatewayTifLabels[tifDefault] ?? '—',
        status: 'Accepted',
        updated: _timestamp(),
        instrumentId: ia.instrumentId,
      );
      _info('ACCEPT $sym $ackKey qty=${ia.qty} @ $px');
    }

    final ex = parseExecuted(inner);
    if (ex != null) {
      _info('EXEC ${ex.orderId} qty=${ex.execQty}');
    }

    final rep = parseReplaced(inner);
    if (rep != null) {
      final repKey = rep.orderId.trimRight();
      final px = rep.priceScaled / kPriceScalingFactor;
      final sym =
          catalog.symbolForId(lastInstrumentId, fallback: 'id:$lastInstrumentId');

      if (lastAcceptedOrderId != null) {
        final parentKey = _findBlotKeyForOrderId(lastAcceptedOrderId!);
        if (parentKey != null) {
          blotByOrderId.remove(parentKey);
        }
      }

      blotByOrderId[repKey] = OrderBlotRow(
        orderId: repKey,
        chainId:
            repKey.length <= 6 ? repKey : repKey.substring(0, 6),
        symbol: sym,
        side: lastBuySide,
        liveQty: rep.qty,
        avgPx: px,
        tif: gatewayTifLabels[tifDefault] ?? '—',
        status: 'Working',
        updated: _timestamp(),
        instrumentId: lastInstrumentId,
      );
      lastAcceptedOrderId = repKey;
      lastPriceHintByInstrumentId[lastInstrumentId] = px;
      _info('REPLACED -> $repKey qty=${rep.qty} @ $px');
    }

    final ca = parseCancelled(inner);
    if (ca != null) {
      final cancelBk = _findBlotKeyForOrderId(ca.orderId);
      final lastBk =
          lastAcceptedOrderId == null ? null : _findBlotKeyForOrderId(lastAcceptedOrderId!);
      if (cancelBk != null) {
        blotByOrderId.remove(cancelBk);
      }
      final coid = ca.orderId.trimRight();
      _info('CANCELLED $coid r=${ca.reason}');
      if (lastBk != null && cancelBk != null && lastBk == cancelBk) {
        lastAcceptedOrderId = null;
      }
    }

    final rj = parseRejected(innerForGatewayView(inner));
    if (rj != null) {
      _info(
        'REJECT oid=${rj.orderId.trim()} reason=${rj.reason}: ${fmxRejectReasonCaption(rj.reason)} '
        '| req=${rj.reqType}: ${fmxRejectedRequestTypeCaption(rj.reqType)}',
      );
      final bk = _findBlotKeyForOrderId(rj.orderId);
      if (bk != null) {
        _markRejected(bk, rj.reason, rj.reqType);
      }
      final pend = _pendingClientEnterOrderKey;
      if (pend != null) {
        final pendTrim = pend.trimRight();
        final rejectTrim = rj.orderId.trimRight();
        final pb = _findBlotKeyForOrderId(pend);
        if ((bk != null && pb == bk) ||
            (rejectTrim.isNotEmpty && rejectTrim == pendTrim)) {
          _pendingClientEnterOrderKey = null;
        }
      }
    }
  }

  void _markRejected(String oid, String code, String reqType) {
    final prev = blotByOrderId[oid];
    if (prev == null) {
      return;
    }
    blotByOrderId[oid] = OrderBlotRow(
      orderId: prev.orderId,
      chainId: prev.chainId,
      symbol: prev.symbol,
      side: prev.side,
      liveQty: prev.liveQty,
      avgPx: prev.avgPx,
      tif: prev.tif,
      status:
          'Reject $code (${fmxRejectedRequestTypeCaption(reqType)}) — ${fmxRejectReasonCaption(code)}',
      updated: _timestamp(),
      instrumentId: prev.instrumentId,
    );
  }

  /// Update TIF wiring from dropdown labels in the ticket panel.
  void applyUiTif(String label) {
    tifDefault = switch (label) {
      'GTC' => 1,
      'IOC' => 3,
      'FOK' => 4,
      _ => 0,
    };
    notifyListeners();
  }

  void notifyGatewayConfigChanged() => notifyListeners();

  String _timestamp() {
    final n = DateTime.now();
    final h = n.hour.toString().padLeft(2, '0');
    final m = n.minute.toString().padLeft(2, '0');
    final s = n.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  /// Replay **login** [`L`] on the live TCP session (TCP already connected).
  void sendWireLoginFrame({int? seq}) {
    final sock = _sock;
    if (sock == null || !connected) {
      _info('LOGIN SKIP (offline)');
      return;
    }
    final useSeq = seq ?? _nextSeq;
    sock.add(
      encodeLoginFrame(
        user8: username,
        password10: password,
        session10: session,
        seq: useSeq,
      ),
    );
    _info('→ LOGIN probe seq=$useSeq (${seq != null ? "override" : "server next"})');
  }

  /// Send login with deliberately wrong-ish sequence vs `decodeLoginAccepted` — expect reject / noop from mock.
  void sendMisalignedSeqLoginProbe() => sendWireLoginFrame(seq: _nextSeq + 999917);

  void sendHeartbeatNow() {
    final sock = _sock;
    if (sock == null || !connected) {
      _info('HEARTBEAT SKIP (offline)');
      return;
    }
    sock.add(encodeHeartbeat());
    _info('→ HEARTBEAT R');
  }

  /// Resend **`T` account-ish request** wrapped in `U`, same trace as initial post-login handshake.
  void sendAccountRequestProbe() {
    final sock = _sock;
    if (sock == null || !connected) {
      _info('ACCT REQ SKIP (offline)');
      return;
    }
    sock.add(encodeAccountRequest(trader8: username.padRight(8).substring(0, 8)));
    _info('→ ACCT REQ T (${username.padRight(8)})');
  }

  Future<bool> submitCancelWorkingOrder({
    required String brokerOrderId,
  }) async {
    final sock = _sock;
    if (sock == null || !loggedIn) {
      _info('CANCEL SKIP (offline)');
      return false;
    }
    try {
      final inner = encodeCancelOrderFuturesExtended(
        orderToCancel30: brokerOrderId,
        senderLocation4: senderLocation,
        clientTrader18: clientTrader.padRight(18),
      );
      sock.add(packTransport(kGatewayFuturesOrderEnvelopeAscii, inner));
      await sock.flush();
      _info('→ CANCEL oid=$brokerOrderId');
      return true;
    } catch (e, st) {
      _info('CANCEL ERR $e');
      debugPrint('$st');
      return false;
    }
  }

  /// **Modify / replace** working order (`U` Tables 38–39): replacement id **`@31`**, qty @61/price @69 in base.
  Future<bool> submitReplaceModifyOrder({
    required String originatingOrderId,
    required String replacementOrderId,
    required int instrumentId,
    required int qty,
    required double limitPriceDisplay,
  }) async {
    final sock = _sock;
    if (sock == null || !loggedIn) {
      _info('REPLACE SKIP (offline)');
      return false;
    }
    try {
      final priceScaled = (limitPriceDisplay * kPriceScalingFactor).round();

      final inner = encodeReplaceOrderFuturesExtended(
        orderToReplace30: originatingOrderId,
        newClientOrderId30: replacementOrderId,
        qty: qty,
        priceScaled: priceScaled,
        timeInForce: tifDefault,
        clientTrader18: clientTrader.padRight(18),
        reportingCodes: kFuturesReportingCodes,
        account18: account.padRight(18),
        senderLocation4: senderLocation,
        smpCode: smpCode,
      );
      sock.add(packTransport(kGatewayFuturesOrderEnvelopeAscii, inner));
      await sock.flush();

      lastInstrumentId = instrumentId;
      final sym = catalog.symbolForId(instrumentId);
      _info(
        '→ REPLACE orig=$originatingOrderId new=$replacementOrderId $sym qty=$qty px=$limitPriceDisplay',
      );
      return true;
    } catch (e, st) {
      _info('REPLACE ERR $e');
      debugPrint('$st');
      return false;
    }
  }

  Future<bool> submitLimitOrder({
    required String orderId,
    required int instrumentId,
    required int qty,
    required double priceDisplay,
    bool sideBuy = true,
  }) async {
    final sock = _sock;
    if (sock == null || !loggedIn) {
      _info('SKIP SEND (offline)');
      return false;
    }
    try {
      final priceScaled = (priceDisplay * kPriceScalingFactor).round();

      final inner = encodeEnterOrderFuturesExtended(
        orderId: orderId,
        side: sideBuy ? 'B' : 'S',
        qty: qty,
        instrumentId: instrumentId,
        priceScaled: priceScaled,
        timeInForce: tifDefault,
        orderTypeAscii: '2',
        originatingTrader8: origTrader8,
        clientTrader18: clientTrader.padRight(18),
        instrumentSymbol30: '',
        reportingCodes: kFuturesReportingCodes,
        account18: account.padRight(18),
        senderLocation4: senderLocation,
        smpCode: smpCode,
        expiryTimeNs: 0,
      );
      sock.add(packTransport(kGatewayFuturesOrderEnvelopeAscii, inner));
      await sock.flush();

      final sym = catalog.symbolForId(instrumentId);
      final chain = orderId.length <= 6 ? orderId : orderId.substring(0, 6);
      final oidKey = orderId.trimRight();
      blotByOrderId[oidKey] = OrderBlotRow(
        orderId: oidKey,
        chainId: chain,
        symbol: sym,
        side: sideBuy,
        liveQty: qty,
        avgPx: priceDisplay,
        tif: gatewayTifLabels[tifDefault] ?? '—',
        status: 'Sent — waiting for Accepted',
        updated: _timestamp(),
        instrumentId: instrumentId,
      );
      _pendingClientEnterOrderKey = oidKey;

      lastInstrumentId = instrumentId;
      lastBuySide = sideBuy;

      _info(
        '→ ENTER $sym oid=$orderId ${sideBuy ? 'BUY' : 'SELL'} qty=$qty px=$priceDisplay',
      );
      notifyListeners();

      return true;
    } catch (e, st) {
      _info('SUBMIT ERR $e');
      debugPrint('$st');
      return false;
    }
  }
}
